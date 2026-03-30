using TogetherShell;

public class ShowDesktopPlugin.Button : Gtk.Button {
    private Wayfire.WayfireIPC ipc = new Wayfire.WayfireIPC ();

    public Button (Panel panel) {
        css_classes = { "panel-button", "flat" };
        halign = Gtk.Align.END;
    }

    public override void clicked () {
        ipc.call.begin ("wm-actions/toggle_showdesktop");
    }
}

public class ShowDesktopPlugin.Plugin : Object, TogetherShell.Plugin {
    private Panel panel;

    public Plugin (Panel panel) {
        this.panel = panel;
    }

    public string get_name () {
        return "Show Desktop";
    }

    public string get_desc () {
        return "Hide all windows";
    }

    public Gtk.Widget? get_panel_widget() {
        Button button = new Button (panel);

        return button;
    }

    public Gtk.Popover? get_showable_widget () {return null;}

    public bool unregister () {
        return true;
    }
}

[CCode (cname = "register_plugin")]
public TogetherShell.Plugin register_plugin(TogetherShell.Panel? panel) {
    return new ShowDesktopPlugin.Plugin (panel);
}
