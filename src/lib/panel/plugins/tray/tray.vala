using TogetherShell;

public class TrayPlugin.Plugin : Object, TogetherShell.Plugin {
    private Gtk.MenuButton button = new Gtk.MenuButton ();
    private Tray tray = new Tray ();

    public Plugin (Panel panel) {
        tray.bind_property ("is_empty", button, "visible", BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN);
    }

    public string get_name () {
        return "Tray";
    }

    public string get_desc () {
        return "Trayyyy";
    }

    public Gtk.Widget? get_panel_widget() {
         return button;
    }

    public Gtk.Popover? get_showable_widget () {
        return tray;
    }

    public bool unregister () {
        return true;
    }
}

[CCode (cname = "register_plugin")]
public TogetherShell.Plugin register_plugin (TogetherShell.Panel? panel) {
    return new TrayPlugin.Plugin (panel);
}
