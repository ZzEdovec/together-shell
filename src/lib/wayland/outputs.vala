namespace TogetherShell { // TODO: Rework for wlr and reuse again
    public class Output : Object {
        internal Wl.Output wl_output;
        private unowned Registry registry;
        private const Wl.OutputListener output_listener = {
            on_geometry,
            on_mode,
            on_done,
            on_scale,
            on_name,
            on_description
        };

        public int32 x { get; private set; }
        public int32 y { get; private set; }
        public int32 phys_width { get; private set; }
        public int32 phys_height { get; private set; }
        public int32 subpixel { get; private set; }
        public int32 transform { get; private set; }
        public uint32 mode_flags { get; private set; }
        public int32 mode_width { get; private set; }
        public int32 mode_height { get; private set; }
        public int32 mode_refresh { get; private set; }
        public int32 scale_factor { get; private set; }
        public string name { get; private set; }
        public string description { get; private set; }
        public string manufacturer { get; private set; }
        public string model { get; private set; }

        public signal void geometry (int32 x, int32 y, int32 phys_width, int32 phys_height, int32 subpixel, string oem, string model, int32 transform);
        public signal void mode (uint32 flags, int32 width, int32 height, int32 refresh);

        internal Output (owned Wl.Output output, Registry registry) {
            this.registry = registry;
            wl_output = (owned) output;

            wl_output.add_listener (output_listener, this);
            registry.display.roundtrip ();
        }

        private static void on_geometry (void* data, Wl.Output output, int32 x, int32 y, int32 w, int32 h, int32 subp, string make, string model, int32 transform) {
            var self = (Output) data;

            self.x = x;
            self.y = y;
            self.phys_width = w;
            self.phys_height = h;
            self.subpixel = subp;
            self.manufacturer = make;
            self.model = model;
            self.transform = transform;

            self.geometry (x, y, w, h, subp, make, model, transform);
        }

        private static void on_mode (void* data, Wl.Output output, uint32 flags, int32 width, int32 height, int32 refresh) {
            var self = (Output) data;

            self.mode_flags = flags;
            self.mode_width = width;
            self.mode_height = height;
            self.mode_refresh = refresh;

            self.mode (flags, width, height, refresh);
        }

        private static void on_done (void* data, Wl.Output output) {}

        private static void on_scale (void* data, Wl.Output output, int32 factor) {
            ((Output) data).scale_factor = factor;
        }

        private static void on_name (void* data, Wl.Output output, string name) {
            ((Output) data).name = name;
        }

        private static void on_description (void* data, Wl.Output output, string description) {
            ((Output) data).description = description;
        }

        ~Output () {
            wl_output.release ();
            registry.display.flush ();
        }
    }

    public class OutputsKeeper : Object {
        private unowned Registry registry;
        private Gee.HashMap<uint32, Output> _outputs = new Gee.HashMap<uint32, Output> ();
        public Output[] outputs { owned get { return _outputs.values.to_array (); }}

        public signal void output_added (Output output);
        public signal void output_removed (Output output);

        internal OutputsKeeper (Registry registry) {
            this.registry = registry;
        }

        internal void add_output (uint32 id, owned Wl.Output output) {
            var goutput = new Output ((owned) output, registry);
            _outputs[id] = goutput;

            output_added (goutput);
        }

        internal void remove_output (uint32 id) {
            if (_outputs.has_key (id)) {
                output_removed (_outputs[id]);
                _outputs.unset (id);
            }
        }

        public Output? get_output (Wl.Output wl_output) {
            foreach (var output in _outputs.values) {
                if (output.wl_output == wl_output)
                    return output;
            }

            return null;
        }

        public Output? get_output_by_widget (Gtk.Widget widget) {
            var surface = widget.get_native ().get_surface ();
            if (surface == null)
                return null;

            var monitor = widget.get_display ().get_monitor_at_surface (surface);
            if (monitor == null)
                return null;

            foreach (var output in _outputs.values) {
                print ("%s %s\n", monitor.manufacturer, output.manufacturer);
                print ("%s %s\n", monitor.model, output.model);
                print ("%s %s\n", monitor.description, output.description);
                if (monitor.manufacturer == output.manufacturer && monitor.model == output.model && monitor.description == output.description) // i think its enougth :D
                    return output;
            }

            return null;
        }

        public Output? get_output_by_id (uint32 id) {
            if (_outputs.has_key (id))
                return _outputs[id];
            else
                return null;
        }

        public Output? get_output_by_x_y (int32 x, int32 y) {
            foreach (var entry in _outputs) {
                if (entry.value.x == x && entry.value.y == y)
                    return entry.value;
            }

            return null;
        }
    }
}
