using TogetherShell;
using TogetherWayland;

namespace WindowListPlugin {
    public class WindowList : Gtk.Box {
        private Registry registry = new Registry ();
        private ToplevelManager? toplevel_manager;
        private AppInfoManager appinfo_manager = new AppInfoManager ();
        private ulong? window_added_id;

        public WindowList () {
            hexpand = true;
            start ();
        }

        private void start () {
            toplevel_manager = registry.toplevel_manager;
            foreach (var window in toplevel_manager.windows)
                window_added (window);

            window_added_id = toplevel_manager.window_added.connect (window_added);
        }

        ~WindowList () { // Maybe not work due to bad memory managment, check needed (хранит ссылку на класс)
            if (window_added_id != null)
                toplevel_manager.disconnect (window_added_id);
        }

        private void window_added (ToplevelWindow window) {
            var revealer = new Gtk.Revealer ();
            var button = new Gtk.ToggleButton ();
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            var icon = new Gtk.Image ();
            var label = new Gtk.Label (window.title ?? _("Unknown app"));

            revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
            revealer.child = button;

            label.max_width_chars = 50;
            label.ellipsize = Pango.EllipsizeMode.END;

            box.margin_start = box.margin_end = 8;
            box.append (icon);
            box.append (label);

            button.child = box;
            button.css_classes = {"flat", "panel-task-button"};

            var button_handle_id = button.toggled.connect (() => {
                if (button.get_data<bool> ("updating_state"))
                    return;

                if (button.active) {
                    if (window.minimized)
                        window.toggle_minimize ();
                    else if (!window.activated)
                        window.activate ();
                }
                else if (!window.minimized)
                    window.toggle_minimize ();
            });
            button.set_data<ulong> ("handle", button_handle_id);

            var window_handles = new Gee.ArrayList<ulong> ();
            var window_state_handle_id = window.state.connect (() =>
            {
                button.set_data<bool> ("updating_state", true);

                if (window.minimized || !window.activated)
                    button.active = false;
                else
                    button.active = true;

                button.set_data ("updating_state", false);
            });
            var window_appid_handle_id = window.notify["app_id"].connect (() => {
                var app = appinfo_manager.apps_list[window.app_id] ?? appinfo_manager.apps_list[window.app_id.down ()];
                Icon? gicon = null;

                if (app != null) {
                    gicon = app.get_icon ();
                    label.label = app.get_display_name ();
                }
                else
                    label.label = window.title ?? _("Unknown app");

                if (gicon != null)
                    icon.set_from_gicon (gicon);
                else
                    icon.icon_name = "application-x-executable-symbolic";

            });
            var window_closed_handle_id = window.closed.connect (() => {
                button.disconnect (button.get_data<ulong> ("handle"));

                revealer.reveal_child = false;
                Timeout.add_once (revealer.transition_duration, () => {
                    revealer.unparent ();
                    foreach (var handle in window_handles) { window.disconnect (handle); }
                });
            });
            window_handles.add_all_array ({ window_state_handle_id, window_appid_handle_id, window_closed_handle_id });
            Signal.emit_by_name (window, "notify::app_id");
            append (revealer);
            revealer.reveal_child = true;
        }
    }

    public class Plugin : Peas.ExtensionBase, TogetherShell.Plugin {
        private PanelContext ctx;
        private WindowList list = new WindowList ();

        public void activate (PanelContext ctx) {
            this.ctx = ctx;
        }

        public Gtk.Widget get_panel_widget () {
            return list;
        }

        public Adw.Bin? get_showable_widget () { return null; }
    }
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
    ((Peas.ObjectModule) module).register_extension_type (typeof (TogetherShell.Plugin), typeof (WindowListPlugin.Plugin));
}
