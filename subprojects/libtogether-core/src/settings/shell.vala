using TogetherCore.Managers;
using TogetherCore;

namespace TogetherCore.Settings.Shell {
    public enum PanelPosition {
        TOP = 0,
        BOTTOM = 1,
        LEFT = 2,
        RIGHT = 3
    }

    public enum PanelAlignment {
        START = 0,
        CENTER = 1,
        END = 2
    }

    public enum BackgroundFit {
        FILL = 0,
        CONTAIN = 1,
        COVER = 2,
        SCALEDOWN = 3
    }

    public errordomain PanelError {
        EXISTS,
        NOTEXISTS
    }

    public class PinnedApps : Object {
        private GLib.Settings settings;
        private string key;
        private AppInfoManager appinfo_manager = new AppInfoManager ();
        private Gee.ArrayList<string> _apps = new Gee.ArrayList<string> ();
        public DesktopAppInfo[] apps {
            owned get {
                DesktopAppInfo[] app_objs = {};
                foreach (var app in _apps)
                    app_objs += appinfo_manager.get_by_id (app);

                return app_objs;
            }
        }

        public signal void app_pinned (DesktopAppInfo app);
        public signal void app_reposed (DesktopAppInfo app, int pos);
        public signal void app_unpinned (DesktopAppInfo app);

        internal PinnedApps (GLib.Settings settings, string key) {
            this.settings = settings;
            this.key = key;

            update_apps ();

            settings.changed[key].connect (update_apps);
        }

        private void update_apps () {
            var to_remove = new Gee.ArrayList<string> ();
            var new_apps = new Gee.ArrayList<string> ();
            new_apps.add_all_array (settings.get_strv (key));

            foreach (var app in _apps) {
                if (!new_apps.contains (app))
                    to_remove.add (app);
            }

            foreach (var app in to_remove) {
                _apps.remove (app);

                app_unpinned (appinfo_manager.get_by_id (app));
            }

            for (int i = 0; i < new_apps.size; i++) {
                var app = new_apps[i];
                if (!_apps.contains (app)) {
                    var app_obj = appinfo_manager.get_by_id (app);
                    if (app_obj == null)
                        continue;

                    _apps.add (app);
                    app_pinned (app_obj);
                }
                else if (_apps[i] != app)
                    app_reposed (appinfo_manager.get_by_id (app), i);
            }
        }

        public void set_pinned (string[] app_ids) {
            settings.set_strv (key, app_ids);
        }

        public void pin_app (string app_id) throws PanelError {
            if (_apps.contains (app_id))
                throw new PanelError.EXISTS (@"$app_id already pinned");

            var new_apps = _apps.to_array ();
            new_apps += app_id;
            settings.set_strv (key, new_apps);
        }

        public void repose_app (string app_id, int pos) throws PanelError {
            if (!_apps.contains (app_id))
                throw new PanelError.NOTEXISTS (@"$app_id not pinned");

            _apps.remove (app_id);
            _apps.insert (pos, app_id);

            settings.set_strv (key, _apps.to_array ());
        }

        public void unpin_app (string app_id) throws PanelError {
            if (!_apps.contains (app_id))
                throw new PanelError.NOTEXISTS (@"$app_id not pinned");

            _apps.remove (app_id);
            settings.set_strv (key, _apps.to_array ());
        }
    }

    public class Panel : Object {
        private GLib.Settings settings;
        public string uuid { get; private set; }
        public PluginsManager plugins_manager { get; private set; }
        public PanelPosition position { get; set; }
        public PanelAlignment alignment { get; set; } // TODO
        public uint size { get; set; }
        public bool dock_mode { get; set; }

        public signal void plugin_position_changed (string plugin, int pos);

        internal Panel (string id) {
            uuid = id;
            settings = new GLib.Settings.with_path ("com.github.ZzEdovec.TogetherShell.Panel", @"/com/github/ZzEdovec/TogetherShell/Panels/$id/");
            string[] plugins = settings.get_strv ("plugins");

            settings.bind ("position", this, "position", SettingsBindFlags.DEFAULT);
            settings.bind ("alignment", this, "alignment", SettingsBindFlags.DEFAULT);
            settings.bind ("size", this, "size", SettingsBindFlags.DEFAULT);
            settings.bind ("dock-mode", this, "dock_mode", SettingsBindFlags.DEFAULT);

            plugins_manager = new PluginsManager<Interfaces.Shell.Plugin> ("%s/TogetherShell".printf (Config.LIBDIR), plugins);

            settings.changed["plugins"].connect (() => { plugins_manager.set_loaded_plugins (settings.get_strv ("plugins")); });
        }

