public class TogetherShell.Background : Gtk.Window {
    Settings settings = new Settings ("com.github.ZzEdovec.TogetherShell");
    Gtk.Picture picture = new Gtk.Picture ();

    public Background (Gdk.Monitor monitor) {
        GtkLayerShell.init_for_window (this);
        GtkLayerShell.set_layer (this, GtkLayerShell.Layer.BACKGROUND);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);
        GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
        GtkLayerShell.set_monitor (this, monitor);
        GtkLayerShell.set_exclusive_zone (this, -1);

        child = picture;

        settings.changed["background-fit"].connect (set_fit);
        set_fit ();
    }

    public void set_background (Gdk.Texture? texture) {
        picture.paintable = texture;
    }

    private void set_fit () {
        switch (settings.get_string ("background-fit")) {
            case ("fill"):
                picture.content_fit = Gtk.ContentFit.FILL;
            break;
            case ("contain"):
                picture.content_fit = Gtk.ContentFit.CONTAIN;
            break;
            case ("cover"):
                picture.content_fit = Gtk.ContentFit.COVER;
            break;
            case ("scale-down"):
                picture.content_fit = Gtk.ContentFit.SCALE_DOWN;
            break;
        }
    }
}
