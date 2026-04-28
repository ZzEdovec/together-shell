using TogetherCore.Settings.Shell;

namespace WindowList {
    public sealed class WindowIndicator : Gtk.Widget, Gtk.Orientable {
        private uint _count = 1;
        private Gtk.Orientation _orientation = Gtk.Orientation.HORIZONTAL;
        private uint _dot_size = 4;
        private uint _dot_gap = 4;
        public uint count {
            get { return _count; }
            set {
                _count = value;
                queue_draw ();
            }
        }
        public Gtk.Orientation orientation {
            get { return _orientation; }
            set {
                _orientation = value;
                queue_draw ();
            }
        }
        public uint dot_size {
            get { return _dot_size; }
            set {
                _dot_size = value;
                queue_draw ();
            }
        }
        public uint dot_gap {
            get { return _dot_gap; }
            set {
                _dot_gap = value;
                queue_draw ();
            }
        }

        public override bool contains (double x, double y) {
            return false;
        }

        public override void snapshot (Gtk.Snapshot snapshot) {
            if (_count == 0)
                return;

            int[] size = { get_width (), get_height () };
            Gdk.RGBA color = { 255, 255, 255, 1 };

            float total = _count * dot_size + (_count - 1) * dot_gap;
            float x = 0;
            float y = 0;
            if (orientation == Gtk.Orientation.HORIZONTAL) {
                x = (size[0] - total) / 2;
                y = (size[1] - dot_size) / 2;
            }
            else {
                x = (size[0] - dot_size) / 2;
                y = (size[1] - total) / 2;
            }

            for (uint i = 0; i < _count; i++) {
                var rect = Graphene.Rect ();
                var rounded = Gsk.RoundedRect ();

                if (orientation == Gtk.Orientation.HORIZONTAL)
                    rect.init (x + i * (dot_size + dot_gap), y, dot_size, dot_size);
                else
                    rect.init (x, y + i * (dot_size + dot_gap), dot_size, dot_size);

                rounded.init_from_rect (rect, dot_size / 2);

                snapshot.push_rounded_clip (rounded);
                snapshot.append_color (color, rect);
                snapshot.pop ();

            }
        }
    }
}
