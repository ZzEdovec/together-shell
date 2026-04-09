using TogetherCore;
using TogetherCore.Settings.Shell;
using TogetherWayland;

namespace WindowList {
    public class WindowList : Gtk.Box {
        private Registry registry = new Registry ();
        private Interfaces.Shell.PanelContext panel;
        internal Gtk.RevealerTransitionType transition_type { get; set; }
        private Gee.HashMap<ToplevelWindow, Gtk.Revealer> revealers = new Gee.HashMap<ToplevelWindow, Gtk.Revealer> ();

        public WindowList (Interfaces.Shell.PanelContext panel) {
            this.panel = panel;

            if (registry.toplevel_manager == null) {
                critical ("Cannot get ToplevelManager\n");
                return;
            }

            update_orientation (panel.position);
            foreach (var window in registry.toplevel_manager.windows)
                handle_window (window);

            panel.position_changed.connect (update_orientation);
            registry.toplevel_manager.window_added.connect (handle_window);
        }

        private void handle_window (ToplevelWindow window) {
            add_button (window);
            window.closed.connect (remove_button);
        }

        private void add_button (ToplevelWindow window) {
            var revealer = new Gtk.Revealer ();
            var button = new WindowButton (window);

            bind_property ("transition_type", revealer, "transition_type", BindingFlags.SYNC_CREATE);
            revealer.child = button;

            revealers[window] = revealer;
            append (revealer);

            revealer.reveal_child = true;
            Timeout.add_once (revealer.transition_duration, () => {window.set_rectangle (panel, revealer);});
        }

        private void remove_button (ToplevelWindow window) {
            Gtk.Revealer revealer;
            if (!revealers.unset (window, out revealer))
                return;

            revealer.notify["child_revealed"].connect (() => { remove (revealer); });
            revealer.reveal_child = false;
        }

        private void update_orientation (PanelPosition pos) { // TODO disable button labels when vertical
            Gtk.RevealerTransitionType transition_type;
            switch (pos) {
                case (PanelPosition.TOP):
                    transition_type = Gtk.RevealerTransitionType.SWING_DOWN;
                    orientation = Gtk.Orientation.HORIZONTAL;
                break;
                case (PanelPosition.BOTTOM):
                    transition_type = Gtk.RevealerTransitionType.SWING_UP;
                    orientation = Gtk.Orientation.HORIZONTAL;
                break;
                case (PanelPosition.LEFT):
                    transition_type = Gtk.RevealerTransitionType.SWING_RIGHT;
                    orientation = Gtk.Orientation.VERTICAL;
                break;
                case (PanelPosition.RIGHT):
                    transition_type = Gtk.RevealerTransitionType.SWING_LEFT;
                    orientation = Gtk.Orientation.VERTICAL;
                break;
            }
        }
    }

    public class Plugin : Peas.ExtensionBase, Interfaces.Shell.Plugin {
        private Interfaces.Shell.PanelContext ctx;
        private WindowList list;

        public void activate (Interfaces.Shell.PanelContext ctx) {
            this.ctx = ctx;
            this.list = new WindowList (ctx);
        }

        public Gtk.Widget get_panel_widget () {
            return list;
        }

        public Adw.Bin? get_showable_widget () { return null; }
    }
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
    ((Peas.ObjectModule) module).register_extension_type (typeof (Interfaces.Shell.Plugin), typeof (WindowList.Plugin));
}
