using TogetherWayland;
using TogetherCore;
using TogetherCore.Managers;

namespace WindowList {
    public sealed class WindowButton : Gtk.ToggleButton {
        public uint icon_size { get; set; default = 0; }
        public bool show_label { get; set; default = false; } // ignored when window not attached
        public bool has_window { get; private set; default = false; }
        private bool toggle_block = false;
        private ToplevelWindow? window;
        private DesktopAppInfo? app;
        private Binding? label_bind;
        private AppInfoManager appinfo_manager = new AppInfoManager ();
        private Registry registry = new Registry ();
        private Gtk.Label title = new Gtk.Label (_("Unknown app"));
        private Gtk.Image icon = new Gtk.Image.from_icon_name ("application-x-executable-symbolic");

        construct {
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            box.margin_start = box.margin_end = 8;
            box.halign = box.valign = Gtk.Align.CENTER;
            box.append (icon);
            box.append (title);

            child = box;
            css_classes = { "panel-task-button" };

            title.max_width_chars = 40;
            title.ellipsize = Pango.EllipsizeMode.MIDDLE;
            title.notify["visible"].connect (switch_flat);

            bind_property ("icon_size", icon, "pixel_size", BindingFlags.DEFAULT); // set only if changed
        }

        public WindowButton (ToplevelWindow window) {
            attach_window (window);
        }

        public WindowButton.for_pinned (DesktopAppInfo app) {
            this.app = app;
            title.visible = false;

            update_app_info ();
        }

        public void attach_window (ToplevelWindow window) {
            if (window == this.window)
                return;

            this.window = window;
            this.has_window = true;

            if (label_bind == null)
                label_bind = bind_property ("show_label", title, "visible", BindingFlags.SYNC_CREATE);

            add_drop_controller ();
            switch_flat ();
            update_app_info ();
            check_active ();

            window.notify["title"].connect (update_app_info);
            window.notify["app_id"].connect (update_app_info);
            window.state.connect (check_active);
            window.output_enter.connect (check_output);
            window.output_leave.connect (check_output);

            Signal.emit_by_name (this, "notify::has_window");
        }

        public void detach_window () {
            if (label_bind != null) {
                label_bind.unbind ();
                label_bind = null;
            }

            toggle_block = true;
            title.visible = false;
            has_window = false;
            window = null;
            active = false;
            toggle_block = false;

            Signal.emit_by_name (this, "notify::has_window");
            switch_flat ();
        }

        public void detach_app () {
            app = null;
        }

        private void add_drop_controller () {
            var drop_controller = new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY |
                                                                             Gdk.DragAction.LINK |
                                                                             Gdk.DragAction.NONE |
                                                                             Gdk.DragAction.MOVE |
                                                                             Gdk.DragAction.ASK);
            drop_controller.enter.connect (() => {
                if (!this.window.activated)
                    this.window.activate ();
                return 0;
            });

            add_controller (drop_controller);
        }

        private void switch_flat () {
            if (title.visible || window == null)
                css_classes = { "flat", "panel-task-button" };
            else
                css_classes = { "panel-task-button" };
        }

        public override void map () {
            base.map ();

            if (window != null) {
                foreach (var output in window.current_outputs)
                    check_output (output);
            }
        }

        private void check_active () {
            if (toggle_block)
                return;

            toggle_block = true;
            active = window.activated;
            toggle_block = false;
        }

        public override void toggled () {
            if (toggle_block)
                return;

            toggle_block = true;

            if (active && window == null && app != null) {
                try {
                    app.launch (null, null);

                    wait_for_window ();
                } catch {
                    active = false;
                }
            }
            else if (window != null) {
                if (active && !window.activated)
                    window.activate ();
                else if (window.activated)
                    window.minimize ();
            }

            toggle_block = false;
        }

        private void wait_for_window () {
            sensitive = false;
            ulong window_id = 0;

            uint timeout = Timeout.add_seconds_once (15, () => {
                sensitive = true;
                toggle_block = true;
                active = false;
                toggle_block = false;
            });
            window_id = notify["has_window"].connect (() => {
                disconnect (window_id);
                Source.remove (timeout);

                sensitive = true;
            });
        }

        private void update_app_info () {
            DesktopAppInfo? app = this.app;
            if (window != null) {
                if (window.app_id == null && app == null)
                    return;

                app = appinfo_manager.get_by_id (window.app_id) ?? appinfo_manager.get_by_wm_class (window.app_id);

                if (app == null)
                    return;

                title.label = app.get_display_name () ?? window.title ?? _("Unknown app"); // label is hidden when pinned but window not attached
            }

            if (app == null)
                return;

            var gicon = app.get_icon ();
            if (gicon != null)
                icon.set_from_gicon (gicon);
            else
                icon.set_from_icon_name ("application-x-executable-symbolic");
        }

        private void check_output (Output output) {
            visible = output == registry.outputs_keeper.get_output_by_widget (this);
        }

        ~WindowButton () {print ("goodbye\n");}
    }
}

