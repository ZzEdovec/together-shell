namespace Wayfire {
    public enum BindingMode {
        RELEASE,
        REPEAT
    }

    public class Binding : Object {
        public int64? bind_id { get; private set; }
        private WayfireIPC ipc = new WayfireIPC ();

        public signal void triggered ();

        public Binding (string shortcut,
                        bool exec_always = false,
                        BindingMode mode = BindingMode.RELEASE,
                        string? command = null,
                        string? call_method = null,
                        Json.Object? call_data = null) {
            var data = new Json.Object ();
            data.set_string_member ("binding", shortcut);
            data.set_boolean_member ("exec-always", exec_always);
            data.set_string_member ("mode", mode == BindingMode.RELEASE ? "release" : "repeat");
            if (command != null)
                data.set_string_member ("command", command);
            if (call_method != null)
                data.set_string_member ("call-method", call_method);
            if (call_data != null)
                data.set_object_member ("call-data", call_data);

            ipc.call.begin ("command/register-binding", data, (obj, res) => {
                try {
                    bind_id = ipc.call.end (res).get_int_member ("binding-id");
                    ipc.event_received[bind_id.to_string ()].connect (() => { triggered (); });
                } catch (Error e) {
                    critical ("Cannot bind! - %s", e.message);
                }
            });
        }

        ~Binding () {
            var data = new Json.Object ();
            data.set_int_member ("binding-id", bind_id);

            ipc.call.begin ("command/unregister-binding", data);
        }
    }
}
