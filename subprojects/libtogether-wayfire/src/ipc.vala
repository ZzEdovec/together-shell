namespace TogetherWayfire {
    private class SourceKeeper {
        public SourceFunc callback;

        public SourceKeeper (owned SourceFunc callback) {
            this.callback = (owned) callback;
        }
    }

    // If you call more than one IPC method at a time, keep a strong reference to the class to avoid problems due to async!
    [SingleInstance]
    public class IPC : Object {
        private SocketConnection? connection;
        private IOChannel? channel;
        private uint? watch_id;
        private Gee.ArrayQueue<SourceKeeper> write_queue = new Gee.ArrayQueue<SourceKeeper> ();
        private SourceFunc? read_callback;
        private bool busy = false;
        private Json.Object? pending_payload;

        [Signal (detailed = true)]
        public signal void event_received (Json.Object j_obj);

        ~IPC () {
            try {
                if (watch_id != null) { Source.remove (watch_id); }
                if (channel != null) { channel.shutdown (true); }
            } catch (Error e) {
                warning ("WayfireIPC: failed to shutdown IOChannel, possible memory leak: %s", e.message);
            }
        }

        private async void connect_socket () throws Error {
            string? socket_path = Environment.get_variable ("WAYFIRE_SOCKET");
            if (socket_path == null)
                socket_path = "/run/user/%u/wayfire-wayland-1-.socket".printf ((uint) Posix.getuid ());

            var client = new SocketClient ();
            connection = yield client.connect_async (new UnixSocketAddress (socket_path));

            channel = new IOChannel.unix_new (connection.socket.fd);
            channel.set_close_on_unref (true);
            watch_id = channel.add_watch (IOCondition.IN | IOCondition.HUP | IOCondition.ERR, read_response);
        }

        public async Json.Object? call (string method, Json.Object data = new Json.Object ()) throws Error {
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

            if (busy) {
                SourceFunc callback = call.callback;
                write_queue.offer (new SourceKeeper ((owned) callback));
                yield;
            }

            busy = true;

            if (connection == null)
                yield connect_socket ();

            connection.output_stream.write_all (lbuf, null);
            connection.output_stream.write_all (msg, null);

            var response = yield wait_for_response ();

            if (response.has_member ("error"))
                throw new IOError.FAILED (pending_payload.get_string_member ("error"));

            return response;
        }

        private async Json.Object? wait_for_response () {
            SourceFunc callback = wait_for_response.callback;
            read_callback = (owned) callback;
            yield;

            var payload = pending_payload;
            pending_payload = null;
            read_callback = null;

            return payload;
        }

        private bool read_response (IOChannel source, IOCondition condition) {
            if (condition == IOCondition.ERR || condition == IOCondition.HUP)
                return false;

            try {
                uint8[] lbuf = new uint8[4];
                connection.input_stream.read_all (lbuf, null);

                uint32 len = (uint32) lbuf[0] | ((uint32) lbuf[1] << 8) | ((uint32) lbuf[2] << 16) | ((uint32) lbuf[3] << 24);
                uint8[] buf = new uint8[len];
                connection.input_stream.read_all (buf, null);

                var parser = new Json.Parser ();
                parser.load_from_data ((string) buf);
                var object = parser.get_root ().get_object ();

                if (object.has_member ("event")) {
                    if (object.has_member ("binding-id"))
                        Signal.emit_by_name (this, "event_received::%lld".printf (object.get_int_member ("binding-id")), object);
                    else
                        Signal.emit_by_name (this, "event_received::%s\n".printf (object.get_string_member ("event")), object);

                    return true;
                }
                else
                    pending_payload = object;
            } catch (Error e) {
                critical ("WayfireIPC: failed to read message - %s\n", e.message);
                return false;
            }

            if (read_callback != null)
                read_callback ();
            else
                print ("no read callback\n");

            Idle.add (() => {
                busy = false;

                var next_cb = write_queue.poll ();
                if (next_cb != null)
                    next_cb.callback ();

                return false;
            });

            return true;
        }
    }
}

