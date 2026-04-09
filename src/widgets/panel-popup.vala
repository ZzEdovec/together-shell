using TogetherCore.Settings.Shell;

namespace TogetherShell {
    public class PanelPopup : Gtk.Window {
        private Panel panel;
        private Gtk.ToggleButton button;
        private Gtk.Revealer revealer = new Gtk.Revealer ();
        //private Registry registry = new Registry ();

        public PanelPopup (Panel panel, Gtk.ToggleButton button, Adw.Bin content) {
            this.panel = panel;
            this.button = button;

            button.set_data<PanelPopup> ("panel_popup", this);

            revealer.child = content;
            child = revealer;

            var focus_controller = new Gtk.EventControllerFocus ();
            focus_controller.leave.connect (close);
            ((Gtk.Widget) this).add_controller (focus_controller);

            button.toggled.connect (() => {
                if (button.active)
                    present ();
                else
                    close ();
            });
            button.realize.connect (pos);
            panel.position_changed.connect (pos);

            GtkLayerShell.init_for_window (this);
            GtkLayerShell.set_layer (this, GtkLayerShell.Layer.OVERLAY);
            GtkLayerShell.set_keyboard_mode (this, GtkLayerShell.KeyboardMode.ON_DEMAND);
        }

        public new void present () {
            base.present ();
            revealer.reveal_child = true;
        }

        public new void minimize () {
            revealer.reveal_child = false;
            Timeout.add_once (revealer.transition_duration, () => { base.minimize (); });
        }

        public new void close () {
            revealer.reveal_child = false;
            Timeout.add_once (revealer.transition_duration, () => { base.close (); });
        }

        private void drop_margins () {
            GtkLayerShell.set_margin (this, GtkLayerShell.Edge.TOP, 0);
            GtkLayerShell.set_margin (this, GtkLayerShell.Edge.BOTTOM, 0);
            GtkLayerShell.set_margin (this, GtkLayerShell.Edge.LEFT, 0);
            GtkLayerShell.set_margin (this, GtkLayerShell.Edge.RIGHT, 0);
        }

        private void drop_anchors () {
            GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, false);
            GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, false);
            GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, false);
            GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, false);
        }

        private void pos () {
            Graphene.Rect bounds;
            if (!button.compute_bounds (panel, out bounds))
                return;

            drop_margins ();
            drop_anchors ();

            switch (panel.position) { // TODO: Panel dock mode
                case (PanelPosition.TOP):
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);
                    GtkLayerShell.set_margin (this, GtkLayerShell.Edge.TOP, 8); // panel has exclusive zone
                    GtkLayerShell.set_margin (this, GtkLayerShell.Edge.LEFT, (int) bounds.origin.x);
                    revealer.transition_type = Gtk.RevealerTransitionType.SWING_DOWN;
                break;
                case (PanelPosition.BOTTOM):
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
                    GtkLayerShell.set_margin (this, GtkLayerShell.Edge.BOTTOM, 8);
                    GtkLayerShell.set_margin (this, GtkLayerShell.Edge.LEFT, (int) bounds.origin.x);
                    revealer.transition_type = Gtk.RevealerTransitionType.SWING_UP;
                break;
                case (PanelPosition.LEFT):
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
                    GtkLayerShell.set_margin (this, GtkLayerShell.Edge.LEFT, 8);
                    GtkLayerShell.set_margin (this, GtkLayerShell.Edge.TOP, (int) bounds.origin.y);
                    revealer.transition_type = Gtk.RevealerTransitionType.SWING_RIGHT;
                break;
                case (PanelPosition.RIGHT):
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);
                    GtkLayerShell.set_margin (this, GtkLayerShell.Edge.RIGHT, 8);
                    GtkLayerShell.set_margin (this, GtkLayerShell.Edge.TOP, (int) bounds.origin.y);
                    revealer.transition_type = Gtk.RevealerTransitionType.SWING_LEFT;
                break;
            }
        }
    }
}
