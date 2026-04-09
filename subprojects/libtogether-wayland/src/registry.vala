namespace TogetherWayland {
    [SingleInstance]
    public class Registry : Object {
        public ToplevelManager? toplevel_manager { get; private set; }
        public OutputsKeeper? outputs_keeper { get; private set; }
        public WayfireShellManager? wayfire_shell_manager { get; private set; }
        public Wl.Seat? seat_proxy;
        public unowned Wl.Display display = ((Gdk.Wayland.Display) Gdk.Display.get_default ()).get_wl_display ();
        private IOChannel dispatch_channel;
        private uint? dispatch_id;
        private const Wl.RegistryListener registry_listener = {
            on_global,
            on_global_remove
        };

        public Registry () {
            if (dispatch_id != null)
                return;

            int fd = display.get_fd ();
            dispatch_channel = new IOChannel.unix_new (fd);
            dispatch_channel.set_close_on_unref (true);
            dispatch_id = dispatch_channel.add_watch (IOCondition.IN | IOCondition.ERR | IOCondition.HUP, (source, condition) => {
                if (condition == IOCondition.IN) {
                    display.roundtrip ();
                    return true;
                }

                return false;
            });

            var registry = display.get_registry();
            outputs_keeper = new OutputsKeeper (this);

            registry.add_listener (registry_listener, this);
            display.roundtrip ();
        }

        private static void on_global (void* data, Wl.Registry registry, uint32 name, string interface, uint32 version) {
            var self = (Registry) data;
            switch (interface) {
                case ("zwlr_foreign_toplevel_manager_v1"):
                    self.toplevel_manager = new ToplevelManager (registry.bind<Zwlr.ForeignToplevelManagerV1> (name, ref Zwlr.foreign_toplevel_manager_v1_interface, version), self);
                break;
                case ("zwf_shell_manager_v2"):
                    self.wayfire_shell_manager = new WayfireShellManager (registry.bind<Zwf.ShellManagerV2> (name, ref Zwf.shell_manager_v2_interface, version), self);
                break;
                case ("wl_output"):
                    self.outputs_keeper.add_output (name, registry.bind<Wl.Output> (name, ref Wl.output_interface, version));
                    self.display.flush ();
                break;
                case ("wl_seat"):
                    self.seat_proxy = registry.bind<Wl.Seat> (name, ref Wl.seat_interface, version); // yes, we don't support configurations with multiple seats, I'm too lazy :(
                break;
            }
        }

        private static void on_global_remove (void* data, Wl.Registry registry, uint32 name) {
            ((Registry) data).outputs_keeper.remove_output (name);
        }

        ~Registry () {
            Source.remove (dispatch_id);
            try {
                dispatch_channel.shutdown (true);
            } catch (Error e) {}
        }
    }
}
