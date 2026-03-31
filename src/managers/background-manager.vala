[SingleInstance]
class TogetherShell.BackgroundManager : Object {
    private Gee.HashMap<Gdk.Monitor, Background> backgrounds = new Gee.HashMap<Gdk.Monitor, Background> ();
    private ListModel monitors = Gdk.Display.get_default ().get_monitors ();
    private Settings settings = new Settings ("com.github.ZzEdovec.TogetherShell");
    private Gdk.Texture? texture;

    public BackgroundManager () {
        if (texture != null)
            return;

        settings.changed["background"].connect (upset_texture);

        upset_texture ();
        add_monitors (monitors);

        monitors.items_changed.connect ((pos, removed, added) => {
            if (removed > 0)
                clear_monitors ();
            if (added > 0)
                add_monitors (monitors, pos, added);
        });
    }

    public override void dispose () {
        base.dispose ();

        foreach (var background in backgrounds.values)
            background.destroy ();

        backgrounds.clear ();
    }

    private void upset_texture () {
        try {
            texture = Gdk.Texture.from_filename (settings.get_string ("background"));
            foreach (var background in backgrounds.values)
                background.set_background (texture);
        } catch {}
    }

    private void add_monitors (ListModel monitors, uint pos = 0, uint added = 0) {
        uint end = added == 0 ? monitors.get_n_items () : pos + added;
        for (uint i = pos; i < end; i++) {
            var monitor = (Gdk.Monitor) monitors.get_item (i);
            add_monitor (monitor);
        }
    }

    private void add_monitor (Gdk.Monitor monitor) {
        var background = new Background (monitor);
        background.set_background (texture);

        backgrounds[monitor] = background;
        background.show ();
    }

    private void clear_monitors () {
        var to_remove = new Gee.ArrayList<Gdk.Monitor> ();

        foreach (var entry in backgrounds) {
            if (!entry.key.is_valid ()) {
                to_remove.add (entry.key);
                entry.value.destroy ();
            }
        }

        foreach (var monitor in to_remove)
            backgrounds.unset (monitor);
    }
}
