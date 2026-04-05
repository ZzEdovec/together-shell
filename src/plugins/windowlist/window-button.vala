using TogetherWayland;
using TogetherCore;

namespace WindowList {
    public class WindowButton : Gtk.ToggleButton {
        private ToplevelWindow window;
        private AppInfoManager appinfo_manager = new AppInfoManager ();
        private Gtk.Revealer revealer = new Gtk.Revealer ();
        private Gtk.Label title = new Gtk.Label (_("Unknown app"));
        private Gtk.Image icon = new Gtk.Image ();

        public WindowButton (ToplevelWindow window) {
            this.window = window;

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            box.margin_start = box.margin_end = 8;
            box.append (title);
            box.append (icon);

            revealer.child = box;
            child = revealer;
        }

        private void update_app_info () {
            var app = appinfo_manager.get_by_id (window.app_id) ?? appinfo_manager.get_by_wm_class (window.app_id);
            if (app == null)
                return;

            title.label = app.get_display_name () ?? window.title ?? _("Unknown app");
            var gicon = app.get_icon ();
            if (gicon != null)
                icon.set_from_gicon (gicon);
            else
                icon.icon_name = "application-x-executable-symbolic";
        }
    }
}
