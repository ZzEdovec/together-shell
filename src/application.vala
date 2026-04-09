public class TogetherShell.Application : Adw.Application {
    private PopupsManager popups_manager;
    //private BackgroundManager background_manager;
    private TogetherCore.Settings.Shell.Settings settings;
    private Gee.HashMap<TogetherCore.Settings.Shell.Panel, Panel> panels = new Gee.HashMap<TogetherCore.Settings.Shell.Panel, Panel> ();

    public Application () {
        Object (
            application_id: "com.github.ZzEdovec.TogetherShell",
            flags: ApplicationFlags.DEFAULT_FLAGS,
            resource_base_path: "/com/github/ZzEdovec/togethershell" // Adw.Application automatically loads style.css
        );
    }

    public override void activate () {
        base.activate ();

        popups_manager = new PopupsManager ();
        //background_manager = new BackgroundManager ();
        settings = new TogetherCore.Settings.Shell.Settings ();

        load_panels ();

        settings.panel_added.connect (add_panel);
        settings.panel_removed.connect (remove_panel);
    }

    private void add_panel (TogetherCore.Settings.Shell.Panel panel_settings) {
        var panel = new Panel (panel_settings);
        panels[panel_settings] = panel;

        panel.present ();
    }

    private void remove_panel (TogetherCore.Settings.Shell.Panel panel_settings) {
        Panel panel;
        if (!panels.unset (panel_settings, out panel))
            return;

        panel.destroy ();
    }

    private void load_panels () {
        var panels = settings.panels;
        if (panels.length == 0) {
            var panel = settings.create_panel ();
            panels += panel;
        }

        foreach (var panel in panels) {
            add_panel (panel);
        }
    }
}

int main (string[] args) {
    Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (Config.GETTEXT_PACKAGE);

    var app = new TogetherShell.Application ();
    return app.run (args);
}
