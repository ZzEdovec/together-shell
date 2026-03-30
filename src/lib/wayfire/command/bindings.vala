namespace Wayfire {
    public class Binding : Object {
        public int64? bind_id { get; private set; }
        private WayfireIPC ipc = new WayfireIPC ();

        public signal void triggered ();

        public Binding (string shortcut) {
            var data = new Json.Object ();
            data.set_string_member ("binding", shortcut);

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
