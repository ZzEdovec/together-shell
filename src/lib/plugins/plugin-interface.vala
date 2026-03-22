/**
 * [!] INTERNAL TOGETHER SHELL USE ONLY
 *
 * This file is part of the core shared library (libtogethershell) and defines the ABI
 * for the Together Shell ecosystem.
 *
 * IMPORTANT FOR PLUGIN DEVELOPERS:
 * 1. You MUST implement the 'Plugin' interface in your code.
 * 2. You MUST export a function named 'register_plugin' using the
 * RegisterPlugin delegate signature.
 * 3. DO NOT implement or subclass internal interfaces (like AbstractPanel);
 * these are provided by the Shell at runtime.
 */

namespace TogetherShell {
    // ------------ Plugin Implementation (Implement these in your plugin) ------------

    public interface Plugin : Object {
        public abstract string get_name ();
        public abstract string get_desc ();
        public abstract Gtk.Widget? get_panel_widget ();
        public abstract Gtk.Popover? get_showable_widget ();
        public abstract bool unregister ();
    }

    /**
     * Entry point for the plugin.
     * Your implementation MUST be decorated with [CCode (cname = "register_plugin")]
     */
    public delegate Plugin register_plugin (Panel? panel);
}
