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

public class TogetherShell.ToplevelWindow : Object {
    private unowned Registry registry;
    private unowned Zwlr.ForeignToplevelHandleV1? parent; // TODO
    private unowned Zwlr.ForeignToplevelHandleV1 handle;
    private Zwlr.ForeignToplevelHandleV1Listener handle_listener;

    public Output[] current_outputs { get; private set; }
    public string title { get; private set; }
    public string app_id { get; private set; }
    public bool maximized { get; private set; }
    public bool minimized { get; private set; }
    public bool activated { get; private set; }
    public bool fullscreen { get; private set; }

    public signal void on_state ();
    public signal void on_closed ();

    public ToplevelWindow (Zwlr.ForeignToplevelHandleV1 handle, Registry registry) {
        this.handle = handle;
        this.registry = registry;

        handle_listener = Zwlr.ForeignToplevelHandleV1Listener () {
            title = (data, h, t) => {
                var self = (ToplevelWindow) data;
                self.title = t;

                Signal.emit_by_name (self, "notify::title");
            },

            app_id = (data, h, id) => {
                var self = (ToplevelWindow) data;
                self.app_id = id;

                Signal.emit_by_name (self, "notify::app_id");
            },

            output_enter = (data, h, o) =>
            {
                // TODO
            },

            output_leave = (data, h, o) =>
            {
                // TODO
            },

            state = (data, h, state_array) => {
                var self = (ToplevelWindow) data;

                self.parse_state (state_array);
                self.on_state ();
            },

            done = (data, h) => {},

            closed = (data, h) => {
                var self = (ToplevelWindow) data;
                self.on_closed ();
            },

            parent = (data, h, parent) => {
                var self = (ToplevelWindow) data;
                self.parent = parent;
            },
        };

        this.handle.add_listener (ref handle_listener, this);
        registry.display.roundtrip ();
    }

    private void parse_state (Wl.Array state_array) {
        if (state_array.data == null)
            return;

        maximized = false;
        minimized = false;
        activated = false;
        fullscreen = false;

        uint32* data = (uint32*) state_array.data;
        size_t count = state_array.size / sizeof(uint32);

        for (size_t i = 0; i < count; i++) {
            var state = (Zwlr.ForeignToplevelHandleV1State) data[i];

            switch (state) {
                case Zwlr.ForeignToplevelHandleV1State.MAXIMIZED:
                    maximized = true;
                break;
                case Zwlr.ForeignToplevelHandleV1State.MINIMIZED:
                    minimized = true;
                break;
                case Zwlr.ForeignToplevelHandleV1State.ACTIVATED:
                    activated = true;
                break;
                case Zwlr.ForeignToplevelHandleV1State.FULLSCREEN:
                    fullscreen = true;
                break;
            }
        }
    }

    public void activate () {
        handle.activate(registry.seat_proxy);

        registry.display.flush ();
    }

    public void close_window () {
        handle.close();

        registry.display.flush ();
    }

    public void toggle_maximize () {
        if (maximized) {
            handle.unset_maximized();
        } else {
            handle.set_maximized();
        }

        registry.display.flush ();
    }

    public void toggle_minimize () {
        if (minimized)
            handle.unset_minimized();
        else
            handle.set_minimized();

        registry.display.flush ();
    }

    public void minimize () {
        handle.set_minimized ();
        registry.display.flush ();
    }

    public void unminimize () {
        handle.unset_minimized ();
        registry.display.flush ();
    }

    public void maximize () {
        handle.set_maximized ();
        registry.display.flush ();
    }

    public void unmaximize () {
        handle.unset_maximized ();
        registry.display.flush ();
    }

    public void toggle_fullscreen (Wl.Output? output = null) {
        if (fullscreen)
            handle.unset_fullscreen();
        else
            handle.set_fullscreen(output);

        registry.display.flush ();
    }

    ~ToplevelWindow () {
        handle.destroy ();
        registry.display.flush ();
    }
}

public class TogetherShell.ToplevelManager : Object {
    public Gee.ArrayList<ToplevelWindow> windows = new Gee.ArrayList<ToplevelWindow> ();
    private unowned Registry registry;
    private Zwlr.ForeignToplevelManagerV1 manager;
    private Zwlr.ForeignToplevelManagerV1Listener manager_listener;

    public signal void window_added (ToplevelWindow window);

    internal ToplevelManager (owned Zwlr.ForeignToplevelManagerV1 manager, Registry registry) {
        this.registry = registry;
        this.manager = (owned) manager;

        manager_listener = Zwlr.ForeignToplevelManagerV1Listener () {
            toplevel = (data, mgr, handle) => {
                var self = (ToplevelManager) data;

                var window = new ToplevelWindow (handle, self.registry); // ??
                weak ToplevelWindow window_weak = window; // If we pass a strong ref, the ToplevelWindow destructor will never work and we get a memory leak.
                window.on_closed.connect (() => {self.windows.remove (window_weak);});

                self.windows.add (window);
                self.window_added (window);
            },
            finished = (data, mgr) => {
                var self = (ToplevelManager) data;

                self.windows.clear ();
                self.registry.display.flush ();
            },
        };

        this.manager.add_listener (ref manager_listener, this);
        registry.display.flush ();
    }

    ~ToplevelManager () {
        manager.stop ();
        registry.display.flush ();
    }
}




