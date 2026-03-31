namespace TrayPlugin {
    public class Tray : Gtk.Popover {
        public bool is_empty { get; private set; }

        private AstalTray.Tray tray = AstalTray.get_default ();
        private Gee.HashMap<string, Adw.PreferencesRow> rows = new Gee.HashMap<string, Adw.PreferencesRow> ();
        private Adw.PreferencesGroup preferences_group = new Adw.PreferencesGroup ();

        public Tray () {
            preferences_group.title = _("Background applications");
            preferences_group.margin_bottom = preferences_group.margin_end = preferences_group.margin_start = 15;
            preferences_group.margin_top = 3;

            var revealer = new Gtk.Revealer ();
            revealer.child = preferences_group;

            child = revealer;
            has_arrow = false;

            foreach (var item in tray.items)
                add_item (item);

            notify["visible"].connect (() => { if (!visible) {collapse_all ();} });
            tray.item_added.connect (add_item_by_id);
            tray.item_removed.connect (remove_item_by_id);
        }

        ~Tray () {print ("Remove tray\n");}

        private void add_item (AstalTray.TrayItem item) {
            if (item.id == null && item.menu_model == null && item.title == null && item.gicon == null)
                return;

            Adw.PreferencesRow row;
            if (item.menu_model != null) {
                row = new TrayExpanderRow (item);
                var expander_row = (TrayExpanderRow) row;

                expander_row.action_selected.connect ((obj) => {
                    collapse_all ();
                    popdown ();
                });
                expander_row.notify["expanded"].connect ((obj, pspec) => {
                    var ex_row = (TrayExpanderRow) obj; // if we pass expander_row directly, there will be a memory leak :)
                    if (ex_row.expanded)
                        collapse_all (ex_row);
                });
            }
            else {
                var image = new Gtk.Image ();

                row = new TrayActionRow ();
                var action_row = (TrayActionRow) row;
                action_row.activatable = true;
                action_row.item = item;
                action_row.add_prefix (image);

                item.bind_property ("title", action_row, "title", BindingFlags.SYNC_CREATE);
                item.bind_property ("gicon", image, "gicon", BindingFlags.SYNC_CREATE);
            }

            preferences_group.add (row);
            rows[item.item_id] = row;

            is_empty = false;
        }

        private void add_item_by_id (string id) {
            var item = tray.get_item (id);
            add_item (item);
        }

        private void remove_item_by_id (string id) {
            if (!rows.has_key (id))
                return;

            preferences_group.remove (rows[id]);
            rows.unset (id);

            is_empty = rows.is_empty;
        }

        private void collapse_all (TrayExpanderRow? except = null) {
            foreach (var row in rows.values) {
                var expander_row = row as TrayExpanderRow;
                if (expander_row != null && except != row)
                    expander_row.expanded = false;
            }
        }
    }

    public class TrayExpanderRow : Adw.ExpanderRow {
        private AstalTray.TrayItem item;
        private Gee.ArrayList<Adw.PreferencesRow> childs = new Gee.ArrayList<Adw.PreferencesRow> ();

        public signal void action_selected ();

        public TrayExpanderRow (AstalTray.TrayItem item) {
            this.item = item;

            var image = new Gtk.Image ();
            add_prefix (image);

            item.bind_property ("title", this, "title", BindingFlags.SYNC_CREATE);
            item.bind_property ("gicon", image, "gicon", BindingFlags.SYNC_CREATE);

            insert_action_group ("dbusmenu", item.action_group);

            notify["expanded"].connect (prepare_to_show); // override notify is bad idea, so connecting a signal..
        }

        ~TrayExpanderRow () {
            print ("Dispose.....\n");
        }

        private void prepare_to_show () {
            if (expanded == false)
                return;

            if (!childs.is_empty)
                clear_childs ();

            item.about_to_show ();
            generate_menu (item.menu_model);
        }

        public void clear_childs () {
            foreach (var child in childs)
                remove (child);

            childs.clear ();
        }

        private void generate_menu (MenuModel menu_model, Adw.ExpanderRow row = this) {
            for (int i = 0; i < menu_model.get_n_items (); i++) {
                var submenu = menu_model.get_item_link (i, Menu.LINK_SUBMENU);
                var section = menu_model.get_item_link (i, Menu.LINK_SECTION);
                if (submenu != null) {
                    var subrow = new Adw.ExpanderRow ();
                    generate_menu (submenu, subrow);

                    add_row (subrow);
                    childs.add (subrow);
                    continue;
                }
                if (section != null) {
                    generate_menu (section);
                    continue;
                }

                string? label = menu_model.get_item_attribute_value (i, Menu.ATTRIBUTE_LABEL, VariantType.STRING) as string;
                string? action = menu_model.get_item_attribute_value (i, Menu.ATTRIBUTE_ACTION, VariantType.STRING) as string;

                var action_row = new TrayActionRow.with_title (label);
                action_row.action_name = action;
                action_row.selected.connect (() => { action_selected (); });

                action_row.weak_ref (() => {print ("Destroy ActionRow\n");});

                row.add_row (action_row);
                if (row == this) { childs.add (action_row); }
            }
        }
    }

    public class TrayActionRow : Adw.ActionRow {
        private string? _action_name = null;
        public string? action_name {
            get { return _action_name; }
            set {
                activatable = value != null;
                _action_name = value;
            }
        }
        public AstalTray.TrayItem? item { get; set; }

        public signal void selected ();

        construct {
            activated.connect (() => {
                selected ();

                if (_action_name != null)
                    activate_action (_action_name, null);
                if (item != null)
                    item.activate (get_width () / 2, get_height () / 2);
            });
        }

        public TrayActionRow.with_title (string title) {
            this.title = title;
        }
    }
}
