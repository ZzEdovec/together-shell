using TogetherCore;
using TogetherCore.Settings.Shell;
using TogetherWayland;

namespace WindowList {
    public sealed class WindowsArea : Gtk.Overlay {
        private WindowButton draggable;
        private WindowList list;
        private Gtk.GestureDrag gesture = new Gtk.GestureDrag ();
        private Gtk.Fixed fixed = new Gtk.Fixed ();

        private double start_x;
        private double start_y;
        private double current_x;
        private double current_y;

        public WindowsArea (Interfaces.Shell.PanelContext panel) {
            list = new WindowList (panel, this);

            child = list;
            add_overlay (fixed);
            set_measure_overlay (fixed, false);

            gesture.drag_update.connect (on_drag_update);
            gesture.drag_end.connect (on_drag_end);
        }

        public void start_drag (WindowButton button, double x, double y) {
            start_x = x;
            start_y = y;

            Graphene.Point start_point = Graphene.Point.zero ();
            button.compute_point (list, start_point, out start_point);
            current_x = start_point.x;
            current_y = start_point.y;

            list.remove (button);

            if (list.orientation == Gtk.Orientation.HORIZONTAL)
                fixed.put (button, start_point.x, 0);
            else
                fixed.put (button, 0, start_point.y);

            button.add_controller (gesture);
            draggable = button;
        }

        private void on_drag_update (double x, double y) {
            if (list.orientation == Gtk.Orientation.HORIZONTAL) {
                if (x > start_x)
                    current_x += x - start_x;
                else
                    current_x -= start_x - x;
            }
            else {
                if (y > start_y)
                    current_y += y - start_y;
                else
                    current_y -= start_y - y;
            }

            fixed.move (draggable, current_x, current_y);
        }

        private void on_drag_end (double x, double y) {

        }
    }

    public sealed class WindowList : Gtk.Box {
        internal Gtk.RevealerTransitionType transition_type { get; set; }
        private WindowsArea windows_area;
        private bool rectangles_dirty = false;
        private Registry registry = new Registry ();
        private Interfaces.Shell.PanelContext panel;
        private Gee.HashMap<ToplevelWindow, Gtk.Revealer> revealers = new Gee.HashMap<ToplevelWindow, Gtk.Revealer> ();

        public WindowList (Interfaces.Shell.PanelContext panel, WindowsArea win_area) {
            this.panel = panel;
            this.windows_area = win_area;

            if (registry.toplevel_manager == null) {
                critical ("Cannot get ToplevelManager\n");
                return;
            }

            update_orientation (panel.position);
            foreach (var window in registry.toplevel_manager.windows)
                handle_window (window);

            panel.position_changed.connect (update_orientation);
            registry.toplevel_manager.window_added.connect (handle_window);
        }

        private void handle_window (ToplevelWindow window) {print ("new window\n");
            add_button (window);
            window.closed.connect (remove_button);
        }

        private void add_button (ToplevelWindow window) {
            var revealer = new Gtk.Revealer ();
            var button = new WindowButton (window);

            button.drag_started.connect ((x, y) => { windows_area.start_drag (button, x, y); });

            bind_property ("transition_type", revealer, "transition_type", BindingFlags.SYNC_CREATE);
            revealer.child = button;

            revealers[window] = revealer;
            append (revealer);

            revealer.reveal_child = true;
            Timeout.add_once (revealer.transition_duration, () => { window.set_rectangle (panel, revealer); });
        }

        private void remove_button (ToplevelWindow window) {
            Gtk.Revealer revealer;
            if (!revealers.unset (window, out revealer))
                return;

            revealer.reveal_child = false;
            Timeout.add_once (revealer.transition_duration, () => {
                rectangles_dirty = true;
                remove (revealer);
            });
        }

        public override void snapshot (Gtk.Snapshot snapshot) {
            base.snapshot (snapshot);

            if (rectangles_dirty) {
                update_rectangles ();
                rectangles_dirty = false;
            }
        }

        private void update_rectangles () {
            print ("Reset\n");
            foreach (var entry in revealers) {
                entry.key.set_rectangle (panel, entry.value);
            }
        }

        private void update_orientation (PanelPosition pos) { // TODO disable button labels when vertical
            switch (pos) {
                case (PanelPosition.TOP):
                    transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
                    orientation = Gtk.Orientation.HORIZONTAL;
                break;
                case (PanelPosition.BOTTOM):
                    transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
                    orientation = Gtk.Orientation.HORIZONTAL;
                break;
                case (PanelPosition.LEFT):
                    transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
                    orientation = Gtk.Orientation.VERTICAL;
                break;
                case (PanelPosition.RIGHT):
                    transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
                    orientation = Gtk.Orientation.VERTICAL;
                break;
            }
        }
    }

    public class Plugin : Peas.ExtensionBase, Interfaces.Shell.Plugin {
        private Interfaces.Shell.PanelContext ctx;
        private WindowsArea list;

        public void activate (Interfaces.Shell.PanelContext ctx) {
            this.ctx = ctx;
            this.list = new WindowsArea (ctx);
        }

        public Gtk.Widget get_panel_widget () {
            return list;
        }

        public Adw.Bin? get_showable_widget () { return null; }
    }
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
    ((Peas.ObjectModule) module).register_extension_type (typeof (Interfaces.Shell.Plugin), typeof (WindowList.Plugin));
}
