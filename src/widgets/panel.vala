namespace TogetherShell {
    public class Panel : Gtk.Window, PanelContext {
        private PanelPosition _panel_position;
        public Gtk.Box widgets_box { get; default = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0); }
        public PanelPosition panel_position {
            get { return _panel_position; }
            set {
                set_anchor (value);
                _panel_position = value;

                position_changed (value);
            }
        }

        public Panel (TogetherShell.Application application, Json.Object config) {
            Object (
                application: application,
                default_height: (int) config.get_int_member_with_default ("height", 48),
                opacity: config.get_double_member_with_default ("opacity", 0.8)
            );
            child = widgets_box;

            GtkLayerShell.init_for_window (this);
            GtkLayerShell.auto_exclusive_zone_enable (this);
            GtkLayerShell.set_layer (this, GtkLayerShell.Layer.TOP);
            GtkLayerShell.set_keyboard_mode (this, GtkLayerShell.KeyboardMode.ON_DEMAND);

            translate_json_position (config.get_string_member_with_default ("position", "bottom"));
            present ();
        }

        public PanelPosition get_panel_position () { return _panel_position; }

        private void translate_json_position (string position) {
            switch (position) {
                case "bottom":
                    panel_position = PanelPosition.BOTTOM;
                break;
                case "top":
                    panel_position = PanelPosition.TOP;
                break;
                case "left":
                    panel_position = PanelPosition.LEFT;
                break;
                case "right":
                    panel_position = PanelPosition.RIGHT;
                break;
            }
        }

        private void set_anchor (PanelPosition pos) {
            GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, false);
            GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, false);
            GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, false);
            GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, false);

            switch (pos) {
                case PanelPosition.BOTTOM:
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);

                    widgets_box.orientation = Gtk.Orientation.HORIZONTAL;
                break;
                case PanelPosition.TOP:
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);

                    widgets_box.orientation = Gtk.Orientation.HORIZONTAL;
                break;
                case PanelPosition.LEFT:
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);

                    widgets_box.orientation = Gtk.Orientation.VERTICAL;
                break;
                case PanelPosition.RIGHT:
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);

                    widgets_box.orientation = Gtk.Orientation.VERTICAL;
                break;
            }
        }
    }
}
