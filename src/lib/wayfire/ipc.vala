namespace TogetherShell {
    private class CallbackKeeper {
        public SourceFunc callback;

        public CallbackKeeper (SourceFunc callback) {
            this.callback = callback;
        }
    }

    [SingleInstance]
    public class WayfireIPC : Object {
        private SocketConnection connection;
        private IOChannel channel;
        private Gee.ArrayQueue<CallbackKeeper> callback_queue = new Gee.ArrayQueue<CallbackKeeper> ();
        private Json.Object? pending_payload = null;

        public WayfireIPC () {
            string? socket_path = Environment.get_variable ("WAYFIRE_SOCKET");

            if (socket_path == null)
                socket_path = "/run/user/%i/wayfire-wayland-1-.socket".printf ((int) Posix.getuid ());

            var client = new SocketClient ();
            try {
                connection = client.connect (new UnixSocketAddress (socket_path));
            } catch (Error e) {
                critical ("WayfireIPC connection failed: %s", e.message);
                return;
            }

            channel = new IOChannel.unix_new (connection.socket.fd);
            channel.add_watch (IOCondition.IN | IOCondition.HUP | IOCondition.ERR, on_data);

            print ("Wayfire IPC inited\n");
        }

        private bool on_data (IOChannel source, IOCondition condition) {
            print ("data\n");
            if ((condition & (IOCondition.ERR | IOCondition.HUP)) != 0)
                return false;

            try {
                uint8[] lbuf = new uint8[4];
                connection.input_stream.read_all (lbuf, null);
                uint32 len = (uint32) lbuf[0] | ((uint32) lbuf[1] << 8) | ((uint32) lbuf[2] << 16) | ((uint32) lbuf[3] << 24);
                uint8[] buf = new uint8[len];
                connection.input_stream.read_all (buf, null);

                var parser = new Json.Parser ();
                parser.load_from_data ((string) buf);
                var j_obj = parser.get_root ().get_object ();

                pending_payload = j_obj;

                if (j_obj.has_member ("event")) {
                    return true; // TODO
                }
                else {
                    if (!callback_queue.is_empty) {
                        var callback = callback_queue.poll ();
                        print ("callback\n");
                        callback.callback ();
                        print ("callbacked\n");
                    }
                }

                return true;
            } catch (Error e) {
                critical ("Wayfire IPC error: %s", e.message);
                return false;
            }
        }

        public async void disconnect () throws Error {
            yield connection.close_async (Priority.DEFAULT);
        }

        public async Json.Object? do_call (string method, Json.Object? data = new Json.Object ()) throws Error {
            var root = new Json.Object ();
            var node = new Json.Node (Json.NodeType.OBJECT);

            root.set_string_member ("method", method);
            root.set_object_member ("data", data);
            node.set_object (root);

            string json = Json.to_string (node, false);
            uint8[] msg = json.data;
            uint32 len = (uint32) msg.length;
            uint8[] lbuf = {
                (uint8) len,
                (uint8) (len >> 8),
                (uint8) (len >> 16),
                (uint8) (len >> 24)
            };

            callback_queue.offer (new CallbackKeeper (do_call.callback));
            yield connection.output_stream.write_all_async (lbuf, Priority.DEFAULT, null, null);
            yield connection.output_stream.write_all_async (msg, Priority.DEFAULT, null, null);
            yield;

            var payload = pending_payload;
            pending_payload = null;

            print (payload.get_string_member ("data") + "\n");
            return payload;
        }
    }
}
