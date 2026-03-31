using TogetherShell;

[GtkTemplate (ui = "/com/github/ZzEdovec/togethershell/panel/appmenu/app_menu.ui")]
public class AppMenuPlugin.Menu : Gtk.Popover {
    [GtkChild]
    private unowned Adw.ViewStack view_stack;
    [GtkChild]
    private unowned Gtk.EventControllerKey key_controller;
    [GtkChild]
    private unowned Gtk.Button settings_button;
    [GtkChild]
    private unowned Gtk.MenuButton power_button;
    [GtkChild]
    private unowned Gtk.FlowBox starred_box;
    [GtkChild]
    private unowned Gtk.FlowBox apps_box;
    [GtkChild]
    private unowned Adw.StatusPage favorites_placeholder;
    [GtkChild]
    private unowned Adw.StatusPage search_placeholder;
    [GtkChild]
    private unowned Gtk.SearchBar search_bar;
    [GtkChild]
    private unowned Gtk.SearchEntry search_entry;

    private Gee.HashMap<string,Gtk.Button> apps_buttons = new Gee.HashMap<string,Gtk.Button> ();
    private AppInfoManager apps_manager = new AppInfoManager ();
    private Registry registry = new Registry ();
    private OutputV2? wf_output;

    public Menu (Panel panel) {
        foreach (var app in apps_manager.apps_list.keys)
            add_app (app);

        var output = registry.outputs_keeper.get_output_by_widget (panel);
        if (output != null) {
            wf_output = registry.wayfire_shell_manager.get_wf_output (output);
            wf_output.notify["menu_toggled"].connect (() => {
                if (wf_output.menu_toggled)
                    popup ();
                else
                    popdown ();
            });
        }

        apps_manager.app_added.connect (add_app);
        apps_manager.app_updated.connect (update_app);
        apps_manager.app_removed.connect (remove_app);

        apps_box.set_filter_func (filter_apps);
    }

    private void run_app (AppInfo app) {
        try {
            search_bar.search_mode_enabled = false;
            app.launch (null, null);
            popdown ();
        }
        catch {} // TODO: GUI fail message (Together Shell Dialog)
    }

    private void add_app (string app_id) {
        var app = apps_manager.apps_list[app_id];

        if (app.should_show () == false)
            return;

        var button = new Gtk.Button ();
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL,10);
        var icon = new Gtk.Image ();
        var label = new Gtk.Label (app.get_display_name ());

        icon.set_from_gicon (app.get_icon ());
        icon.icon_size = Gtk.IconSize.LARGE;

        label.hexpand = true;
        label.wrap = true;
        label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        label.ellipsize = Pango.EllipsizeMode.END;
        label.justify = Gtk.Justification.CENTER;
        label.max_width_chars = 10;
        label.lines = 2;
        label.css_classes = {"body"};

        box.valign = box.halign = Gtk.Align.CENTER;
        box.append (icon);
        box.append (label);

        button.tooltip_text = label.get_text ();
        button.child = box;
        button.css_classes = {"flat"};
        button.height_request = 60;

        var handler_id = button.clicked.connect (() => { run_app (app); });

        button.set_data<ulong> ("handler_id", handler_id);
        button.set_data<string> ("app_id", app_id);
        button.set_data<Gtk.Label> ("label", label);
        button.set_data<Gtk.Image> ("icon", icon);

