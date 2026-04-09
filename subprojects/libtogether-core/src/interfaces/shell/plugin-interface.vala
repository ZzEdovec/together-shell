using TogetherCore;

namespace TogetherCore.Interfaces.Shell {
    public interface PanelContext : Gtk.Widget {
        public abstract TogetherCore.Settings.Shell.PanelPosition position { get; set; }
        public signal void position_changed (Settings.Shell.PanelPosition pos);
        public signal void widget_moved (Gtk.Widget widget);
    }

    /*
     * get_panel_widget () and get_showable_widget () can be called multiple times.
     * You should return the same objects to avoid problems
    */
    public interface Plugin : Object {
        public abstract void activate (PanelContext ctx);
        public abstract Gtk.Widget get_panel_widget ();
        public abstract Adw.Bin? get_showable_widget ();
    }
}
