using TogetherCore;
using TogetherCore.Settings.Shell;
using TogetherCore.Managers;
using TogetherWayland;
using TogetherWidgets;

namespace WindowList {
    public sealed class WindowList : Gtk.Box {
        internal Gtk.RevealerTransitionType transition_type { get; set; }
        private DraggableArea drag_area;
        private bool rectangles_dirty = false;
        private Registry registry = new Registry ();
        private TogetherCore.Settings.Shell.Settings settings = new TogetherCore.Settings.Shell.Settings ();
        private AppInfoManager appinfo_manager = new AppInfoManager ();
        private Interfaces.Shell.PanelContext panel;
        private Gee.HashMap<DesktopAppInfo, Gtk.Revealer> pinned_revealers = new Gee.HashMap<DesktopAppInfo, Gtk.Revealer> ();
        private Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        private Gee.HashMap<ToplevelWindow, Gtk.Revealer> revealers = new Gee.HashMap<ToplevelWindow, Gtk.Revealer> ();
        private Gtk.Revealer? painted;

        public WindowList (Interfaces.Shell.PanelContext panel, DraggableArea drag_area) {
            this.panel = panel;
            this.drag_area = drag_area;

            separator.visible = false;
            separator.margin_end = separator.margin_top = separator.margin_start = separator.margin_bottom = 8;
            append (separator);

            if (registry.toplevel_manager == null) {
                critical ("Cannot get ToplevelManager\n");
                return;
            }

            bind_property ("orientation", separator, "orientation", BindingFlags.SYNC_CREATE);
            bind_property ("orientation", drag_area, "orientation", BindingFlags.SYNC_CREATE);

            drag_area.below_finded.connect (repaint_revealer);
            drag_area.below_lost.connect (unpaint_revealer);
            drag_area.drag_ended.connect ((dragged, below) => { repose_revealer (dragged, below); });

            foreach (var app in settings.panel_pinned.apps)
                add_pinned_revealer (app);
            foreach (var window in registry.toplevel_manager.windows)
                handle_window (window);

            update_orientation (panel.position);

            panel.position_changed.connect (update_orientation);
            registry.toplevel_manager.window_added.connect (handle_window);
            settings.panel_pinned.app_pinned.connect (add_pinned_revealer);
            settings.panel_pinned.app_unpinned.connect (remove_pinned_revealer);
        }

        private void handle_window (ToplevelWindow window) {
            if (window.app_id == null && window.title == null) // gpu-screen-recorder-ui workaround
                return;

            bool pinned_found = false;
            if (window.app_id != null) {
                DesktopAppInfo? app = appinfo_manager.get_by_id (window.app_id) ?? appinfo_manager.get_by_wm_class (window.app_id);
                if (app != null && pinned_revealers.has_key (app) && window.parent == null) { // PARENT CHECK IS TEMPORARY
                    pinned_found = true;
                    var revealer = pinned_revealers[app];
                    var button = ((WindowButton) revealer.child);

                    if (button.window == null) { // parent windows are not always correctly sent by the compositor, TEMPORARY
                        button.window = window;
                        revealers[window] = revealer;
                    }
                }
            }

            if (!pinned_found)
                add_window_revealer (window);

            window.closed.connect (remove_window_revealer);
        }

        private Gtk.Revealer create_revealer (WindowButton button) {
            var revealer = new Gtk.Revealer ();
            weak Interfaces.Shell.PanelContext panel_weak = panel;

            panel.settings.bind_property ("size", button, "icon_size", BindingFlags.SYNC_CREATE, (bind, from, ref to) => {
                if ((uint) from >= 60)
                    to = (uint) ((uint) from / 2);
                else
                    to = (uint) ((uint) from / 2.7);
                return true;
            });
            settings.bind_property ("show_window_labels", button, "show_label", BindingFlags.SYNC_CREATE, (bind, from, ref to) => {
                if (panel_weak.position == PanelPosition.LEFT || panel_weak.position == PanelPosition.RIGHT)
                    to = false;
                else
                    to = from;

                return true;
            });

            panel.settings.bind_property ("size", revealer, "width_request", BindingFlags.SYNC_CREATE);
            panel.settings.bind_property ("size", revealer, "height_request", BindingFlags.SYNC_CREATE); // maybe bug?
            bind_property ("transition_type", revealer, "transition_type", BindingFlags.SYNC_CREATE);
            revealer.child = button;

            return revealer;
        }

        private void add_window_revealer (ToplevelWindow window) {
            var button = new WindowButton (window);
            var revealer = create_revealer (button);

            revealers[window] = revealer;
            append (revealer);
            try { drag_area.bind_widget (revealer); } catch {}

            revealer.reveal_child = true;
            Timeout.add_once (revealer.transition_duration, () => { window.set_rectangle (panel, revealer); });

            update_separator_state ();
            bind_property ("orientation", button, "orientation", BindingFlags.SYNC_CREATE);
            button.content_size_updated.connect (update_rectangles);
        }

