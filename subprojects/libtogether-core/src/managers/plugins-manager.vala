public class TogetherCore.Managers.PluginsManager<T> {
    private Peas.Engine engine = new Peas.Engine.with_nonglobal_loaders ();
    public Peas.ExtensionSet plugins { get; private set; }

    public PluginsManager (string path, string[] plugins) {
        engine.add_search_path (path, null);
        engine.set_loaded_plugins (plugins);

        this.plugins = new Peas.ExtensionSet.with_properties (engine, typeof (T), {}, {});
    }

    public void set_loaded_plugins (string[] plugins) {
        var to_load = new Gee.ArrayList<string> ();

        foreach (var plugin in plugins) {
            if (!to_load.contains (plugin))
                to_load.add (plugin);
        }

        engine.set_loaded_plugins (to_load.to_array ());
    }
}
