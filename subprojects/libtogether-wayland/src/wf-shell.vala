namespace TogetherWayland {
    public class HotspotV2 : Object {
        public bool active { get; private set; default = false; }

        private Zwf.HotspotV2 hotspot;
        private unowned Registry registry;
        private const Zwf.HotspotV2Listener listener = {
            on_enter,
            on_leave
        };

        internal HotspotV2 (owned Zwf.HotspotV2 hotspot, Registry registry) {
            this.hotspot = (owned) hotspot;
            this.registry = registry;

            this.hotspot.add_listener (listener, this);
            registry.display.roundtrip ();
        }

        private static void on_enter (void* data, Zwf.HotspotV2 hotspot) {
            ((HotspotV2) data).active = true;
        }

        private static void on_leave (void* data, Zwf.HotspotV2 hotspot) {
            ((HotspotV2) data).active = false;
        }

        ~HotspotV2 () {
            hotspot.destroy ();
            registry.display.flush ();
        }
    }

    public class OutputV2 : Object {
        private Zwf.OutputV2 output;
        private unowned Registry registry;
        private const Zwf.OutputV2Listener listener = {
            on_enter_fullscreen,
            on_leave_fullscreen,
            on_toggle_menu
        };

        private bool _inhibited = false;
        public bool inhibited {
            get {
                return _inhibited;
            } set {
                if (value)
                    output.inhibit_output ();
                else
                    output.inhibit_output_done ();

                _inhibited = value;
                registry.display.flush ();
            }
        }
        public bool menu_toggled { get; private set; }
        public bool has_fullscreen { get; private set; }

        internal OutputV2 (owned Zwf.OutputV2 output, Registry registry) {
            this.output = (owned) output;
            this.registry = registry;

            this.output.add_listener (listener, this);
            registry.display.roundtrip ();
        }

        private static void on_enter_fullscreen (void* data, Zwf.OutputV2 output) {
            var self = (OutputV2) data;
            self.has_fullscreen = true;

            Signal.emit_by_name (self, "notify::has_fullscreen");
        }

        private static void on_leave_fullscreen (void* data, Zwf.OutputV2 output) {
            var self = (OutputV2) data;
            self.has_fullscreen = false;

            Signal.emit_by_name (self, "notify::has_fullscreen");
        }

        private static void on_toggle_menu (void* data, Zwf.OutputV2 output) {
            var self = (OutputV2) data;
            self.menu_toggled = !self.menu_toggled;

            Signal.emit_by_name (self, "notify::menu_toggled");
        }

        public HotspotV2 create_hotspot (uint32 hotspot, uint32 threshold, uint32 timeout) {
            return new HotspotV2 (output.create_hotspot (hotspot, threshold, timeout), registry);
        }

        ~OutputV2 () {
            output.destroy ();
            registry.display.flush ();
        }
    }

    public class SurfaceV2 : Object {
        private Zwf.SurfaceV2 surface;
        private unowned Registry registry;

        internal SurfaceV2 (owned Zwf.SurfaceV2 surface, Registry registry) {
            this.surface = (owned) surface;
            this.registry = registry;
        }

        public void interactive_move () {
            surface.interactive_move ();
            registry.display.flush ();
        }

        ~SurfaceV2 () {
            surface.destroy ();
            registry.display.flush ();
        }
    }

    public class WayfireShellManager : Object {
        private Zwf.ShellManagerV2 manager;
        private unowned Registry registry;

        private Gee.HashMap<Output, OutputV2> _outputs = new Gee.HashMap<Output, OutputV2> ();
        public OutputV2[] outputs { owned get { return _outputs.values.to_array (); }}

        internal WayfireShellManager (owned Zwf.ShellManagerV2 manager, Registry registry) {
            this.manager = (owned) manager;
            this.registry = registry;

            foreach (var output in registry.outputs_keeper.outputs)
                _outputs[output] = new OutputV2 (this.manager.get_wf_output (output.wl_output), registry);

            registry.outputs_keeper.output_added.connect ((output) => { _outputs[output] = new OutputV2 (this.manager.get_wf_output (output.wl_output), this.registry); });
            registry.outputs_keeper.output_removed.connect ((output) => { _outputs.unset (output); });
        }

        public OutputV2 get_wf_output (Output output) {
            return _outputs[output];
        }

        public OutputV2? get_wf_output_for_wl (Wl.Output wl_output) {
            foreach (var output in _outputs.keys) {
                if (output.wl_output == wl_output)
                    return _outputs[output];
            }

            return null;
        }

        public SurfaceV2 get_wf_surface (Wl.Surface surface) {
            return new SurfaceV2 (manager.get_wf_surface (surface), registry);
        }

        ~WayfireShellManager () {
            manager.destroy ();
            registry.display.flush ();
        }
    }
}
