/**
 * TOGETHER SHELL CORE RUNTIME API
 *
 * This file defines objects managed exclusively by the Together Shell Core.
 *
 * FOR PLUGIN DEVELOPERS:
 * ACCESS: These objects are instantiated and managed by the Shell.
 * You receive them via provider methods.
 * LIFECYCLE: Do NOT attempt to create (new) instances of these classes.
 * Doing so will result in unlinked objects, memory corruption and Shell crash.
 */

public class TogetherShell.Application : Adw.Application {
    public Gee.ArrayList<Panel> panels = new Gee.ArrayList<Panel> ();
    public PluginLoader plugin_loader = new PluginLoader ();
    private BackgroundManager background_manager;

    public Application () {
        Object (
            application_id: "com.github.ZzEdovec.TogetherShell",
            flags: ApplicationFlags.DEFAULT_FLAGS,
            resource_base_path: "/com/github/ZzEdovec/togethershell" // Adw.Application automatically loads style.css
        );
    }

    public override void activate () {
        base.activate ();

        // TODO: TOGETHER SHELL INITIAL SETUP APPLICATION

        background_manager = new BackgroundManager ();
        load_panels ();
    }

    private void load_panels () {
        var config_parser = new Json.Parser ();
        var settings = new Settings (application_id);
        try {config_parser.load_from_data (settings.get_string ("panels"));}
        catch (Error e) {
            critical ("Panels settings cannot be loaded!" + e.message + ". Make sure that gschema for Together Shell is installed correctly");
            quit ();
        }

        load_actions ();

        var root = config_parser.get_root ();
        var root_obj = root.get_object ();

        var panels = root_obj.get_array_member ("panels");
        panels.foreach_element ((array, index, member_node) => {
            Panel panel = new Panel(this, member_node.get_object ());
            this.panels.add (panel);
        });
    }

    private void load_actions () {
        var shutdown = new SimpleAction ("shutdown", null);
        shutdown.activate.connect (() => {
            var proc = new Subprocess.newv ({"poweroff"}, SubprocessFlags.NONE);
        });

        add_action (shutdown);
    }
}
