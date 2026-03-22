namespace TogetherShell {
    private class PluginInfo : Object {
        public Module module;
        public Plugin plugin;
        public int users;

        public PluginInfo (Plugin plugin, owned Module module) {
            module = (owned) module;
            users = 1;
            this.plugin = plugin;
        }
    }

    public class PluginLoader : Object {
        private Gee.HashMap<string, PluginInfo> plugins;

        public PluginLoader () {
            plugins = new Gee.HashMap<string, PluginInfo> ();
        }

        public Plugin? load_plugin (string libname, Panel? panel) {
            if (plugins.has_key (libname)) {
                plugins[libname].users++;

                return plugins[libname].plugin;
            }

            Module module = Module.open ("%s/%s".printf (Config.PLUGINS_DIR, libname), ModuleFlags.LAZY);
            if (module == null) {
                warning ("Failed to load plugin: %s", Module.error ());
                return null;
            }

            void* func;
            if (!module.symbol ("register_plugin", out func))
            {
                warning (@"register_plugin not defined in $libname");
                return null;
            }

            var register = (register_plugin) func;
            var plugin = register (panel);

            module.make_resident ();

            plugins[libname] = new PluginInfo (plugin, (owned) module);

            return plugin;
        }
    }
}