        private void add_pinned_revealer (DesktopAppInfo app) {
            var button = new WindowButton.for_pinned (app);
            var revealer = create_revealer (button);

            pinned_revealers[app] = revealer;
            revealer.insert_before (this, separator);

            revealer.reveal_child = true;

            update_separator_state ();
            bind_property ("orientation", button, "orientation", BindingFlags.SYNC_CREATE);
            button.content_size_updated.connect (update_rectangles);
        }

        private void remove_revealer (Gtk.Revealer revealer) {
            try { drag_area.unbind_widget (revealer); } catch {}
            revealer.reveal_child = false;
            Timeout.add_once (revealer.transition_duration, () => {
                rectangles_dirty = true;
                remove (revealer);
            });
        }

        private bool update_separator_state () {
            bool should_show = !revealers.is_empty && !pinned_revealers.is_empty;
            if (should_show != separator.visible) {
                separator.visible = should_show;
                Idle.add_once (update_rectangles);

                return true;
            }

            return false;
        }

        private void update_revealer_output (Gtk.Revealer revealer, bool pinned, Output output) {
            // TODO
        }

        private void remove_window_revealer (ToplevelWindow window) {
            Gtk.Revealer revealer;
            if (!revealers.unset (window, out revealer))
                return;

            update_separator_state ();

            if (pinned_revealers.values.contains (revealer)) {
                if (window.parent == null) { // TEMPORARY
                    var button = (WindowButton) revealer.child;
                    button.window = null;
                }
                return;
            }

            remove_revealer (revealer);
        }

        private void remove_pinned_revealer (DesktopAppInfo app) {
            Gtk.Revealer revealer;
            if (!pinned_revealers.unset (app, out revealer))
                return;

            bool sep_upd = update_separator_state (); // update_rectangles in Idle.add_once, so we do not need to schedule another update

            if (revealers.values.contains (revealer)) {
                ((WindowButton) revealer.child).application = null;
                repose_revealer (revealer, null, !sep_upd);
            }
            else
                remove_revealer (revealer);
        }

        private void unpaint_revealer () {
            if (painted == null)
                return;

            var classes = new Gee.HashSet<string> ();
            classes.add_all_array (painted.css_classes);

            classes.remove ("accent");
            painted.css_classes = classes.to_array ();

            painted = null;
        }

        private void repaint_revealer (Gtk.Widget dragged, Gtk.Widget below) {
            unpaint_revealer ();

            var classes = below.css_classes;
            classes += "accent";
            below.css_classes = classes;

            painted = (Gtk.Revealer) below;
        }

        private void repose_revealer (Gtk.Widget repose, Gtk.Widget? after = null, bool update_rects = true) {
            if (after != null)
                reorder_child_after (repose, after);
            else
                reorder_child_after (repose, get_last_child ());

            unpaint_revealer ();

            if (update_rects)
                Idle.add_once (update_rectangles);
        }

        public override void snapshot (Gtk.Snapshot snapshot) {
            base.snapshot (snapshot);

            if (rectangles_dirty) {
                update_rectangles ();
                rectangles_dirty = false;
            }
        }

        private void update_rectangles () {
            print ("updating\n");
            foreach (var entry in revealers) {
                entry.key.set_rectangle (panel, entry.value);
            }
        }

        private void update_orientation (PanelPosition pos) {
            bool show_labels = settings.show_window_labels;
            switch (pos) {
                case (PanelPosition.TOP):
                    transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
                    orientation = Gtk.Orientation.HORIZONTAL;
                break;
                case (PanelPosition.BOTTOM):
                    transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
                    orientation = Gtk.Orientation.HORIZONTAL;
                break;
                case (PanelPosition.LEFT):
                    transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
                    orientation = Gtk.Orientation.VERTICAL;
                    show_labels = false;
                break;
                case (PanelPosition.RIGHT):
                    transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
                    orientation = Gtk.Orientation.VERTICAL;
                    show_labels = false;
                break;
            }

            foreach (var revealer in revealers.values) {
                var button = (WindowButton) revealer.child;
                button.show_label = show_labels;
            }
            foreach (var revealer in pinned_revealers.values) {
                var button = (WindowButton) revealer.child;
                button.show_label = show_labels;
            }
        }
    }

    public class Plugin : Peas.ExtensionBase, Interfaces.Shell.Plugin {
        private Interfaces.Shell.PanelContext ctx;
        private Gtk.Overlay overlay = new Gtk.Overlay ();

        public void activate (Interfaces.Shell.PanelContext ctx) {
            this.ctx = ctx;

            var drag_area = new DraggableArea ();
            var win_list = new WindowList (ctx, drag_area);

            overlay.child = win_list;
            overlay.add_overlay (drag_area);
            overlay.set_measure_overlay (drag_area, false);
        }

        public Gtk.Widget get_panel_widget () {
            return overlay;
        }

        public Adw.Bin? get_showable_widget () { return null; }
    }
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
    ((Peas.ObjectModule) module).register_extension_type (typeof (Interfaces.Shell.Plugin), typeof (WindowList.Plugin));
}

