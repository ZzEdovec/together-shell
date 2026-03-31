namespace ControlCenterPlugin {
    [GtkTemplate (ui = "/com/github/ZzEdovec/togethershell/panel/controlcenter/connection_page.ui")]
    public abstract class ConnectionPage : Adw.Bin {
        [GtkChild]
        protected unowned Adw.ToastOverlay toast_overlay;
        [GtkChild]
        protected unowned Adw.PreferencesGroup available_connections_group;
        [GtkChild]
        protected unowned Gtk.ListBox available_connections_list;
        [GtkChild]
        protected unowned Adw.SwitchRow connection_switch;

        private string _connection_type;
        protected string connection_type {
            get { return _connection_type; }
            set {
                _connection_type = value;
                connection_switch.title = _("Enable %s").printf (value);
            }
        }
    }

    public enum ConnectionStatus {
        CONNECTED,
        KNOWN,
        PASSWORD,
        NOPASSWORD,
        PROCESSING
    }

    public enum ConnectionAction {
        CONNECT,
        DISCONNECT,
        REMOVE
    }

    public sealed class ConnectionRow : Adw.ExpanderRow {
        private Gee.ArrayList<Adw.PreferencesRow> rows = new Gee.ArrayList<Adw.PreferencesRow> ();
        private ConnectionStatus _connection_status;
        public ConnectionStatus connection_status {
            get { return _connection_status; }
            set {
                if (value != _connection_status) {
                    _connection_status = value;

                    clear_childs ();
                    upset_status ();
                    if (value != ConnectionStatus.PROCESSING)
                        build_childs ();
                }
            }
        }

        public signal void selected (ConnectionAction action, string? password = null);

        public ConnectionRow (ConnectionStatus status) {
            _connection_status = status;

            upset_status ();
            build_childs ();
        }

        public override void dispose () {
            clear_childs ();
            base.dispose ();
        }

        private void upset_status () {
            switch (_connection_status) {
                case (ConnectionStatus.CONNECTED):
                    subtitle = _("Connected");
                break;
                case (ConnectionStatus.KNOWN):
                    subtitle = _("Saved");
                break;
                case (ConnectionStatus.NOPASSWORD):
                    subtitle = _("No password required");
                break;
                case (ConnectionStatus.PASSWORD):
                    subtitle = _("Requires password");
                break;
                case (ConnectionStatus.PROCESSING):
                    subtitle = _("Connecting");
                break;
            }
        }

        private void build_childs () {
            if (_connection_status == ConnectionStatus.PASSWORD) {
                subtitle = _("Requires password");

                var password_row = new Adw.PasswordEntryRow ();
                password_row.show_apply_button = true;
                password_row.title = _("Password");
                ulong pass_id = password_row.apply.connect (() => {
                    if (password_row.text.length < 8)
                        password_row.css_classes = { "error" };
                    else {
                        password_row.css_classes = {};
                        selected (ConnectionAction.CONNECT, password_row.text);
                    }
                });
                password_row.set_data<ulong> ("signal", pass_id);

                this.add_row (password_row);
                rows.add (password_row);
            }
            else {
                var connect_row = new Adw.ActionRow ();
                connect_row.activatable = true;
                connect_row.title = _(_connection_status == ConnectionStatus.CONNECTED ? "Disconnect" : "Connect");
                ulong conn_id = connect_row.activated.connect (() => { selected (_connection_status == ConnectionStatus.CONNECTED ? ConnectionAction.DISCONNECT : ConnectionAction.CONNECT); });
                connect_row.set_data<ulong> ("signal", conn_id);

                this.add_row (connect_row);
                rows.add (connect_row);

                if (_connection_status != ConnectionStatus.NOPASSWORD) {
                    var forget_row = new Adw.ActionRow ();
                    forget_row.activatable = true;
                    forget_row.title = _("Forget");
                    ulong forg_id = forget_row.activated.connect (() => { selected (ConnectionAction.REMOVE); });
                    forget_row.set_data<ulong> ("signal", forg_id);

                    this.add_row (forget_row);
                    rows.add (forget_row);
                }
            }
        }

        public void clear_childs () {
            foreach (var row in rows) {
                ulong signal_id = row.get_data<ulong> ("signal");
                row.disconnect (signal_id);
                this.remove (row);
            }

            rows.clear ();
        }
    }
}
