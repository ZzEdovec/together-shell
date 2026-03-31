namespace TogetherShell {
    [GtkTemplate (ui = "/com/github/ZzEdovec/togethershell/ui/level_popup.ui")]
    public class LevelPopup : Gtk.Window {
        [GtkChild]
        private unowned Gtk.Image icon;
        [GtkChild]
        private unowned Gtk.ProgressBar bar;
        [GtkChild]
        private unowned Gtk.Box player_box;
        [GtkChild]
        private unowned Gtk.Picture player_picture;
        [GtkChild]
        private unowned Gtk.Label player_name;
        [GtkChild]
        private unowned Gtk.Label player_artist;

        private uint? timeout_id;
        public GtkLayerShell.Edge edge { get; set; default = GtkLayerShell.Edge.TOP; }
        public Gtk.RevealerTransitionType transition_type { get; set; default = Gtk.RevealerTransitionType.SWING_DOWN; }
        public double progress { get; set; }
        public string icon_name { get; set; }

        public LevelPopup () {
            GtkLayerShell.init_for_window (this);
            GtkLayerShell.set_layer (this, GtkLayerShell.Layer.OVERLAY);
            upset_edge ();

            bind_property ("progress", bar, "fraction", BindingFlags.SYNC_CREATE);
            bind_property ("icon_name", icon, "icon_name", BindingFlags.SYNC_CREATE);
            notify["edge"].connect (upset_edge);
        }

        private void upset_edge () {
            GtkLayerShell.set_anchor (this, edge, true);
            GtkLayerShell.set_margin (this, edge, 8);
        }

        private void load_from_player (AstalMpris.Player player) {
            player_box.visible = true;

            if (player_picture.file == null || player_picture.file.get_path () != player.cover_art)
                player_picture.set_filename (player.cover_art);

            player_name.label = player.title;
            player_artist.label = player.artist;
        }

        public new void present (AstalMpris.Player? player = null) {
            base.present ();

            if (player != null)
                load_from_player (player);
            else
                player_box.visible = false;

            if (timeout_id != null)
                Source.remove (timeout_id);

            timeout_id = Timeout.add_seconds_once (3, () => {
                hide ();
                timeout_id = null;
            });
        }
    }
}
