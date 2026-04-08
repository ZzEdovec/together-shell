using TogetherWayland;
using TogetherCore;
using TogetherCore.Managers;

namespace WindowList {
    public class WindowButton : Gtk.ToggleButton {
        private unowned Interfaces.Shell.PanelContext panel;
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

            window.notify["title"].connect (update_app_info);
            window.notify["app_id"].connect (update_app_info);
            window.state.connect (update_window_state);
            window.output_enter.connect (update_outputs);
            window.output_leave.connect (update_outputs);
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

        private void update_window_state () {
            active = window.activated;
        }

        private void update_outputs () {
            var registry = new Registry ();
            var native = panel.get_native ();
            var surface = native.get_surface ();

            foreach (var output in window.current_outputs) {
                var wl_output = ((Gdk.Wayland.Monitor) native.get_display ().get_monitor_at_surface (surface)).get_wl_output ();
                if (registry.outputs_keeper.get_output (wl_output) == output) {
                    visible = true;
                    return;
                }
            }

            visible = false;
        }

        private void on_output_leave (Output output) {

        }
    }
}
