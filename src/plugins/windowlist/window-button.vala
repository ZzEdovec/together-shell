using TogetherWayland;
using TogetherCore;
using TogetherCore.Managers;

namespace WindowList {
    public sealed class WindowButton : Gtk.ToggleButton, Gtk.Orientable {
        private Gtk.Orientation _orientation = Gtk.Orientation.HORIZONTAL;
        private ToplevelWindow? _window = null;
        private DesktopAppInfo? _application = null;
        private bool _show_label = false;
        private bool toggle_block = false;
        private Gtk.Revealer title_revealer = new Gtk.Revealer ();
        private Gtk.DropTarget drop_controller =  new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY |
                                                                                             Gdk.DragAction.LINK |
                                                                                             Gdk.DragAction.NONE |
                                                                                             Gdk.DragAction.MOVE |
                                                                                             Gdk.DragAction.ASK);
        private Gee.ArrayList<ulong> window_signals = new Gee.ArrayList<ulong> ();
        private AppInfoManager appinfo_manager = new AppInfoManager ();
        private Gtk.Label title = new Gtk.Label (_("Unknown app"));
        private Gtk.Image icon = new Gtk.Image.from_icon_name ("application-x-executable-symbolic");
        public uint icon_size { get; set; default = 0; }
        public bool show_label {
            get { return _show_label; }
            set {
                _show_label = value;
                switch_title_revealer ();
            }
        }
        public ToplevelWindow window {
            get { return _window; }
            set {
                if (_window != null || value == null)
                    detach_window ();
                if (value != null)
                    attach_window (value);
            }
        }
        public Gtk.Orientation orientation {
            get { return _orientation; }
            set {
                _orientation = value;
                switch_title_revealer_anim ();
            }
        }
        public DesktopAppInfo application {
            get { return _application; }
            set {
                _application = value;
                if (value != null)
                    update_app_info ();
            }
        }

        public signal void content_size_updated ();

        construct {
            title_revealer.child = title;
            title_revealer.notify["visible"].connect (switch_flat);

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            box.margin_start = box.margin_end = 8;
            box.halign = box.valign = Gtk.Align.CENTER;
            box.append (icon);
            box.append (title_revealer);

            child = box;
            css_classes = { "panel-task-button" };

            title.max_width_chars = 40;
            title.ellipsize = Pango.EllipsizeMode.MIDDLE;

            bind_property ("icon_size", icon, "pixel_size", BindingFlags.DEFAULT); // set only if changed (DEFAULT flag)
            drop_controller.enter.connect (() => {
                if (!_window.activated)
                    _window.activate ();
                return 0;
            });
        }

        public WindowButton (ToplevelWindow window) {
            attach_window (window);
        }

        public WindowButton.for_pinned (DesktopAppInfo app) {
            application = app;
            title_revealer.visible = false;
        }

        private void attach_window (ToplevelWindow window) {
            if (window == _window)
                return;

            _window = window;

            add_controller (drop_controller);
            switch_flat ();
            update_app_info ();
            check_active ();
            switch_title_revealer ();

            window_signals.add (_window.notify["title"].connect (update_app_info));
            window_signals.add (_window.notify["app_id"].connect (update_app_info));
            window_signals.add (_window.state.connect (check_active));
            //window_signals.add (_window.output_enter.connect (check_output));
            //window_signals.add (_window.output_leave.connect (check_output));
        }

        private void detach_window () {
            foreach (ulong sig in window_signals)
                _window.disconnect (sig);
            window_signals.clear ();

            toggle_block = true;
            _window = null;
            active = false;
            toggle_block = false;

            remove_controller (drop_controller);
            switch_title_revealer ();
            switch_flat ();
        }

        private void switch_flat () {
            if (title_revealer.visible || _window == null)
                css_classes = { "flat", "panel-task-button" };
            else
                css_classes = { "panel-task-button" };
        }

        private void switch_title_revealer () {
            bool should_show = _window != null && _show_label;
            if (should_show == title_revealer.reveal_child)
                return;

            if (should_show && _show_label && _show_label) {
                title_revealer.visible = true;
                Timeout.add_once (title_revealer.transition_duration, () => { content_size_updated (); });
            }
            else
                Timeout.add_once (title_revealer.transition_duration, () => {
                    title_revealer.visible = false;
                    Idle.add_once (() => { content_size_updated (); });
                });

            title_revealer.reveal_child = should_show;
        }

        private void switch_title_revealer_anim () {
            title_revealer.transition_type = orientation == Gtk.Orientation.VERTICAL ? Gtk.RevealerTransitionType.SLIDE_DOWN
                                                                                     : Gtk.RevealerTransitionType.SLIDE_RIGHT;
        }

        /*public override void map () {
            base.map ();

            if (_window != null) {
                foreach (var output in window.current_outputs)
                    check_output (output);
            }
        }*/

        private void check_active () {
            if (toggle_block)
                return;

            toggle_block = true;
            active = _window.activated;
            toggle_block = false;
        }

        public override void toggled () {
            if (toggle_block)
                return;

            toggle_block = true;

            if (active && _window == null && _application != null) {
                try {
                    _application.launch (null, null);
                    wait_for_window ();
                } catch {
                    active = false;
                }
            }
            else if (_window != null) {
                if (active && !_window.activated)
                    _window.activate ();
                else if (_window.activated)
                    _window.minimize ();
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
            window_id = notify["window"].connect (() => {
                if (_window == null)
                    return;

                disconnect (window_id);
                Source.remove (timeout);

                sensitive = true;
            });
        }

        private void update_app_info () {
            DesktopAppInfo? app = _application;
            if (window != null) {
                if (window.app_id == null && app == null)
                    return;

                app = appinfo_manager.get_by_id (window.app_id) ?? appinfo_manager.get_by_wm_class (window.app_id);

                if (app == null)
                    return;

                var prev_label = title.label;
                title.label = app.get_display_name () ?? _window.title ?? _("Unknown app");

                if (prev_label != title.label)
                    Idle.add_once (() => { content_size_updated (); });
            }

            if (app == null)
                return;

            var gicon = app.get_icon ();
            if (gicon != null)
                icon.set_from_gicon (gicon);
            else
                icon.set_from_icon_name ("application-x-executable-symbolic");
        }

        ~WindowButton () {print ("goodbye\n");}
    }
}


