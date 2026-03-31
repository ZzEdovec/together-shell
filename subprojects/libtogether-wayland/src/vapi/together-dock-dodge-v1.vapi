/**
 * Wayland protocol bindings for together-dock-dodge-v1
 * (c) Kai Neumann (ZzEdovec), 2026
 */

[CCode (cheader_filename = "together-dock-dodge-v1.h")]
namespace Tdd {

    // -------------------------------------------------------------------------
    // together_dock_dodge_manager_v1
    // -------------------------------------------------------------------------

    [CCode (cname = "struct together_dock_dodge_manager_v1", free_function = "together_dock_dodge_manager_v1_destroy")]
    [Compact]
    public class DockDodgeManagerV1 {
        [CCode (cname = "together_dock_dodge_manager_v1_interface")]
        public static extern Wl.Interface iface;

        /**
         * Register a wl_surface which should be monitored for obscuration.
         */
        [CCode (cname = "together_dock_dodge_manager_v1_get_dock_dodge_surface")]
        public DockDodgeSurfaceV1 get_dock_dodge_surface (Wl.Surface surface);

        [CCode (cname = "together_dock_dodge_manager_v1_destroy")]
        public void destroy ();

        [CCode (cname = "together_dock_dodge_manager_v1_set_user_data")]
        public void set_user_data (void* user_data);

        [CCode (cname = "together_dock_dodge_manager_v1_get_user_data")]
        public void* get_user_data ();

        [CCode (cname = "together_dock_dodge_manager_v1_get_version")]
        public uint32 get_version ();
    }

    // -------------------------------------------------------------------------
    // together_dock_dodge_surface_v1
    // -------------------------------------------------------------------------

    [CCode (cname = "enum together_dock_dodge_surface_v1_state", cprefix = "TOGETHER_DOCK_DODGE_SURFACE_V1_STATE_")]
    public enum DockDodgeSurfaceV1State {
        /** The surface is not obscured. */
        CLEAR,
        /** The surface is obscured by a window. */
        OBSCURED
    }

    [CCode (cname = "struct together_dock_dodge_surface_v1", free_function = "together_dock_dodge_surface_v1_destroy")]
    [Compact]
    public class DockDodgeSurfaceV1 {
        [CCode (cname = "together_dock_dodge_surface_v1_interface")]
        public static extern Wl.Interface iface;

        [CCode (cname = "together_dock_dodge_surface_v1_add_listener")]
        public int add_listener (ref DockDodgeSurfaceV1Listener listener, void* data = null);

        [CCode (cname = "together_dock_dodge_surface_v1_destroy")]
        public void destroy ();

        [CCode (cname = "together_dock_dodge_surface_v1_set_user_data")]
        public void set_user_data (void* user_data);

        [CCode (cname = "together_dock_dodge_surface_v1_get_user_data")]
        public void* get_user_data ();

        [CCode (cname = "together_dock_dodge_surface_v1_get_version")]
        public uint32 get_version ();
    }

    [CCode (cname = "struct together_dock_dodge_surface_v1_listener", has_type_id = false)]
    public struct DockDodgeSurfaceV1Listener {
        [CCode (cname = "obscured")]
        public unowned DockDodgeSurfaceV1ObscuredFunc? obscured;
    }

    /**
     * Sent whenever the compositor detects that the tracked surface became
     * obscured or unobscured.
     */
    [CCode (has_target = false)]
    public delegate void DockDodgeSurfaceV1ObscuredFunc (void* data,
                                                         DockDodgeSurfaceV1 surface,
                                                         DockDodgeSurfaceV1State state);
}
