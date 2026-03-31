namespace ControlCenterPlugin {
    [GtkTemplate (ui = "/com/github/ZzEdovec/togethershell/panel/controlcenter/sound_page.ui")]
    public sealed class SoundPage : Adw.Bin {
        [GtkChild]
        private unowned Adw.ExpanderRow output_expander;
        [GtkChild]
        private unowned Adw.ExpanderRow input_expander;
        [GtkChild]
        private unowned Adw.ActionRow speaker_volume_row;
        [GtkChild]
        private unowned Adw.ActionRow microphone_volume_row;
        [GtkChild]
        private unowned Gtk.Scale speaker_volume_scale;
        [GtkChild]
        private unowned Gtk.Scale microphone_volume_scale;

        private unowned AstalWp.Wp wireplumber = AstalWp.get_default ();
        private Gee.ArrayList<ulong> signals = new Gee.ArrayList<ulong> ();

        public SoundPage () {
            wireplumber.default_speaker.bind_property ("volume", speaker_volume_scale.adjustment, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            wireplumber.default_speaker.bind_property ("volume", speaker_volume_row, "subtitle", BindingFlags.SYNC_CREATE, volume_to_subtitle);
            wireplumber.default_speaker.bind_property ("volume_icon", speaker_volume_row, "icon_name", BindingFlags.SYNC_CREATE);
            wireplumber.default_microphone.bind_property ("volume", microphone_volume_scale.adjustment, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            wireplumber.default_microphone.bind_property ("volume", microphone_volume_row, "subtitle", BindingFlags.SYNC_CREATE, volume_to_subtitle);
            wireplumber.default_microphone.bind_property ("volume_icon", microphone_volume_row, "icon_name", BindingFlags.SYNC_CREATE);

            foreach (var endpoint in wireplumber.audio.speakers)
                create_endpoint_row (endpoint);
            foreach (var endpoint in wireplumber.audio.microphones)
                create_endpoint_row (endpoint);

            ulong speak_mute_id = speaker_volume_row.activated.connect (() => {wireplumber.audio.default_speaker.mute = !wireplumber.audio.default_speaker.mute;});
            ulong mic_mute_id = microphone_volume_row.activated.connect (() => {wireplumber.audio.default_microphone.mute = !wireplumber.audio.default_microphone.mute;});
            ulong speak_added_id = wireplumber.audio.speaker_added.connect (create_endpoint_row);
            ulong mic_added_id = wireplumber.audio.microphone_added.connect (create_endpoint_row);
            ulong speak_removed_id = wireplumber.audio.speaker_removed.connect (remove_endpoint_row);
            ulong mic_removed_id = wireplumber.audio.microphone_removed.connect (remove_endpoint_row);
            signals.add_all_array ({ speak_mute_id, mic_mute_id, speak_added_id, mic_added_id, speak_removed_id, mic_removed_id });
        }

        public override void dispose () {
            if (!signals.is_empty) {
                foreach (ulong id in signals)
                    wireplumber.audio.disconnect (id);

                signals.clear ();
            }

            base.dispose ();
        }

        private void create_endpoint_row (AstalWp.Endpoint endpoint) {
            if (endpoint.get_data<Adw.ActionRow?> ("row") != null)
                return;

            var adjustment = new Gtk.Adjustment (0, 0, 1, 0, 0, 0);
            endpoint.bind_property ("volume", adjustment, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

            var scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, adjustment);
            scale.digits = 2;
            scale.width_request = 120;

            var row = new Adw.ActionRow ();
            row.activatable = true;
            row.activated.connect (() => {endpoint.is_default = true;});
            row.add_suffix (scale);

            endpoint.bind_property ("volume", row, "subtitle", BindingFlags.SYNC_CREATE, volume_to_subtitle);
            endpoint.bind_property ("description", row, "title", BindingFlags.SYNC_CREATE);
            endpoint.bind_property ("is_default", row, "icon_name", BindingFlags.SYNC_CREATE, (bind, def, ref icon) => {
                if ((bool) def)
                    icon = "selection-mode-symbolic";
                else
                    icon = "";

                return true;
            });
            endpoint.set_data<Adw.ActionRow> ("row", row);

            if (endpoint.media_class == AstalWp.MediaClass.AUDIO_SINK)
                output_expander.add_row (row);
            else
                input_expander.add_row (row);

            update_visibility ();
        }

        private void remove_endpoint_row (AstalWp.Endpoint endpoint) {
            var row = endpoint.get_data<Adw.ActionRow> ("row");
            endpoint.set_data<Adw.ActionRow?> ("row", null);
            row.unparent ();

            update_visibility ();
        }

        private void update_visibility () {
            var speaks_count = wireplumber.audio.speakers.length ();
            var micros_count = wireplumber.audio.microphones.length ();

            this.visible = speaks_count > 0 && micros_count > 0;
            speaker_volume_row.visible = output_expander.visible = speaks_count > 0;
            microphone_volume_row.visible = input_expander.visible = micros_count > 0;
        }

        private bool volume_to_subtitle (Binding bind, Value volume, ref Value subtitle) {
            subtitle = _("Volume: %.0f%%").printf ((double) volume * 100);
            return true;
        }
    }
}
