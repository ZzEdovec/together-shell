using TogetherWayland;
using TogetherCore;
using TogetherCore.Managers;

namespace WindowList {
    public class WindowButton : Gtk.ToggleButton {
        private ToplevelWindow window;
        private TogetherCore.Settings.Shell.Settings settings = new TogetherCore.Settings.Shell.Settings ();
        private AppInfoManager appinfo_manager = new AppInfoManager ();
        private Registry registry = new Registry ();
        private Gtk.Revealer revealer = new Gtk.Revealer ();
        private Gtk.Label title = new Gtk.Label (_("Unknown app"));
        private Gtk.Image icon = new Gtk.Image ();

        public WindowButton (ToplevelWindow window) {
            this.window = window;
            this.css_classes = {"flat", "panel-task-button"};

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            box.margin_start = box.margin_end = 8;
            box.append (title);
            box.append (icon);

            title.max_width_chars = 40;
            title.ellipsize = Pango.EllipsizeMode.MIDDLE;
            settings.bind_property ("show_window_labels", title, "visible", BindingFlags.SYNC_CREATE);

            revealer.child = box;
            child = revealer;

            window.notify["title"].connect (update_app_info);
            window.notify["app_id"].connect (update_app_info);
            window.state.connect (() => { active = window.activated; });
            window.output_enter.connect (check_output);
            window.output_leave.connect (check_output);
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

        private void check_output (Output output) {
            visible = output == registry.outputs_keeper.get_output_by_widget (this);
        }
    }
}
