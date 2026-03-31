using TogetherShell;

public class TimePlugin.TimeButton : Gtk.Button {
    private Gtk.Label time_label = new Gtk.Label (null);
    private Gtk.Label date_label = new Gtk.Label (null);
    private uint timeout_id;

    public TimeButton () {
        time_label.css_classes = { "caption-heading" };
        date_label.css_classes = { "caption" };
        css_classes = { "panel-button", "flat" };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        box.append (time_label);
        box.append (date_label);

        child = box;

        update_time ();

        var date_time = new DateTime.now_local ();
        Timeout.add_once ((60 - date_time.get_second ()) * 1000 - (date_time.get_microsecond () / 1000), () => {
            update_time ();

            timeout_id = Timeout.add_seconds (60, update_time);
        });
    }

    private bool update_time () {
        var date_time = new DateTime.now_local ();
        time_label.label = date_time.format ("%H:%M"); // TODO: 12 HOURS FORMAT
        date_label.label = date_time.format ("%d.%m.%y"); // TODO: MORE FORMATS

        return true;
    }
}

public class TimePlugin.Plugin : Object, TogetherShell.Plugin {
   //private Panel panel;

    public Plugin (Panel panel) {
        //this.panel = panel;
    }

    public string get_name () {
        return "Time";
    }

    public string get_desc () {
        return "Show time and date";
    }

    public Gtk.Widget? get_panel_widget() {
        TimeButton btn = new TimeButton ();

        return btn;
    }

    public Gtk.Popover? get_showable_widget () {return null;}

    public bool unregister () {
        return true;
    }
}

[CCode (cname = "register_plugin")]
public TogetherShell.Plugin register_plugin(TogetherShell.Panel? panel) {
    return new TimePlugin.Plugin (panel);
}
