[SingleInstance]
public class TogetherCore.Managers.AppInfoManager : Object {
    private Gee.HashMap<string, DesktopAppInfo> apps_list = new Gee.HashMap<string, DesktopAppInfo> ();
    private AppInfoMonitor apps_monitor = AppInfoMonitor.get ();

    public signal void app_added (string app);
    public signal void app_updated (string app);
    public signal void app_removed (string app);

    construct {
        update_apps_list ();
        apps_monitor.changed.connect (update_apps_list);
    }

    public DesktopAppInfo? get_by_id (string app_id) {
        if (app_id.has_suffix (".desktop") && !apps_list.has_key (app_id))
            return apps_list[app_id[0:-8]];
        else
            return apps_list[app_id];
    }

    public DesktopAppInfo? get_by_wm_class (string wm_class) {
        foreach (var app in apps_list.values) {
            if (app.get_startup_wm_class () == wm_class)
                return app;
        }

        return null;
    }

    public DesktopAppInfo[] get_all () {
        return apps_list.values.to_array ();
    }

    private void update_apps_list () {
        var new_apps = AppInfo.get_all ();
        var new_apps_gee = new Gee.HashMap<string, DesktopAppInfo> ();
        var to_remove = new Gee.ArrayList<string> ();

        new_apps.foreach ((app) => { new_apps_gee[app.get_id ()[0:-8]] = (DesktopAppInfo) app; }); // -8 - removing .desktop file extension

        foreach (var app in apps_list.keys) {
            if (!new_apps_gee.has_key (app))
                to_remove.add (app);
        }

        foreach (var app in to_remove) {
            apps_list.unset (app);
            app_removed (app);
        }

        foreach (var app in new_apps_gee) {
            bool updated = false;

            if (apps_list.has_key (app.key)) {
                if (apps_list[app.key].equal (app.value))
                    continue;

                updated = true;
            }

            apps_list[app.key] = app.value;
            if (updated)
                app_updated (app.key);
            else
                app_added (app.key);
        }
    }
}

