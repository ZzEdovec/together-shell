namespace TogetherShell {
    [SingleInstance]
    public class PopupsManager : Object {
        private AstalWp.Wp wireplumber = AstalWp.get_default ();
        private Gee.ArrayList<Wayfire.Binding> bindings = new Gee.ArrayList<Wayfire.Binding> ();
        private LevelPopup level_popup = new LevelPopup ();

        public PopupsManager () {
            if (!bindings.is_empty)
                return;

            var volume_up_bind = new Wayfire.Binding ("KEY_VOLUMEUP", false, Wayfire.BindingMode.REPEAT);
            volume_up_bind.triggered.connect (() => { wireplumber.default_speaker.volume += 0.05; });
            var volume_down_bind = new Wayfire.Binding ("KEY_VOLUMEDOWN", false, Wayfire.BindingMode.REPEAT);
            volume_down_bind.triggered.connect (() => { wireplumber.default_speaker.volume -= 0.05; });
            bindings.add_all_array ({ volume_down_bind, volume_up_bind });

            wireplumber.default_speaker.notify["volume"].connect (() => { on_level (wireplumber.default_speaker); });
            wireplumber.default_microphone.notify["volume"].connect (() => { on_level (wireplumber.default_microphone); });
        }

        private void on_level (AstalWp.Endpoint endpoint) {
            level_popup.icon_name = endpoint.volume_icon;
            level_popup.progress = endpoint.volume;

            AstalMpris.Player? player = null;
            foreach (var pl in AstalMpris.get_default ().players) {
                if (pl.playback_status == AstalMpris.PlaybackStatus.PLAYING) {
                    player = pl;
                    break;
                }
            }

            level_popup.present (player);
        }
    }
}
