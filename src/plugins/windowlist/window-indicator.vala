using TogetherCore.Settings.Shell;

namespace WindowList {
    public sealed class WindowIndicator : Gtk.Widget, Gtk.Orientable {
        private uint _count = 1;
        private Gtk.Orientation _orientation = Gtk.Orientation.HORIZONTAL;
        private uint dots_length;
        private uint _dot_size = 4;
        private uint _dot_gap = 2;
        public uint count {
            get { return _count; }
            set {
                _count = value;
                dots_length = _count * _dot_size + (_count - 1) * _dot_gap;
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
                dots_length = _count * _dot_size + (_count - 1) * _dot_gap;
                queue_draw ();
            }
        }
        public uint dot_gap {
            get { return _dot_gap; }
            set {
                _dot_gap = value;
                dots_length = _count * _dot_size + (_count - 1) * _dot_gap;
                queue_draw ();
            }
        }

        construct {
            dots_length = _count * _dot_size + (_count - 1) * _dot_gap;
        }

        public override void snapshot (Gtk.Snapshot snapshot) {
            if (_count == 0)
                return;

            int[] size = { get_width (), get_height () };
            var rect = Graphene.Rect ();
            var cairo = snapshot.append_cairo (rect.init (0, 0, size[0], size[1]));

            var color = get_color ();
            cairo.set_source_rgba (color.red, color.green, color.blue, color.alpha);

            double cx, cy;
            double r = _dot_size / 2;

            for (uint i = 0; i < _count; i++) {
                if (orientation == Gtk.Orientation.HORIZONTAL) {
                    cx = (size[0] - dots_length) / 2 + i * (_dot_size + _dot_gap) + r;
                    cy = size[1] / 2;
                }
                else {
                    cx = size[0] / 2;
                    cy = (size[1] - dots_length) / 2 + i * (_dot_size + _dot_gap) + r;
                }

                cairo.arc (cx, cy, r, 0, 2 * Math.PI);
                cairo.fill ();
            }
        }

        public override void measure (Gtk.Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
            if (orientation == Gtk.Orientation.HORIZONTAL) {
                minimum = natural = _orientation == Gtk.Orientation.HORIZONTAL ? (int) dots_length : (int) _dot_size;
                minimum_baseline = natural_baseline = -1;
            }
            else {
                minimum = natural = _orientation == Gtk.Orientation.VERTICAL ? (int) dots_length : (int) _dot_size;
                minimum_baseline = natural_baseline = (int) (_dot_size / 2);
            }
        }
    }
}
