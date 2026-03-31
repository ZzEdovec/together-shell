namespace ControlCenterPlugin {
    public sealed class WirelessPage : ConnectionPage {
        private Gtk.Button scan_button = new Gtk.Button ();
        private Adw.Spinner scan_spinner = new Adw.Spinner ();

        private AstalNetwork.Network network = AstalNetwork.get_default ();
        private Gee.HashMap<Object, Gee.ArrayList<ulong>> signals = new Gee.HashMap<Object, Gee.ArrayList<ulong>> ();
        private Gee.HashMap<AstalNetwork.AccessPoint, ConnectionRow> rows = new Gee.HashMap<AstalNetwork.AccessPoint, ConnectionRow> ();

        // TODO: Invalid password catch
        // ПЕРЕДЕЛАТЬ ВСЕ НАХУЙ

        public WirelessPage () {
            connection_type = "Wi-Fi";

            var scan_label = new Gtk.Label (_("Refresh"));
            var scan_icon = new Gtk.Image ();
            scan_icon.icon_name = "view-refresh-symbolic";
            var scan_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);

            scan_box.append (scan_icon);
            scan_box.append (scan_label);

            scan_button.css_classes = { "flat" };
            scan_button.child = scan_box;

            available_connections_list.set_sort_func (sort_rows);

            if (network.wifi != null)
                connect_handlers ();

            reg_signal_id (network, network.notify["wifi"].connect (() => {
                if (network.wifi != null)
                    connect_handlers ();
                else {
                    foreach (var ap in rows.keys)
                        remove_row (ap);

                    disconnect_handlers ();
                    visible = false;
                }
            }));
        }

        public override void dispose () {
            disconnect_handlers ();
            base.dispose ();
        }

        private void reg_signal_id (Object obj, ulong id) {
            Gee.ArrayList<ulong> ids;
            if (signals.has_key (obj))
                ids = signals[obj];
            else {
                ids = new Gee.ArrayList<ulong> ();
                signals[obj] = ids;
            }

            ids.add (id);
        }

        private void connect_handlers () {
            foreach (var ap in network.wifi.access_points)
                create_row (ap);

            reg_signal_id (scan_button, scan_button.clicked.connect (() => { network.wifi.scan (); }));
            reg_signal_id (network.wifi, network.wifi.device.state_changed.connect (update_rows));
            reg_signal_id (network.wifi, network.wifi.access_point_added.connect (create_row));
            reg_signal_id (network.wifi, network.wifi.access_point_removed.connect (remove_row));

            network.wifi.bind_property ("enabled", connection_switch, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            network.wifi.bind_property ("enabled", available_connections_group, "visible", BindingFlags.SYNC_CREATE);
            network.wifi.bind_property ("scanning", available_connections_group, "header_suffix", BindingFlags.SYNC_CREATE, switch_scanning_widget);
        }

        private void disconnect_handlers (Object? obj = null) {
            if (obj == null) {
                foreach (var key in signals.keys)
                    disconnect_handlers (key);

                return;
            }

            foreach (ulong id in signals[obj])
                obj.disconnect (id);

            signals.unset (obj);
        }

        private bool switch_scanning_widget (Binding bind, Value scanning, ref Value header_suffix) {
            header_suffix = (bool) scanning ? (Gtk.Widget) scan_spinner : (Gtk.Widget) scan_button;
            return true;
        }

        private void create_row (AstalNetwork.AccessPoint ap) {
            var row = new ConnectionRow (get_connection_status (ap));
            row.set_data<AstalNetwork.AccessPoint> ("ap", ap);

            ap.bind_property ("ssid", row, "title", BindingFlags.SYNC_CREATE, (bind, ssid, ref title) => {
                var point = (AstalNetwork.AccessPoint) bind.source;
                var ssid_str = ssid as string;
                if (ssid_str != null)
                    title = ssid_str;
                else
                    title = _("Unknown SSID (%s)").printf (point.bssid);

                return true;
            });
            ap.bind_property ("requires_password", row, "connection_status", BindingFlags.DEFAULT, (bind, req, ref status) => {
                status = get_connection_status ((AstalNetwork.AccessPoint) bind.source);
                return true;
            });
            ap.bind_property ("icon_name", row, "icon_name", BindingFlags.SYNC_CREATE);

            reg_signal_id (row, row.selected.connect ((action, pass) => { do_row_action (ap, row, action, pass); }));
            reg_signal_id (ap, ap.notify["strength"].connect (() => { available_connections_list.invalidate_sort (); }));

            available_connections_list.append (row);
            rows[ap] = row;
        }

        private ConnectionStatus get_connection_status (AstalNetwork.AccessPoint ap) {
            ConnectionStatus status;
            if (network.wifi.active_access_point == ap)
                status = ConnectionStatus.CONNECTED;
            else if (ap.get_connections ().length > 0)
                status = ConnectionStatus.KNOWN;
            else if (ap.requires_password)
                status = ConnectionStatus.PASSWORD;
            else
                status = ConnectionStatus.NOPASSWORD;

            return status;
        }

        private void update_rows () {
            foreach (var entry in rows)
                entry.value.connection_status = get_connection_status (entry.key);
        }

        private void remove_row (AstalNetwork.AccessPoint ap) {
            var row = rows[ap];
            disconnect_handlers (row);
            disconnect_handlers (ap);
            available_connections_list.remove (row);

            rows.unset (ap);
        }

        private void do_row_action (AstalNetwork.AccessPoint ap, ConnectionRow row, ConnectionAction action, string? password) {
            switch (action) {
                case (ConnectionAction.CONNECT):
                    ap.activate.begin (password, (obj, res) => {
                        try {
                            ap.activate.end (res);
                            row.connection_status = ConnectionStatus.CONNECTED;

                            available_connections_list.invalidate_sort ();
                        } catch {
                            toast_overlay.add_toast (new Adw.Toast (_("Failed to connect")));
                        }
                    });
                break;
                case (ConnectionAction.DISCONNECT):
                    var wifi = network.wifi;
                    if (wifi.active_access_point != ap)
                        return;

                    wifi.deactivate_connection.begin ((obj, res) => {
                        try {
                            wifi.deactivate_connection.end (res);
                            row.connection_status = ConnectionStatus.KNOWN;

                            available_connections_list.invalidate_sort ();
                        } catch {
                            toast_overlay.add_toast (new Adw.Toast (_("Failed to disconnect")));
                        }
                    });
                break;
                case (ConnectionAction.REMOVE):
                    foreach (var connection in ap.get_connections ()) {
                        connection.delete_async.begin (null, (obj, res) => {
                            try {
                                connection.delete_async.end (res);
                                row.connection_status = ap.requires_password ? ConnectionStatus.PASSWORD : ConnectionStatus.NOPASSWORD;

                                available_connections_list.invalidate_sort ();
                            } catch {
                                toast_overlay.add_toast (new Adw.Toast (_("Failed to remove")));
                            }
                        });
                    }
                break;
            }
        }

        private int sort_rows (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
            var a = row1.get_data<AstalNetwork.AccessPoint> ("ap");
            var b = row2.get_data<AstalNetwork.AccessPoint> ("ap");

            if (network.wifi.active_access_point == a || a.get_connections ().length > 0) return -1;
            if (network.wifi.active_access_point == b || b.get_connections ().length > 0) return 1;

            return (int8) b.strength - (int8) a.strength;
        }
    }
}

