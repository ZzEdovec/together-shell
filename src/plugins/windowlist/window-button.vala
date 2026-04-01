using TogetherWayland;

namespace WindowList {
    public class WindowButton : Gtk.ToggleButton {
        private ToplevelWindow window;
        private Gtk.Revealer revealer = new Gtk.Revealer ();
        private Gtk.Label title = new Gtk.Label (_("Unknown app"));
        private Gtk.Image icon = new Gtk.Image ();

        public WindowButton (ToplevelWindow window) {
            this.window = window;

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            box.margin_start = box.margin_end = 8;
            box.append (title);
            box.append (icon);

            revealer.
        }

        private void update_app_info () {

        }
    }
}
