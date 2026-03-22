using TogetherShell;

namespace ControlCenterPlugin {
    [GtkTemplate (ui = "/com/github/ZzEdovec/togethershell/panel/controlcenter/control_center.ui")]
    public sealed class ControlCenter : Gtk.Popover {
        [GtkChild]
        private unowned Adw.ViewStack status_view_stack;
        [GtkChild]
        private unowned Adw.ViewStack view_stack;

        private AstalWp.Wp wireplumber = AstalWp.Wp.get_default ();
        private AstalNetwork.Network network = AstalNetwork.get_default ();

        private Gee.HashMap<Object, ulong> signals = new Gee.HashMap<Object, ulong> ();

        public ControlCenter () {
            load_pages ();

            signals[wireplumber] = wireplumber.audio.device_added.connect (load_pages); // lazy init, no remove handler needed
            signals[network] = network.notify["wifi"].connect (load_pages);
        }

        private void load_pages () {
            if (wireplumber.audio.devices.length () > 0 && signals.has_key (wireplumber)) {
                var sound_page = new SoundPage ();
                view_stack.add_titled_with_icon (sound_page, null, _("Sound"), "audio-volume-high-symbolic");

                wireplumber.audio.disconnect (signals[wireplumber]);
                signals.unset (wireplumber);
            }
            if (network.wifi != null && signals.has_key (network)) {
                var wireless_page = new WirelessPage ();
                view_stack.add_titled_with_icon (wireless_page, null, "Wi-Fi", "network-wireless-symbolic");

                network.disconnect (signals[network]);
                signals.unset (network);
            }

            status_view_stack.visible_child_name = view_stack.get_first_child () == null ? "error" : "settings";
        }
    }

    public class StatusBox : Gtk.Box {
        private AstalBluetooth.Bluetooth bluetooth = AstalBluetooth.get_default ();
        private AstalNetwork.Network network = AstalNetwork.get_default ();
        private AstalWp.Wp wireplumber = AstalWp.get_default ();
        private AstalBattery.Device battery = AstalBattery.get_default ();

        private Gtk.Image microphone_icon = new Gtk.Image ();
        private Gtk.Image webcam_icon = new Gtk.Image ();
        private Gtk.Label battery_label = new Gtk.Label (null);
        private Gtk.Image battery_icon = new Gtk.Image ();
        private Gtk.Image sound_icon = new Gtk.Image ();
        private Gtk.Image network_icon = new Gtk.Image ();
        private Gtk.Image bluetooth_icon = new Gtk.Image ();

        private Gee.HashMap<Object, Gee.ArrayList<ulong>> signal_ids = new Gee.HashMap<Object, Gee.ArrayList<ulong>> ();

        public StatusBox () {
            spacing = 8;

            microphone_icon.tooltip_text = _("Microphone in use");
            webcam_icon.tooltip_text = _("Webcam in use");

            microphone_icon.icon_name = "audio-input-microphone-symbolic";
            webcam_icon.icon_name = "camera-video-symbolic";

            Gtk.Widget[] widgets = { microphone_icon, webcam_icon, bluetooth_icon, network_icon, sound_icon, battery_icon, battery_label };
            foreach (var widget in widgets)
                append (widget);

            microphone_icon.css_classes = webcam_icon.css_classes = { "accent" };

            update_microphone_status ();
            update_network_status ();
            update_webcam_status ();
            update_sound_status ();
            update_bluetooth_status ();
            update_battery_status ();

            reg_signal (wireplumber.audio, wireplumber.audio.recorder_added.connect (update_microphone_status));
            reg_signal (wireplumber.audio, wireplumber.audio.recorder_removed.connect (update_microphone_status));
            reg_signal (wireplumber.audio, wireplumber.audio.default_speaker.notify["volume"].connect (update_sound_status));
            reg_signal (wireplumber.audio, wireplumber.audio.default_speaker.notify["mute"].connect (update_sound_status));
            reg_signal (wireplumber.video, wireplumber.video.recorder_added.connect (update_webcam_status));
            reg_signal (wireplumber.video, wireplumber.video.recorder_removed.connect (update_webcam_status));
            reg_signal (network, network.notify["primary"].connect (update_network_status));
            reg_signal (network, network.notify["state"].connect (update_network_status));
            reg_signal (bluetooth, bluetooth.notify["is-powered"].connect (update_bluetooth_status));
            reg_signal (bluetooth, bluetooth.notify["is-connected"].connect (update_bluetooth_status));
            reg_signal (battery, battery.notify["percentage"].connect (update_battery_status));
            reg_signal (battery, battery.notify["charging"].connect (update_battery_status));
            reg_signal (battery, battery.notify["battery-icon-name"].connect (update_battery_status));
        }

