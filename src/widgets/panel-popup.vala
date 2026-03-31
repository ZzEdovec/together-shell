namespace TogetherShell {
    public class PanelPopup : Gtk.Window {
        private Panel panel;
        private Gtk.ToggleButton button;
        private TogetherWayland.Registry registry = new TogetherWayland.Registry ();

        public PanelPopup (Panel panel, Gtk.ToggleButton button) {
            this.panel = panel;
            this.button = button;

            GtkLayerShell.init_for_window (this);
        }

        public void present () {
            var p = compute_present_geometry ();
        }

        private Graphene.Point compute_present_geometry () {
            Graphene.Point p = Graphene.Point () { x = button.get_width () / 2, y = 0 };
            //var output = registry.outputs_keeper.get_output_by_widget (panel);
            button.compute_point (panel, p, out p);

            return p; // TODO
        }
    }
}
