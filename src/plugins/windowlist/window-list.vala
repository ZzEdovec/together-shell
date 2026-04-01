using TogetherShell;
using TogetherWayland;

namespace WindowList {
    public class WindowList : Gtk.Box {
        private Registry registry = new Registry ();
        private ToplevelManager toplevel_manager;
        private AstalApps.Apps apps = new AstalApps.Apps ();
        private ulong? window_added_id;

        public WindowList () {
            hexpand = true;
            start ();
        }

        private void start () {
            foreach (var window in registry.toplevel_manager.windows)
                window_added (window);

            window_added_id = registry.toplevel_manager.window_added.connect (window_added);
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