        private void reg_signal (Object obj, ulong id) {
            Gee.ArrayList<ulong> ids = signal_ids[obj] ?? new Gee.ArrayList<ulong> ();

            ids.add (id);
            signal_ids[obj] = ids;
        }

        public void unload () {
            foreach (var object in signal_ids) {
                foreach (var signal_id in object.value)
                    object.key.disconnect (signal_id);
            }

            signal_ids.clear ();
        }

        private void update_microphone_status () {
            if (wireplumber.audio.recorders.length () > 0)
                microphone_icon.visible = true;
            else
                microphone_icon.visible = false;
        }

        private void update_webcam_status () {
            if (wireplumber.video.recorders.length () > 0)
                webcam_icon.visible = true;
            else
                webcam_icon.visible = false;
        }

        private void update_sound_status () {
            var speaker = wireplumber.audio.default_speaker;
            if (speaker.volume > 0)
                sound_icon.icon_name = speaker.volume_icon;
            else
                sound_icon.icon_name = "audio-volume-muted-symbolic";
        }

        private void update_network_status () {
            network_icon.css_classes = {};
            string network_type;

            if (network.primary == AstalNetwork.Primary.UNKNOWN || network.state == AstalNetwork.State.UNKNOWN) {
                network_icon.tooltip_text = _("Unknown state");
                network_icon.icon_name = "network-error-symbolic";

                return;
            }
            else
                network_type = network.primary == AstalNetwork.Primary.WIRED ? "wired"
                                                                             : "wireless";

            switch (network.state) {
                case (AstalNetwork.State.ASLEEP):
                    network_icon.tooltip_text = _("Airplane mode");
                    network_icon.icon_name = "airplane-mode-symbolic";
                break;
                case (AstalNetwork.State.DISCONNECTED):
                    network_icon.tooltip_text = _("Disconnected");
                    network_icon.icon_name = network_type == "wired" ? "network-wired-disconnected-symbolic"
                                                                     : "network-wireless-offline-symbolic";
                break;
                case (AstalNetwork.State.CONNECTING):
                case (AstalNetwork.State.DISCONNECTING):
                    network_icon.tooltip_text = _("Acquiring");
                    network_icon.icon_name = @"network-$network_type-acquiring-symbolic";
                break;
                case (AstalNetwork.State.CONNECTED_LOCAL):
                    network_icon.tooltip_text = _("Connected, no gateway");
                    network_icon.icon_name = @"network-$network_type-no-route-symbolic";
                break;
                case (AstalNetwork.State.CONNECTED_SITE):
                case (AstalNetwork.State.CONNECTED_GLOBAL):
                    if (network.state == AstalNetwork.State.CONNECTED_SITE) {
                        network_icon.tooltip_text = _("Connected, gateway only");
                        network_icon.css_classes = { "dimmed" };
                    }
                    else
                        network_icon.tooltip_text = _("Connected to global network");

                    if (network_type == "wired")
                        network_icon.icon_name = "network-wired-symbolic";
                    else
                        network_icon.icon_name = network.wifi.icon_name;
                break;
            }
        }

        private void update_bluetooth_status () {
            if (bluetooth.is_powered) {
                bluetooth_icon.visible = true;
                bluetooth_icon.icon_name = bluetooth.is_connected ? "bluetooth-active-symbolic"
                                                                  : "bluetooth-disconnected-symbolic";
            }
            else
                bluetooth_icon.visible = false;
        }

        private void update_battery_status () {
            if (!battery.is_present || battery.device_type != AstalBattery.Type.BATTERY || !battery.power_supply)
                battery_label.visible = battery_icon.visible = false;
            else {
                battery_label.visible = battery_icon.visible = true;

                var battery_percentage = (uint) (battery.percentage * 100);
                battery_label.label = battery_percentage.to_string () + "%";
                battery_icon.icon_name = battery.battery_icon_name;
            }
        }
    }

    public class Plugin : Object, TogetherShell.Plugin {
        private Panel panel;

        public Plugin (Panel panel) {
            this.panel = panel;
        }

        public string get_name () {
            return "Control center";
        }

        public string get_desc () {
            return "Fast settings";
        }

        public Gtk.Widget? get_panel_widget() {
            var button = new Gtk.MenuButton ();
            var status_box = new StatusBox ();

            button.css_classes = { "panel-button", "flat" };
            button.child = status_box;

            return button;
        }

        public Gtk.Popover? get_showable_widget () {
            return new ControlCenter ();
        }

        public bool unregister () {
            return true;
        }
    }
}

[CCode (cname = "register_plugin")]
public TogetherShell.Plugin register_plugin(TogetherShell.Panel? panel) {
    return new ControlCenterPlugin.Plugin (panel);
}
