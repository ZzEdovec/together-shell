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

public class TogetherShell.Output : Object {
    internal unowned Wl.Output output;
    private unowned Wl.Display display;
    private Wl.OutputListener output_listener;

    public int x;
    public int y;
    public int phys_width;
    public int phys_height;
    public int subpixel;
    public int transform;
    public uint mode_flags;
    public int mode_width;
    public int mode_height;
    public int mode_refresh;
    public int scale_factor;
    public string name;
    public string description;
    public string manufacturer;
    public string model;

    public signal void on_geometry (int x, int y, int phys_width, int phys_height, int subpixel, string oem, string model, int transform);
    public signal void on_mode (uint flags, int width, int height, int refresh);
    public signal void on_scale (int factor);
    public signal void on_name (string name);
    public signal void on_description (string desc);

    internal Output (Wl.Output output, Wl.Display display) {
        this.output = output;
        this.display = display;

        output_listener = Wl.OutputListener () {
            geometry = (data, o, x, y, w, h, subp, make, model, transform) =>
            {
                stdout.printf ("geometry\n");
                unowned Output self = (Output) data;

                self.x = x;
                self.y = y;
                self.phys_width = w;
                self.phys_height = h;
                self.subpixel = subp;
                self.manufacturer = make;
                self.model = model;
                self.transform = transform;
            },

            mode = (data, o, flags, width, height, refresh) => {
                unowned Output self = (Output) data;

                self.mode_flags = flags;
                self.mode_width = width;
                self.mode_height = height;
                self.mode_refresh = refresh;
            },

            done = (data, o) => {},

            scale = (data, o, fac) =>
            {
                unowned Output self = (Output) data;

                self.scale_factor = fac;
            },

            name = (data, o, name) => {
                unowned Output self = (Output) data;

                self.name = name;
            },

            description = (data, o, desc) => {
                unowned Output self = (Output) data;

                self.description = desc;
            },
        };

        output.add_listener (ref output_listener, (void*) this);
    }

    ~Output () {
        output.release ();
    }
}

public class TogetherShell.OutputManager : Object {
    internal Gee.HashMap<uint,Output> outputs;
    private unowned Wl.Display display;

    public signal void output_added (Output output);

    internal OutputManager (Wl.Display display) {
        this.outputs = new Gee.HashMap<uint,Output> ();
        this.display = display;
    }

    internal void add_output (uint id, Wl.Output output) {
        var tg_output = new Output (output, display);
        outputs[id] = tg_output;

        output_added (tg_output);
    }

    internal void remove_output (uint id) {
        if (outputs[id] != null)
            outputs.unset (id);
    }

    internal void stop () {
        outputs.clear ();
        display.flush ();
    }

    public Output? get_output (Wl.Output output) {
        foreach (var entry in outputs) {
            if (entry.value.output == output)
                return entry.value;
        }

        return null;
    }

    public Output? get_output_by_id (uint id) {
        return outputs[id];
    }

    public Output? get_output_by_x_y (int x, int y) {
        foreach (var entry in outputs) {
            if (entry.value.x == x && entry.value.y == y)
                return entry.value;
        }

        return null;
    }
}
