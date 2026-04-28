namespace TogetherWidgets {
    public errordomain DraggableError {
        ALREADY_BINDED,
        NOT_BINDED
    }

    private class Draggable {
        public Gtk.Widget widget;
        public Gtk.GestureDrag controller;
        public double start_opacity;
        public double start_x;
        public double start_y;

        public Draggable (Gtk.Widget widget, Gtk.GestureDrag controller, double? start_x = 0, double? start_y = 0) {
            this.widget = widget;
            this.controller = controller;
            this.start_opacity = widget.opacity;
            this.start_x = start_x;
            this.start_y = start_y;
        }
    }

    // this widget must be placed as overlay above draggable widgets parent
    public sealed class DraggableArea : Gtk.Fixed {
        public Gtk.Orientation orientation { get; set; }
        public Gtk.Widget below_widget { get; private set; }
        private Draggable? draggable;
        private Gtk.Picture picture = new Gtk.Picture ();
        private double picture_x = 0;
        private double picture_y = 0;
        private Gee.HashMap<Gtk.Widget, Draggable> binded = new Gee.HashMap<Gtk.Widget, Draggable> ();

        public signal void below_finded (Gtk.Widget widget, Gtk.Widget below_widget);
        public signal void below_lost (Gtk.Widget widget, Gtk.Widget below_widget);
        public signal void drag_ended (Gtk.Widget widget, Gtk.Widget? below_widget);

        construct {
            visible = false;
            put (picture, 0, 0);
        }

        public void bind_widget (Gtk.Widget widget) throws DraggableError {
            if (binded.has_key (widget))
                throw new DraggableError.ALREADY_BINDED ("Already binded");

            var controller = new Gtk.GestureDrag ();
            controller.propagation_phase = Gtk.PropagationPhase.CAPTURE;
            controller.drag_begin.connect ((x, y) => { on_drag_start (widget, x, y); });
            controller.drag_update.connect (on_drag_update);
            controller.drag_end.connect (on_drag_end);
            widget.add_controller (controller);

            binded[widget] = new Draggable (widget, controller);
        }

        public void unbind_widget (Gtk.Widget widget) throws DraggableError {
            if (!binded.has_key (widget))
                throw new DraggableError.NOT_BINDED ("Not binded");

            widget.remove_controller (binded[widget].controller);
            binded.unset (widget);
        }

        private Gtk.Widget? find_below_widget () {
            foreach (var widget in binded.keys) {
                var point = Graphene.Point.zero ();
                if (widget == draggable.widget || !widget.compute_point (this, point, out point))
                    continue;

                bool intersects = picture_x < point.x + widget.get_width () &&
                                  picture_x + picture.get_width () > point.x &&
                                  picture_y < point.y + widget.get_height () &&
                                  picture_y + picture.get_height () > point.y;
                if (intersects)
                    return widget;
            }

            return null;
        }

        private void move_picture (double x, double y) {
            picture_x = x;
            picture_y = y;

            move (picture, x, y);
        }

        private void on_drag_start (Gtk.Widget widget, double x, double y) {print ("drag_start called\n");
            if (draggable != null)
                return;

            draggable = binded[widget];

            var start_point = Graphene.Point.zero ();
            if (!widget.compute_point (this, start_point, out start_point))
                return;

            draggable.start_x = start_point.x;
            draggable.start_y = start_point.y;

            if (orientation == Gtk.Orientation.HORIZONTAL)
                move_picture (start_point.x, 0);
            else if (orientation == Gtk.Orientation.VERTICAL)
                move_picture (0, start_point.y);
            else
                move_picture (start_point.x, start_point.y);
        }

        private void on_drag_update (double x, double y) {
            if (!visible &&
            (draggable.start_x + x < draggable.start_x - 5 || draggable.start_x + x > draggable.start_x + 5) ||
            (draggable.start_y + y < draggable.start_y - 5 || draggable.start_y + y > draggable.start_y + 5)) {
                visible = true;
                draggable.widget.opacity = 0;
                draggable.controller.set_state (Gtk.EventSequenceState.CLAIMED);

                Gtk.Snapshot snapshot = new Gtk.Snapshot ();
                draggable.widget.snapshot (snapshot);

                var size = Graphene.Size () {
                    width = draggable.widget.get_width (),
                    height = draggable.widget.get_height ()
                };
                picture.paintable = snapshot.free_to_paintable (size);
                picture.set_size_request ((int) size.width, (int) size.height);
            }

            if (orientation == Gtk.Orientation.HORIZONTAL)
                move_picture (draggable.start_x + x, picture_y);
            else if (orientation == Gtk.Orientation.VERTICAL)
                move_picture (picture_x, draggable.start_y + y);
            else
                move_picture (draggable.start_x + x, draggable.start_y + y);

            var below = find_below_widget ();
            if (below != null && below != below_widget) {
                below_widget = below;
                below_finded (draggable.widget, below);
            }
            else if (below == null && below_widget != null) {
                below_lost (draggable.widget, below_widget);
                below_widget = null;
            }
        }

        private void on_drag_end (double x, double y) {print ("drag_end called\n");
            if (draggable.widget.opacity == 0) {
                drag_ended (draggable.widget, find_below_widget ());
                draggable.widget.opacity = draggable.start_opacity;
            }

            draggable = null;
            picture.paintable = null;
            below_widget = null;

            visible = false;
        }
    }
}
