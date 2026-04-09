using TogetherCore.Settings.Shell;
using TogetherCore;
using TogetherWayland;

namespace TogetherShell {
    public class Panel : Gtk.Window, TogetherCore.Interfaces.Shell.PanelContext { // TODO: DOCK MODE, WIDGET_MOVE SIGNAL
        private TogetherCore.Settings.Shell.Panel settings;
        private Gtk.Box widgets_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        public PanelPosition position {
            get { return settings.position; }
            set {
                settings.position = value;
                upset_position ();

                position_changed (value);
            }
        }

        public Panel (TogetherCore.Settings.Shell.Panel settings) {
            this.settings = settings;
            opacity = new TogetherCore.Settings.Shell.Settings ().opacity ? 0.8 : 1;
            child = widgets_box;

            GtkLayerShell.init_for_window (this);
            GtkLayerShell.auto_exclusive_zone_enable (this);
            GtkLayerShell.set_layer (this, GtkLayerShell.Layer.TOP);
            GtkLayerShell.set_keyboard_mode (this, GtkLayerShell.KeyboardMode.ON_DEMAND);

            upset_position ();

            settings.notify["position"].connect (upset_position);
            settings.notify["size"].connect (update_size);

            for (uint i = 0; i < settings.plugins_manager.plugins.get_n_items (); i++) {
                var obj = settings.plugins_manager.plugins.get_item (i);
                if (obj != null)
                    load_plugin ((Interfaces.Shell.Plugin) obj);
            }

            settings.plugins_manager.plugins.extension_added.connect ((info, obj) => { load_plugin ((Interfaces.Shell.Plugin) obj); });
            settings.plugins_manager.plugins.extension_removed.connect ((info, obj) => { unload_plugin ((Interfaces.Shell.Plugin) obj); });
        }

        private void load_plugin (Interfaces.Shell.Plugin plugin) {
            plugin.activate (this);
            var panel_widget = plugin.get_panel_widget ();
            widgets_box.append (panel_widget);

            var showable = plugin.get_showable_widget ();
            if (showable != null && panel_widget is Gtk.ToggleButton)
                new PanelPopup (this, (Gtk.ToggleButton) panel_widget, showable);
        }

        /*private void repos_plugin (Interfaces.Shell.Plugin ) { TODO

        }*/

        private void unload_plugin (Interfaces.Shell.Plugin plugin) {
            widgets_box.remove (plugin.get_panel_widget ());
        }

        private void upset_position () {
            GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, false);
            GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, false);
            GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, false);
            GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, false);

            default_height = 0;
            default_width = 0;

            switch (settings.position) {
                case PanelPosition.BOTTOM:
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);

                    widgets_box.orientation = Gtk.Orientation.HORIZONTAL;
                    default_height = (int) settings.size;
                break;
                case PanelPosition.TOP:
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);

                    widgets_box.orientation = Gtk.Orientation.HORIZONTAL;
                    default_height = (int) settings.size;
                break;
                case PanelPosition.LEFT:
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);

                    widgets_box.orientation = Gtk.Orientation.VERTICAL;
                    default_width = (int) settings.size;
                break;
                case PanelPosition.RIGHT:
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);

                    widgets_box.orientation = Gtk.Orientation.VERTICAL;
                    default_width = (int) settings.size;
                break;
            }
        }

        private void update_size () {
            if (default_height > 0)
                default_height = (int) settings.size;
            else
                default_width = (int) settings.size;
        }
    }
}
