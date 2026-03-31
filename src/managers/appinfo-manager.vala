[SingleInstance]
public class TogetherShell.AppInfoManager : Object {
    public Gee.HashMap<string,AppInfo> apps_list { get; private set; }
    private AppInfoMonitor apps_monitor = AppInfoMonitor.get ();
    private ulong monitor_handle_id;

    public signal void app_added (string app);
    public signal void app_updated (string app);
    public signal void app_removed (string app);

    public AppInfoManager () {
        if (apps_list != null)
            return;

        apps_list = new Gee.HashMap<string,AppInfo> ();

        update_apps_list ();
        monitor_handle_id = apps_monitor.changed.connect (update_apps_list);
    }

    private void update_apps_list () {
        var new_apps = AppInfo.get_all ();
        var new_apps_gee = new Gee.HashMap<string,AppInfo> ();
        var to_remove = new Gee.ArrayList<string> ();

        new_apps.foreach ((app) => { new_apps_gee[app.get_id ()[0:-8]] = app; }); // -8 - removing .desktop file extension

        foreach (var app in apps_list.keys) {
            if (new_apps_gee.has_key (app) == false)
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
            if (updated == true)
                app_updated (app.key);
            else
                app_added (app.key);
        }
    }

    public void stop () {
        apps_monitor.disconnect (monitor_handle_id);
    }
}