        public void add_plugin (string plugin, int? pos = null) throws PanelError {
            var current_plugins = new Gee.ArrayList<string> ();
            current_plugins.add_all_array (settings.get_strv ("plugins"));

            if (pos == null)
                current_plugins.add (plugin);
            else
                current_plugins.insert (pos, plugin);

            settings.set_strv ("plugins", current_plugins.to_array ());
        }

        public void pos_plugin (string plugin, int pos) throws PanelError {
            var current_plugins = new Gee.ArrayList<string> ();
            current_plugins.add_all_array (settings.get_strv ("plugins"));

            if (!current_plugins.contains (plugin))
                throw new PanelError.NOTEXISTS (@"$plugin not exists in configuration");

            current_plugins.remove (plugin);
            current_plugins.insert (pos, plugin);

            settings.set_strv ("plugins", current_plugins.to_array ());
            plugin_position_changed (plugin, pos);
        }

        public void remove_plugin (string plugin) throws PanelError {
            var current_plugins = new Gee.ArrayList<string> ();
            current_plugins.add_all_array (settings.get_strv ("plugins"));

            if (!current_plugins.contains (plugin))
                throw new PanelError.NOTEXISTS (@"$plugin not exists in configuration");

            current_plugins.remove (plugin);

            settings.set_strv ("plugins", current_plugins.to_array ());
        }
    }

    public class Background : Object {
        public string path { get; set; }
        public BackgroundFit fit { get; set; }

        internal Background (GLib.Settings settings) {
            settings.bind ("background", this, "path", SettingsBindFlags.DEFAULT);
            settings.bind ("background-fit", this, "fit", SettingsBindFlags.DEFAULT);
        }
    }

    [SingleInstance]
    public class Settings : Object {
        private GLib.Settings settings = new GLib.Settings ("com.github.ZzEdovec.TogetherShell");
        private Gee.HashMap<string, Panel> _panels = new Gee.HashMap<string, Panel> ();
        public Panel[] panels { owned get { return _panels.values.to_array (); }}
        public bool opacity { get; set; }
        public bool show_window_labels { get; set; }
        public bool group_windows { get; set; }
        public Background background { get; private set; }
        public PinnedApps panel_pinned { get; private set; }
        public PinnedApps menu_pinned { get; private set; }

        public signal void panel_added (Panel panel);
        public signal void panel_removed (Panel panel);

        construct {
            background = new Background (settings);
            panel_pinned = new PinnedApps (settings, "panel-pinned");
            menu_pinned = new PinnedApps (settings, "appmenu-pinned");

            settings.bind ("opacity", this, "opacity", SettingsBindFlags.DEFAULT);
            settings.bind ("window-list-labels", this, "show_window_labels", SettingsBindFlags.DEFAULT);
            settings.bind ("window-list-group", this, "group_windows", SettingsBindFlags.DEFAULT);

            update_panels ();

            settings.changed["panels"].connect (update_panels);
        }

        public Panel create_panel () {
            var id = Uuid.string_random ().replace ("-", "_");
            var panel = new Panel (id);
            _panels[id] = panel;
            string[] panels = _panels.keys.to_array ();

            settings.set_strv ("panels", panels);

            panel_added (panel);
            return panel;
        }

        public void remove_panel (string id) throws PanelError {
            if (!_panels.has_key (id))
                throw new PanelError.NOTEXISTS (@"Panel with id $id not exists");

            Panel panel;
            _panels.unset (id, out panel);
            settings.set_strv ("panels", _panels.keys.to_array ());

            panel_removed (panel);
        }

        private void update_panels () {
            var new_panels = new Gee.HashSet<string> ();
            var to_remove = new Gee.ArrayList<string> ();
            new_panels.add_all_array (settings.get_strv ("panels"));

            foreach (string id in _panels.keys) {
                if (!new_panels.contains (id))
                    to_remove.add (id);
            }

            foreach (string id in to_remove) {
                Panel panel;
                _panels.unset (id, out panel);

                panel_removed (panel);
            }

            foreach (string id in new_panels) {
                if (!_panels.has_key (id)) {
                    var panel = new Panel (id);
                    _panels[id] = panel;

                    panel_added (panel);
                }
            }
        }
    }
}

