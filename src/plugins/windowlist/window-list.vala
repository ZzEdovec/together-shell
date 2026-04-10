using TogetherCore;
using TogetherCore.Settings.Shell;
using TogetherWayland;

namespace WindowList {
    public errordomain DraggableError {
        ALREADY_BINDED,
        NOT_BINDED
    }

    public sealed class DraggableArea : Gtk.Fixed {
        private Gtk.Widget? draggable;
        private Gee.HashMap<Gtk.Widget, Gtk.Box> binded = new Gee.HashMap<Gtk.Widget, Gtk.Box> ();

        private double start_x;
        private double start_y;
        private double current_x;
        private double current_y;

        construct {
            visible = false;
        }

        public void bind_widget (Gtk.Box parent, Gtk.Widget widget) throws DraggableError {
            if (binded.has_key (widget))
                throw new DraggableError.ALREADY_BINDED ("Already binded");

            binded[widget] = parent;

            var controller = new Gtk.GestureDrag ();
            controller.drag_begin.connect ((x, y) => { on_drag_start (widget, x, y); });
            controller.drag_update.connect (on_drag_update);
            controller.drag_end.connect (on_drag_end);

            widget.add_controller (controller);
            widget.set_data<Gtk.GestureDrag> ("drag_area_gest", controller);
        }

        public void unbind_widget (Gtk.Widget widget) throws DraggableError {
            var controller = widget.get_data<Gtk.GestureDrag?> ("drag_area_gest");
            if (controller == null || !binded.has_key (widget))
                throw new DraggableError.NOT_BINDED ("Not binded");

            widget.remove_controller (controller);
            binded.unset (widget);
            widget.set_data<Gtk.GestureDrag?> ("drag_area_gest", null);
        }

        public void on_drag_start (Gtk.Widget widget, double x, double y) {
            if (draggable != null)
                return;

            visible = true;
            draggable = widget;
            start_x = x;
            start_y = y;

            var drag_parent = binded[widget];
            Graphene.Point start_point = Graphene.Point.zero ();

            widget.compute_point (drag_parent, start_point, out start_point);
            current_x = start_point.x;
            current_y = start_point.y;
            drag_parent.remove (widget);

            if (drag_parent.orientation == Gtk.Orientation.HORIZONTAL)
                put (widget, start_point.x, 0);
            else
                put (widget, 0, start_point.y);
        }

        private void on_drag_update (double x, double y) {
            if (binded[draggable].orientation == Gtk.Orientation.HORIZONTAL) {
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

            move (draggable, current_x, current_y);
        }

        private void on_drag_end (double x, double y) {

        }
    }

    public sealed class WindowList : Gtk.Box {
        internal Gtk.RevealerTransitionType transition_type { get; set; }
        private DraggableArea drag_area;
        private bool rectangles_dirty = false;
        private Registry registry = new Registry ();
        private Interfaces.Shell.PanelContext panel;
        private Gee.HashMap<ToplevelWindow, Gtk.Revealer> revealers = new Gee.HashMap<ToplevelWindow, Gtk.Revealer> ();

        public WindowList (Interfaces.Shell.PanelContext panel, DraggableArea drag_area) {
            this.panel = panel;
            this.drag_area = drag_area;

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

            bind_property ("transition_type", revealer, "transition_type", BindingFlags.SYNC_CREATE);
            revealer.child = button;

            revealers[window] = revealer;
            append (revealer);

            drag_area.bind_widget (this, revealer);

            revealer.reveal_child = true;
            Timeout.add_once (revealer.transition_duration, () => { window.set_rectangle (panel, revealer); });
        }

        private void remove_button (ToplevelWindow window) {
            Gtk.Revealer revealer;
            if (!revealers.unset (window, out revealer))
                return;

            drag_area.unbind_widget (revealer);
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
        private Gtk.Overlay overlay = new Gtk.Overlay ();

        public void activate (Interfaces.Shell.PanelContext ctx) {
            this.ctx = ctx;

            var drag_area = new DraggableArea ();
            var win_list = new WindowList (ctx, drag_area);

            overlay.child = win_list;
            overlay.add_overlay (drag_area);
            overlay.set_measure_overlay (drag_area, false);
        }

        public Gtk.Widget get_panel_widget () {
            return overlay;
        }

        public Adw.Bin? get_showable_widget () { return null; }
    }
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
    ((Peas.ObjectModule) module).register_extension_type (typeof (Interfaces.Shell.Plugin), typeof (WindowList.Plugin));
}
