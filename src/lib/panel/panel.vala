/**
 * TOGETHER SHELL CORE RUNTIME API
 *
 * This file defines objects managed exclusively by the Together Shell Core.
 *
 * FOR PLUGIN DEVELOPERS:
 * ACCESS: These objects are instantiated and managed by the Shell.
 * You receive them via provider methods.
 * LIFECYCLE: Do NOT attempt to create (new) instances of these classes.
 * Doing so will result in unlinked objects, memory corruption and Shell crash.
 */

public class TogetherShell.Panel : Gtk.Window {
    private string _panel_position;
    private Gee.HashMap<string, Plugin> plugins = new Gee.HashMap<string, Plugin> ();
    public Gtk.Box widgets_box { get; construct; }
    public string panel_position {
         get {return _panel_position;}
         set {
            set_anchor (value);
            _panel_position = value;
        }
    }

    public Panel (TogetherShell.Application application, Json.Object config) {
        Object (
            application: application,
            default_height: (int)config.get_int_member_with_default ("height", 48),
            widgets_box: new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0),
            opacity: config.get_double_member_with_default ("opacity", 0.8)
        );
        child = widgets_box;

        GtkLayerShell.init_for_window (this);
        GtkLayerShell.auto_exclusive_zone_enable (this);
        GtkLayerShell.set_layer (this, GtkLayerShell.Layer.TOP);
        GtkLayerShell.set_keyboard_mode (this, GtkLayerShell.KeyboardMode.ON_DEMAND);

        Json.Array? plugins;
        if ((plugins = config.get_array_member ("plugins")) != null && plugins.get_length () > 0)
            load_plugins (plugins);

        panel_position = config.get_string_member_with_default ("position", "bottom");
        Signal.emit_by_name (this, "notify::panel_position"); // we put a handler on popover plugins, but if we set a property in the Panel constructor, then the notify signal does not emit itself

        present ();
    }

    private void load_plugins (Json.Array plugins) {
        plugins.foreach_element ((array, index, element_node) => {
            var app = (TogetherShell.Application) application;
            var name = element_node.get_string ();
            var plugin = app.plugin_loader.load_plugin ("together-shell/plugins/%s".printf (name), this);

            if (plugin == null)
                return;

            Gtk.Popover? showable = plugin.get_showable_widget ();
            var visible = plugin.get_panel_widget ();

            if (visible is Gtk.MenuButton && showable != null) {
                var revealer = showable.child as Gtk.Revealer;
                var visible_button = (Gtk.MenuButton) visible;

                visible_button.css_classes = { "flat", "panel-button" };
                visible_button.popover = showable;
                visible_button.width_request = default_height;

                var popover_show_id = showable.show.connect (() => {
                    if (showable.get_data<bool> ("hide_in_progress"))
                        return;

                    revealer.reveal_child = true;
                    switch_menu_icon ((Gtk.MenuButton) visible);
                });
                var popover_hide_id = showable.hide.connect (() => {
                    if (showable.get_data<bool> ("hide_in_progress"))
                        return;

                    showable.visible = true; // Layer shell windows don't receive proper focus events, so we have to use workarounds
                    showable.set_data<bool> ("hide_in_progress", true);
                    revealer.reveal_child = false;


                    Timeout.add_once (revealer.transition_duration, () => {
                        showable.popdown ();
                        switch_menu_icon ((Gtk.MenuButton) visible);

                        showable.set_data<bool> ("hide_in_progress", false);
                    });
                });
                var orientation_signal_id = notify["panel_position"].connect (() => {
                    switch (panel_position) {
                        case ("bottom"):
                            showable.set_offset (0, -4);
                            revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
                        break;
                        case ("top"):
                            showable.set_offset (0, 4);
                            revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
                        break;
                        case ("left"):
                            showable.set_offset (4, 0);
                            revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
                        break;
                        case ("right"):
                            showable.set_offset (-4, 0);
                            revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
                        break;
                    }

                    switch_menu_icon ((Gtk.MenuButton) visible);
                });

                plugin.set_data<ulong> ("popover_show_id", popover_show_id);
                plugin.set_data<ulong> ("popover_hide_id", popover_hide_id);
                plugin.set_data<ulong> ("orientation_signal_id", orientation_signal_id);
            }

            widgets_box.append (visible);
            this.plugins[name] = plugin;
        });
    }

    private void switch_menu_icon (Gtk.MenuButton button) { // TODO Отдельный виджет кнопки и popover
        if (button.child != null || (button.icon_name != null && !button.icon_name.has_prefix ("pan-")) || button.popover == null)
            return;

        switch (panel_position) {
            case ("bottom"):
                button.icon_name = button.popover.visible ? "pan-down-symbolic" : "pan-up-symbolic";
            break;
            case ("top"):
                button.icon_name = button.popover.visible ? "pan-up-symbolic" : "pan-down-symbolic";
            break;
            case ("left"):
                button.icon_name = button.popover.visible ? "pan-start-symbolic" : "pan-end-symbolic";
            break;
            case ("right"):
                button.icon_name = button.popover.visible ? "pan-end-symbolic" : "pan-start-symbolic";
            break;
        }
    }

    private void set_anchor (string pos) {
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, false);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, false);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, false);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, false);

        switch (pos) {
            case "bottom":
                GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
                GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
                GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);

                this.widgets_box.orientation = Gtk.Orientation.HORIZONTAL;
            break;
            case "top":
                GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);
                GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
                GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);

                this.widgets_box.orientation = Gtk.Orientation.HORIZONTAL;
            break;
            case "left":
                GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
                GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
                GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);

                this.widgets_box.orientation = Gtk.Orientation.VERTICAL;
            break;
            case "right":
                GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
                GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);
                GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);

                this.widgets_box.orientation = Gtk.Orientation.VERTICAL;
            break;
        }
    }
}
