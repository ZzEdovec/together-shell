namespace WindowList {
    public sealed class WindowIndicator : Gtk.Widget {
        private uint _count = 0;
        public uint count {
            get {
                return _count;
            }
            set {
                _count = value.clamp (0, 3);
                queue_draw ();
            }
        }
        public uint dot_width { get; set; default = 14; }
        public uint dot_height { get; set; default = 3; }
        public uint dot_gap { get; set; default = 4; }

        construct {
            height_request = 4;
        }

        public override bool contains (double x, double y) {
            return false;
        }

        public override void snapshot (Gtk.Snapshot snapshot) {print ("snapshot called: w=%d h=%d count=%u\n", get_width (), get_height (), _count);
            if (_count == 0)
                return;

            int[] size = { get_width (), get_height () };
            Gdk.RGBA color = { 255, 255, 255, 1 };

            float total = _count * dot_width + (_count - 1) * dot_gap;
            float x = (size[0] - total) / 2;
            float y = (size[1] - dot_height) / 2;

            for (uint i = 0; i < _count; i++) {
                var rect = Graphene.Rect ();
                var rounded = Gsk.RoundedRect ();

                rect.init (x + i * (dot_width + dot_gap), y, dot_width, dot_height);
                rounded.init_from_rect (rect, dot_height / 2);

                snapshot.push_rounded_clip (rounded);
                snapshot.append_color (color, rect);
                snapshot.pop ();
            }
        }
    }
}
