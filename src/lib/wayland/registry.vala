/**
 * TOGETHER SHELL CORE RUNTIME API
 *
 * This file defines objects managed exclusively by the Together Shell Core.
 *
 * FOR PLUGIN DEVELOPERS:
 * ACCESS: These objects are instantiated and managed by the Shell.
 * You receive them via provider methods.
 * LIFECYCLE: Do NOT attempt to create (new) instances of these classes.
 * Doing so will result in unlinked objects, memory corruption and Shell crash.
 */

[SingleInstance]
public class TogetherShell.WaylandRegistry : Object {
    public ToplevelManager? toplevel_manager { get; private set; }
    public OutputManager? output_manager { get; private set; }
    private Zwlr.ForeignToplevelManagerV1? toplevel_proxy;
    private Gee.HashMap<uint, void*> output_proxies = new Gee.HashMap<uint, void*> ();
    private Wl.Seat? seat;
    private Wl.Display display = new Wl.Display.connect (Environ.get_variable (null, "WAYLAND_DISPLAY"));
    private IOChannel? dispatch_channel;
    private uint? dispatch_id;
    private Wl.RegistryListener? registry_listener;

    public signal void on_toplevel_manager (ToplevelManager toplevel_manager);
    public signal void on_output_manager (OutputManager output_manager);

    public WaylandRegistry () {
        if (dispatch_id != null)
            return;

        var registry = display.get_registry();

        registry_listener = Wl.RegistryListener () {
            global = (data, reg, name, iface, version) => {
                unowned WaylandRegistry self = (WaylandRegistry) data;
                switch (iface) { // if we start creating manager objects directly in the global handler, it will cause problems, so we save the proxy and do it later.
                    case ("zwlr_foreign_toplevel_manager_v1"):
                        self.toplevel_proxy = reg.bind<Zwlr.ForeignToplevelManagerV1> (name, ref Zwlr.foreign_toplevel_manager_v1_interface, version);
                    break;
                    case ("wl_output"):
                        self.output_proxies[name] = (void*) reg.bind<Wl.Output> (name, ref Wl.output_interface, version);
                    break;
                    case ("wl_seat"):
                        if (self.seat == null) // yes, we don't support configurations with multiple seats, I'm too lazy :(
                            self.seat = reg.bind<Wl.Seat> (name, ref Wl.seat_interface, version);
                    break;
                }
            },
            global_remove = (data, reg, name) => {
                unowned WaylandRegistry self = (WaylandRegistry) data;

                /**
                 * This is a very stupid decision,
                 * but considering that in addition to wl_output,
                 * the rest of the Globals we use usually live the entire lifecycle of the compositor, this is justified.
                 */
                if (self.output_manager != null)
                    self.output_manager.remove_output (name);
            },
        };

        registry.add_listener (ref registry_listener, (void*) this);
        display.roundtrip ();

        if (output_proxies != null) {
            output_manager = new OutputManager (display);

            foreach (var output in (Gee.HashMap<uint, Wl.Output>) output_proxies)
                output_manager.add_output (output.key, output.value);

            on_output_manager (output_manager);
        }
        else
            warning ("Failed to bind outputs!");

        if (toplevel_proxy != null && seat != null) {
            toplevel_manager = new ToplevelManager (toplevel_proxy, display, seat);
            print("Toplevel manager\n");

            on_toplevel_manager (toplevel_manager);
        }
        else
            warning ("Failed to bind toplevel management!");

        int fd = display.get_fd ();
        dispatch_channel = new IOChannel.unix_new (fd);

        dispatch_id = dispatch_channel.add_watch (IOCondition.IN | IOCondition.ERR | IOCondition.HUP, (source, condition) => {
            if ((condition & IOCondition.IN) != 0) {
                display.dispatch ();
                display.flush ();
                return true;
            }

            return false;
        });

        display.flush ();
    }

    internal void stop () {
        if (toplevel_manager != null)
            toplevel_manager.stop ();
        if (output_manager != null)
            output_manager.stop ();
        if (output_proxies != null)
            output_proxies.clear ();
        if (seat != null) {
            seat.release ();
            display.flush ();
        }

        Source.remove (dispatch_id);
        dispatch_channel.shutdown (true);
    }
}
