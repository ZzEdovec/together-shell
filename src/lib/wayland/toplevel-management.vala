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

namespace TogetherShell {
    public class ToplevelWindow : Object {
        private unowned Registry registry;
        internal unowned Zwlr.ForeignToplevelHandleV1 handle;
        private Gee.ArrayList<Output> _current_outputs = new Gee.ArrayList<Output> ();
        private const Zwlr.ForeignToplevelHandleV1Listener listener = {
            on_title,
            on_appid,
            on_output_enter,
            on_output_leave,
            on_state,
            on_done,
            on_close,
            on_parent
        };

        public Output[] current_outputs {
            owned get {
                return _current_outputs.to_array ();
            }
        }
        public string title { get; private set; }
        public string app_id { get; private set; }
        public bool maximized { get; private set; }
        public bool minimized { get; private set; }
        public bool activated { get; private set; }
        public bool fullscreen { get; private set; }
        public ToplevelWindow? parent { get; private set; }

        public signal void output_enter (Output output);
        public signal void output_leave (Output output);
        public signal void state ();
        public signal void closed ();

        public ToplevelWindow (Zwlr.ForeignToplevelHandleV1 handle, Registry registry) {
            this.handle = handle;
            this.registry = registry;

            this.handle.add_listener (listener, this);
            registry.display.roundtrip ();
        }

        private static void on_title (void* data, Zwlr.ForeignToplevelHandleV1 handle, string title) {
            var self = (ToplevelWindow) data;

            self.title = title;
            Signal.emit_by_name (self, "notify::title");
        }

        private static void on_appid (void* data, Zwlr.ForeignToplevelHandleV1 handle, string id) {
            var self = (ToplevelWindow) data;

            self.app_id = id;
            Signal.emit_by_name (self, "notify::app_id");
        }

        private static void on_output_enter (void* data, Zwlr.ForeignToplevelHandleV1 handle, Wl.Output wl_output) {
            var self = (ToplevelWindow) data;
            var output = self.registry.outputs_keeper.get_output (wl_output);

            self._current_outputs.add (output);
            self.output_enter (output);
        }

        private static void on_output_leave (void* data, Zwlr.ForeignToplevelHandleV1 handle, Wl.Output wl_output) {
            var self = (ToplevelWindow) data;
            var output = self.registry.outputs_keeper.get_output (wl_output);

            self._current_outputs.remove (output);
            self.output_leave (output);
        }

        private static void on_state (void* data, Zwlr.ForeignToplevelHandleV1 handle, Wl.Array state) {
            var self = (ToplevelWindow) data;
            self.parse_state (state);
            self.state ();
        }

        private static void on_done (void* data, Zwlr.ForeignToplevelHandleV1 handle) {}

        private static void on_close (void* data, Zwlr.ForeignToplevelHandleV1 handle) {
            ((ToplevelWindow) data).closed ();
        }

        private static void on_parent (void* data, Zwlr.ForeignToplevelHandleV1 handle, Zwlr.ForeignToplevelHandleV1? wl_parent) {
            var self = (ToplevelWindow) data;
            if (wl_parent == null)
                return;

            var parent = self.registry.toplevel_manager.get_window (wl_parent);
            if (parent != null) {
                print ("has parent!\n");
                self.parent = parent;
                Signal.emit_by_name (self, "notify::parent");
            }
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
            handle.activate (registry.seat_proxy);

            registry.display.flush ();
        }

        public void close_window () {
            handle.close ();

            registry.display.flush ();
        }

        public void toggle_maximize () {
            if (maximized)
                handle.unset_maximized ();
            else
                handle.set_maximized ();

            registry.display.flush ();
        }

        public void toggle_minimize () {
            if (minimized)
                handle.unset_minimized ();
            else
                handle.set_minimized ();

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
                handle.unset_fullscreen ();
            else
                handle.set_fullscreen (output);

            registry.display.flush ();
        }

        ~ToplevelWindow () {
            handle.destroy ();
            registry.display.flush ();
        }
    }

    public class ToplevelManager : Object {
        private Gee.ArrayList<ToplevelWindow> _windows = new Gee.ArrayList<ToplevelWindow> ();
        private unowned Registry registry;
        private Zwlr.ForeignToplevelManagerV1 manager;
        private const Zwlr.ForeignToplevelManagerV1Listener listener = {
            on_toplevel,
            on_finished
        };
        public ToplevelWindow[] windows {
            owned get {
                return _windows.to_array ();
            }
        }

        public signal void window_added (ToplevelWindow window);

        internal ToplevelManager (owned Zwlr.ForeignToplevelManagerV1 manager, Registry registry) {
            this.registry = registry;
            this.manager = (owned) manager;

            this.manager.add_listener (listener, this);
            registry.display.flush ();
        }

        private static void on_toplevel (void* data, Zwlr.ForeignToplevelManagerV1 manager, Zwlr.ForeignToplevelHandleV1 handle) {
            var self = (ToplevelManager) data;

            var window = new ToplevelWindow (handle, self.registry);
            weak ToplevelWindow window_weak = window; // If we pass a strong ref, the ToplevelWindow destructor will never work and we get a memory leak.
            window.closed.connect (() => {self._windows.remove (window_weak);});

            self._windows.add (window);
            self.window_added (window);
        }

        private static void on_finished (void* data, Zwlr.ForeignToplevelManagerV1 manager) {
            ((ToplevelManager) data)._windows.clear ();
        }

        public ToplevelWindow? get_window (Zwlr.ForeignToplevelHandleV1 handle) {
            foreach (var window in _windows) {
                if (window.handle == handle)
                    return window;
            }

            return null;
        }

        ~ToplevelManager () {
            manager.stop ();
            registry.display.flush ();
        }
    }
}
