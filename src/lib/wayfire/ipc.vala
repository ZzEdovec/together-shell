[SingleInstance]
public class TogetherShell.WayfireIPC : Object {
    private SocketConnection connection;

    public WayfireIPC () {
        string socket_path = Environment.get_variable ("WAYFIRE_SOCKET");

        if (socket_path == null)
            socket_path = "/run/user/1000/wayfire-wayland-1-.socket";

        var address = new UnixSocketAddress (socket_path);
        var client = new SocketClient ();

        connection = client.connect (address);
    }

    public async void disconnect () throws Error {
        yield connection.close_async (Priority.DEFAULT);
    }

    public async string call (string method, Json.Object? data = null) throws Error {
        var root = new Json.Object ();
        var node = new Json.Node (Json.NodeType.OBJECT);

        root.set_string_member ("method", method);
        root.set_object_member ("data", data);
        node.set_object (root);

        string json = Json.to_string (node, false);
        uint8[] msg = json.data;
        uint32 len = (uint32) msg.length;

        uint8 len_buf[4] = {
            (uint8) (len),
            (uint8) (len >> 8),
            (uint8) (len >> 16),
            (uint8) (len >> 24)
        }; // Little Endian

        yield connection.output_stream.write_all_async (len_buf, Priority.DEFAULT, null, null);
        yield connection.output_stream.write_all_async (msg, Priority.DEFAULT, null, null);

        uint8[] rlen_buf = new uint8[4];
        connection.input_stream.read_all (rlen_buf, null); // idk why, but async version specifically for reading the lenght causes the MainLoop to hang

        uint32 response_len = (uint32) rlen_buf[0] | ((uint32) rlen_buf[1] << 8) |
                              ((uint32) rlen_buf[2] << 16) | ((uint32) rlen_buf[3] << 24);
        uint8[] buf = new uint8[response_len];
        yield connection.input_stream.read_all_async (buf, Priority.DEFAULT, null, null);

        return (string) buf;
    }
}

