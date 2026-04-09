using TogetherCore;
using TogetherCore.Settings.Shell;
using TogetherWayland;

namespace WindowList {
    public class WindowList : Gtk.Box {
        private Registry registry = new Registry ();
        private Interfaces.Shell.PanelContext panel;
        private Gee.HashMap<ToplevelWindow, WindowButton> buttons = new Gee.HashMap<ToplevelWindow, WindowButton> ();

        public WindowList (Interfaces.Shell.PanelContext panel) {
            this.panel = panel;

            if (registry.toplevel_manager == null) {
                critical ("Cannot get ToplevelManager\n");
                return;
            }

            update_orientation (panel.position);
            foreach (var window in registry.toplevel_manager.windows)
                window_added (window);

            panel.position_changed.connect (update_orientation);
            registry.toplevel_manager.window_added.connect (window_added);
        }

        private void window_added (ToplevelWindow window) {
            var button = new WindowButton (window);
            buttons[window] = button;
        }

        private void update_orientation (PanelPosition pos) { // TODO disable button labels when vertical
            switch (pos) {
                case (PanelPosition.TOP):
                case (PanelPosition.BOTTOM):
                    orientation = Gtk.Orientation.HORIZONTAL;
                break;
                case (PanelPosition.LEFT):
                case (PanelPosition.RIGHT):
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
