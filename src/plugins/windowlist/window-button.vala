using TogetherWayland;
using TogetherCore;
using TogetherCore.Managers;

namespace WindowList {
    public sealed class WindowButton : Gtk.ToggleButton, Gtk.Orientable {
        private Gtk.Orientation _orientation = Gtk.Orientation.HORIZONTAL;
        private DesktopAppInfo? _application = null;
        private uint _dot_size = 4;
        private uint _dot_gap = 2;
        private int active_window = -1;
        private bool _show_label = false;
        internal bool toggle_block = false;
        private WindowIndicator indicator = new WindowIndicator ();
        private Gtk.Revealer title_revealer = new Gtk.Revealer ();
        private Gtk.DropTarget drop_controller =  new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY |
                                                                                             Gdk.DragAction.LINK |
                                                                                             Gdk.DragAction.NONE |
                                                                                             Gdk.DragAction.MOVE |
                                                                                             Gdk.DragAction.ASK);
        private Gee.ArrayList<ToplevelWindow> windows = new Gee.ArrayList<ToplevelWindow> ();
        private Gee.HashMap<ToplevelWindow, Gee.ArrayList<ulong>> windows_signals = new Gee.HashMap<ToplevelWindow, Gee.ArrayList<ulong>> ();
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
        public Gtk.Orientation orientation {
            get { return _orientation; }
            set {
                _orientation = value;
                switch_title_revealer_anim ();
                switch_indicator_orientation ();
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
        public uint dot_size {
            get { return _dot_size; }
            set { _dot_size = indicator.dot_size = value; }
        }
        public uint dot_gap {
            get { return _dot_gap; }
            set { _dot_gap = indicator.dot_gap = value; }
        }
        public int windows_count {
            get { return windows.size; }
        }

        public signal void content_size_updated ();
        private signal void window_added ();

        construct {
            title_revealer.child = title;
            title_revealer.notify["visible"].connect (switch_flat);

            indicator.visible = false;
            indicator.opacity = 0.8;

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            box.margin_start = box.margin_end = 8;
            box.halign = box.valign = Gtk.Align.CENTER;
            box.append (icon);
            box.append (title_revealer);

            var overlay = new Gtk.Overlay ();
            overlay.child = box;
            overlay.add_overlay (indicator);
            overlay.set_measure_overlay (indicator, true);

            child = overlay;
            css_classes = { "panel-task-button" };

            title.max_width_chars = 40;
            title.ellipsize = Pango.EllipsizeMode.MIDDLE;

            bind_property ("icon_size", icon, "pixel_size", BindingFlags.DEFAULT); // set only if changed (DEFAULT flag)

            switch_title_revealer_anim ();
            switch_indicator_orientation ();

            /*drop_controller.enter.connect (() => {
                if (!_window.activated)
                    _window.activate ();
                return 0;
            });
            add_controller (drop_controller);*/
        }

        public WindowButton (ToplevelWindow window) {
            attach_window (window);
        }

        public WindowButton.for_pinned (DesktopAppInfo app) {
            application = app;
            title_revealer.visible = false;
        }

        public void attach_window (ToplevelWindow window) {
            windows.add (window);
            if (windows.size <= 1) {
                switch_flat ();
                update_app_info (window);
                switch_title_revealer ();
            }
            else {
                indicator.visible = true;
                indicator.count = windows.size;
            }

            check_active ();

            var signals = new Gee.ArrayList<ulong> ();
            windows_signals[window] = signals;

            signals.add (window.notify["title"].connect (handle_window_info));
            signals.add (window.notify["app_id"].connect (handle_window_info));
            signals.add (window.state.connect (check_active));
            //window_signals.add (_window.output_enter.connect (check_output));
            //window_signals.add (_window.output_leave.connect (check_output));

            window_added ();
        }

        public void detach_window (ToplevelWindow window) {
            foreach (ulong sig in windows_signals[window])
                window.disconnect (sig);

            windows_signals.unset (window);
            windows.remove (window);

            var total_windows = windows.size;
            indicator.count = total_windows;
            if (total_windows <= 1)
                indicator.visible = false;

            check_active ();
            switch_title_revealer ();
            switch_flat ();
        }

        private void handle_window_info (Object win_obj, ParamSpec pspec) {
            var window = (ToplevelWindow) win_obj;
            if (!window.activated && windows.size > 1)
                return;

            update_app_info (window);
        }

        private void switch_flat () {
            if (title_revealer.visible || windows.is_empty)
                css_classes = { "flat", "panel-task-button" };
            else
                css_classes = { "panel-task-button" };
        }

        private void switch_title_revealer () {
            bool should_show = !windows.is_empty && _show_label;
            if (should_show == title_revealer.reveal_child)
                return;

            ulong reveal_id = 0;

            if (should_show) {
                title_revealer.visible = true;
                reveal_id = title_revealer.notify["child-revealed"].connect (() => {
                    Idle.add_once (() => { content_size_updated (); });
                    title_revealer.disconnect (reveal_id);
                });
            }
            else
                reveal_id = title_revealer.notify["child-revealed"].connect (() => {
                    title_revealer.visible = false;
                    Idle.add_once (() => { content_size_updated (); });

                    title_revealer.disconnect (reveal_id);
                });

            title_revealer.reveal_child = should_show;
        }

        private void switch_title_revealer_anim () {
            title_revealer.transition_type = _orientation == Gtk.Orientation.VERTICAL ? Gtk.RevealerTransitionType.SLIDE_DOWN
                                                                                      : Gtk.RevealerTransitionType.SLIDE_RIGHT;
        }

        private void switch_indicator_orientation () {
            bool is_horizontal = _orientation == Gtk.Orientation.HORIZONTAL;

            indicator.halign = is_horizontal ? Gtk.Align.FILL : Gtk.Align.END;
            indicator.valign = is_horizontal ? Gtk.Align.END : Gtk.Align.FILL;
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
            var prev_active = active_window;
            bool should_active = false;

            if (!windows.is_empty) {
                for (int i = 0; i < windows.size; i++) {
                    var window = windows[i];
                    if (window.activated) {
                        should_active = true;
                        active_window = i;

                        break;
                    }
                }
            }

            if (!should_active)
                active_window = -1;
            if (active_window != prev_active)
                update_app_info ();

            active = should_active;
            toggle_block = false;
        }

        public override void toggled () {
            if (toggle_block)
                return;

            toggle_block = true;

            if (active_window >= 0 && windows.size > 1)
                active = true;

            if (active && windows.is_empty && _application != null) {
                try {
                    _application.launch (null, null);
                    wait_for_window ();
                } catch {
                    active = false;
                }
            }
            else if (!windows.is_empty) {
                if (active) {
                    var window = active_window >= 0 ? windows[(active_window + 1) % windows.size] : windows[0];
                    window.activate ();
                }
                else {
                    windows[active_window].minimize ();
                    active_window = -1;
                }
            }

            toggle_block = false;
        }

        private void wait_for_window () {
            sensitive = false;
            ulong window_id = 0;

            uint timeout = Timeout.add_seconds_once (15, () => {
                toggle_block = true;
                sensitive = true;
                active = false;
                toggle_block = false;

                windows.disconnect (window_id);
            });
            window_id = window_added.connect (() => {
                if (windows.is_empty)
                    return;

                disconnect (window_id);
                Source.remove (timeout);

                sensitive = true;
            });
        }

        private void update_app_info (ToplevelWindow? for_window = null) {
            ToplevelWindow? window = for_window;
            DesktopAppInfo? app = _application;

            if (window == null && active_window >= 0)
                window = windows[active_window];

            if (window != null && window.app_id != null)
                app = appinfo_manager.get_by_id (window.app_id) ?? appinfo_manager.get_by_wm_class (window.app_id);

            if (app == null)
                return;

            var prev_label = title.label;
            title.label = app.get_display_name () ?? window.title ?? _("Unknown app");
            tooltip_text = title.label;

            if (title.visible && prev_label != title.label)
                Idle.add_once (() => { content_size_updated (); });

            var gicon = app.get_icon ();
            if (gicon != null)
                icon.set_from_gicon (gicon);
            else
                icon.set_from_icon_name ("application-x-executable-symbolic");
        }

        ~WindowButton () {print ("goodbye\n");}
    }
}


