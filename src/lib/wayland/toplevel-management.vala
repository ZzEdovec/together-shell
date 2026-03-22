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
    internal unowned Zwlr.ForeignToplevelHandleV1? parent;
    internal unowned Zwlr.ForeignToplevelHandleV1 handle;
    private unowned Wl.Display display;
    private unowned Wl.Seat seat;
    private Zwlr.ForeignToplevelHandleV1Listener handle_listener;

    public Gee.ArrayList<Output> current_outputs;
    public string title;
    public string app_id;
    public bool maximized;
    public bool minimized;
    public bool activated;
    public bool fullscreen;

    public signal void on_title (string title);
    public signal void on_appid (string app_id);
    public signal void on_output_enter (Wl.Output output);
    public signal void on_output_leave (Wl.Output output);
    public signal void on_parent (Zwlr.ForeignToplevelHandleV1 handle);
    public signal void on_state ();
    public signal void on_closed ();

    public ToplevelWindow (Zwlr.ForeignToplevelHandleV1 handle, Wl.Display display, Wl.Seat seat) {
        this.handle = handle;
        this.display = display;
        this.seat = seat;
        this.current_outputs = new Gee.ArrayList<Output> ();

        this.handle_listener = Zwlr.ForeignToplevelHandleV1Listener () {
            title = (data, h, t) => {
                unowned ToplevelWindow self = (ToplevelWindow) data;

                self.title = t;
                self.on_title (self.title);
            },

            app_id = (data, h, id) => {
                unowned ToplevelWindow self = (ToplevelWindow) data;

                self.app_id = id;
                self.on_appid (self.app_id);
            },

            output_enter = (data, h, o) =>
            {
                unowned ToplevelWindow self = (ToplevelWindow) data;

                self.on_output_enter (o);
            },

            output_leave = (data, h, o) =>
            {
                unowned ToplevelWindow self = (ToplevelWindow) data;

                self.on_output_leave (o);
            },

            state = (data, h, state_array) => {
                unowned ToplevelWindow self = (ToplevelWindow) data;

                self.parse_state (state_array);
                self.on_state ();
            },

            done = (data, h) => {},

            closed = (data, h) => {
                unowned ToplevelWindow self = (ToplevelWindow) data;

                self.on_closed ();
            },

            parent = (data, h, parent) => {
                unowned ToplevelWindow self = (ToplevelWindow) data;

                self.parent = parent;
                self.on_parent (parent);
            },
        };

        handle.add_listener(ref this.handle_listener, (void*) this);
    }

    ~ToplevelWindow () {
        if (handle != null)
            handle.destroy ();
    }

    private void parse_state (Wl.Array state_array) {
        if (state_array.data == null) return;

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
        handle.activate(seat);

        display.flush ();
    }

    public void close_window () {
        handle.close();

        display.flush ();
    }

    public void toggle_maximize () {
        if (maximized) {
            handle.unset_maximized();
        } else {
            handle.set_maximized();
        }

        display.flush ();
    }

    public void toggle_minimize () {
        if (minimized) {
            handle.unset_minimized();
        } else {
            handle.set_minimized();
        }

        display.flush ();
    }

    public void minimize () {
        handle.set_minimized ();
        display.flush ();
    }

    public void unminimize () {
        handle.unset_minimized ();
        display.flush ();
    }

    public void maximize () {
        handle.set_maximized ();
        display.flush ();
    }

    public void unmaximize () {
        handle.unset_maximized ();
        display.flush ();
    }

    public void toggle_fullscreen (Wl.Output? output = null) {
        if (fullscreen) {
            handle.unset_fullscreen();
        } else {
            handle.set_fullscreen(output);
        }

        display.flush ();
    }
}

public class TogetherShell.ToplevelManager : Object {
    public Gee.ArrayList<ToplevelWindow> windows;
    private unowned Wl.Display display;
    private unowned Wl.Seat seat;
    private unowned Zwlr.ForeignToplevelManagerV1 manager;
    private Zwlr.ForeignToplevelManagerV1Listener manager_listener;

    public signal void window_added (ToplevelWindow window);

    internal ToplevelManager (Zwlr.ForeignToplevelManagerV1 manager, Wl.Display display, Wl.Seat seat) {
        this.windows = new Gee.ArrayList<ToplevelWindow> ();
        this.display = display;
        this.seat = seat;
        this.manager = manager;

        this.manager_listener = Zwlr.ForeignToplevelManagerV1Listener () {
            toplevel = (data, mgr, handle) => {
                unowned ToplevelManager self = (ToplevelManager) data;

                var window = new ToplevelWindow (handle, self.display, self.seat);
                weak ToplevelWindow window_weak = window; // If we pass a strong ref, the ToplevelWindow destructor will never work and we get a memory leak.
                window.on_closed.connect (() => {self.windows.remove (window_weak);});

                self.windows.add (window);
                self.window_added (window);
            },
            finished = (data, mgr) => {
                unowned ToplevelManager self = (ToplevelManager) data;

                self.windows.clear ();
                self.display.flush ();
            },
        };

        manager.add_listener (ref this.manager_listener, (void*) this);
    }

    internal void stop () {
        manager.stop ();

        display.flush ();
    }
}
