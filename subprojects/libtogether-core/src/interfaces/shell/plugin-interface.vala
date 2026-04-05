using TogetherCore;

namespace TogetherCore.Interfaces.Shell {
    public interface PanelContext : Gtk.Widget {
        public signal void position_changed (Settings.Shell.PanelPosition pos);
        public abstract Settings.Shell.PanelPosition get_panel_position ();
    }

    public interface Plugin : Object {
        public abstract void activate (PanelContext ctx);
        public abstract Gtk.Widget get_panel_widget ();
        public abstract Adw.Bin? get_showable_widget ();
    }
}