        apps_box.insert (button, 0);
        apps_buttons[app_id] = button;
    }

    private void update_app (string app_id) {
        if (apps_buttons.has_key (app_id) == false)
            return;

        var app = apps_manager.apps_list[app_id];
        var button = apps_buttons[app_id];
        var label = button.get_data<Gtk.Label> ("label");
        var icon = button.get_data<Gtk.Image> ("icon");
        var old_handler_id = button.get_data<ulong> ("handler_id");

        button.disconnect (old_handler_id);

        label.set_text (app.get_display_name ());
        icon.set_from_gicon (app.get_icon ());

        var handler_id = button.clicked.connect (() => { run_app (app); });

        button.set_data<ulong> ("handler_id", handler_id);
    }

    private void remove_app (string app_id) {
        var button = apps_buttons[app_id];

        button.disconnect (button.get_data<ulong> ("handler_id"));
        apps_box.remove (button);
        apps_buttons.unset (app_id);
    }

    [GtkCallback]
    private void open_dir (Gtk.Button button) {
        string dir = "/";
        switch (button.get_id ()) {
            case ("downloads_button"):
                dir = Environment.get_user_special_dir (UserDirectory.DOWNLOAD);
            break;
            case ("documents_button"):
                dir = Environment.get_user_special_dir (UserDirectory.DOCUMENTS);
            break;
            case ("music_button"):
                dir = Environment.get_user_special_dir (UserDirectory.MUSIC);
            break;
            case ("pictures_button"):
                dir = Environment.get_user_special_dir (UserDirectory.PICTURES);
            break;
            case ("videos_button"):
                dir = Environment.get_user_special_dir (UserDirectory.VIDEOS);
            break;
        }

        var file_launcher = new Gtk.FileLauncher (File.new_for_path (dir));
        file_launcher.launch.begin (null, null);

        popdown ();
    }

    [GtkCallback]
    private bool switch_to_search (Gtk.EventControllerKey controller, uint key, uint keycode, Gdk.ModifierType state) {
        unichar ch = Gdk.keyval_to_unicode (key);

        if (ch.isprint () && ch != 0) {
            search_entry.text = ch.to_string ();
            search_entry.set_position (-1);

            view_stack.visible_child = view_stack.get_child_by_name ("apps");
            search_bar.search_mode_enabled = true;
            search_entry.grab_focus ();
        }

        return true;
    }

    [GtkCallback]
    private void search () {
        if (search_entry.text == "") {
            search_cancel ();
            return;
        }

        search_placeholder.visible = true;
        apps_box.invalidate_filter ();
    }

    [GtkCallback]
    private void search_activate_first () {
        var box_child = apps_box.get_first_child ();
        var button = (Gtk.Button) box_child.get_first_child ();

        button.clicked ();

        Idle.add_once (() => { search_bar.search_mode_enabled = false; });
    }

    [GtkCallback]
    private void search_cancel () {
        apps_box.invalidate_filter ();
    }

    private bool filter_apps (Gtk.FlowBoxChild flow_child) {
        if (search_entry.text == "") {
            search_placeholder.visible = false;
            return true;
        }

        var button = (Gtk.Button) flow_child.child;
        AppInfo app = apps_manager.apps_list[button.get_data<string> ("app_id")];

        bool type_matches = false;

        foreach (var type in app.get_supported_types ()) {
            if (type.contains (search_entry.text)) {
                type_matches = true;
                break;
            }
        }

        var display_name = app.get_display_name ();
        var name = app.get_name ();
        var executable = app.get_executable ();
        var description = app.get_description () ?? "";
        var id = app.get_id () ?? "";

        if (display_name.down ().contains (search_entry.text) ||
        name.down ().contains (search_entry.text) ||
        description.down ().contains (search_entry.text) ||
        id.down ().contains (search_entry.text) ||
        executable.down ().contains (search_entry.text) ||
        type_matches) {
            search_placeholder.visible = false;
            return true;
        }
        else
            return false;
    }
}

public class AppMenuPlugin.Plugin : Object, TogetherShell.Plugin {
    private Panel panel;

    public Plugin (Panel panel) {
        this.panel = panel;
    }

    public string get_name () {
        return "App Menu";
    }

    public string get_desc () {
        return "Basic app menu";
    }

    public Gtk.Widget? get_panel_widget () {
        var button = new Gtk.MenuButton ();
        button.width_request = panel.get_height ();

        button.label = "Menu";
        button.icon_name = "archlinux-logo";

        return button;
    }

    public Gtk.Popover? get_showable_widget () {
        var menu = new AppMenuPlugin.Menu (panel);

        return menu;
    }

    public bool unregister () {return true;}
}

[CCode (cname = "register_plugin")]
public TogetherShell.Plugin register_plugin(TogetherShell.Panel? panel) {
    return new AppMenuPlugin.Plugin (panel);
}
