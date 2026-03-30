/**
 * Complete Vala bindings for wayfire-shell-unstable-v2
 * (c) Kai Neumann (ZzEdovec), 2026
 */

[CCode (cheader_filename = "wayfire-shell-unstable-v2.h")]
namespace Zwf {
    [CCode (cname = "zwf_shell_manager_v2_interface")]
    public static extern Wl.Interface shell_manager_v2_interface;

    [CCode (cname = "zwf_output_v2_interface")]
    public static extern Wl.Interface output_v2_interface;

    [CCode (cname = "zwf_hotspot_v2_interface")]
    public static extern Wl.Interface hotspot_v2_interface;

    [CCode (cname = "zwf_surface_v2_interface")]
    public static extern Wl.Interface surface_v2_interface;

    // -------------------------------------------------------------------------
    // zwf_shell_manager_v2
    // -------------------------------------------------------------------------

    [CCode (cname = "struct zwf_shell_manager_v2", free_function = "zwf_shell_manager_v2_destroy")]
    [Compact]
    public class ShellManagerV2 : Wl.Proxy {
        [CCode (cname = "zwf_shell_manager_v2_get_wf_output")]
        public OutputV2 get_wf_output (Wl.Output output);

        [CCode (cname = "zwf_shell_manager_v2_get_wf_surface")]
        public SurfaceV2 get_wf_surface (Wl.Surface surface);

        [CCode (cname = "zwf_shell_manager_v2_destroy")]
        [DestroysInstance]
        public void destroy ();

        [CCode (cname = "zwf_shell_manager_v2_set_user_data")]
        public void set_user_data (void* user_data);

        [CCode (cname = "zwf_shell_manager_v2_get_user_data")]
        public void* get_user_data ();

        [CCode (cname = "zwf_shell_manager_v2_get_version")]
        public uint32 get_version ();
    }

    // -------------------------------------------------------------------------
    // zwf_output_v2
    // -------------------------------------------------------------------------

    [CCode (cname = "enum zwf_output_v2_hotspot_edge", cprefix = "ZWF_OUTPUT_V2_HOTSPOT_EDGE_")]
    public enum OutputV2HotspotEdge {
        TOP,
        BOTTOM,
        LEFT,
        RIGHT
    }

    [CCode (cname = "struct zwf_output_v2", free_function = "zwf_output_v2_destroy")]
    [Compact]
    public class OutputV2 : Wl.Proxy {
        [CCode (cname = "zwf_output_v2_add_listener")]
        public int add_listener (OutputV2Listener listener, void* data = null);

        [CCode (cname = "zwf_output_v2_inhibit_output")]
        public void inhibit_output ();

        [CCode (cname = "zwf_output_v2_inhibit_output_done")]
        public void inhibit_output_done ();

        [CCode (cname = "zwf_output_v2_create_hotspot")]
        public HotspotV2 create_hotspot (uint32 hotspot, uint32 threshold, uint32 timeout);

        [CCode (cname = "zwf_output_v2_destroy")]
        [DestroysInstance]
        public void destroy ();

        [CCode (cname = "zwf_output_v2_set_user_data")]
        public void set_user_data (void* user_data);

        [CCode (cname = "zwf_output_v2_get_user_data")]
        public void* get_user_data ();

        [CCode (cname = "zwf_output_v2_get_version")]
        public uint32 get_version ();
    }

    [CCode (cname = "struct zwf_output_v2_listener", has_type_id = false)]
    public struct OutputV2Listener {
        [CCode (cname = "enter_fullscreen")]
        public unowned OutputV2EnterFullscreenFunc? enter_fullscreen;

        [CCode (cname = "leave_fullscreen")]
        public unowned OutputV2LeaveFullscreenFunc? leave_fullscreen;

        [CCode (cname = "toggle_menu")]
        public unowned OutputV2ToggleMenuFunc? toggle_menu;
    }

    [CCode (has_target = false)]
    public delegate void OutputV2EnterFullscreenFunc (void* data,
                                                      OutputV2 output);

    [CCode (has_target = false)]
    public delegate void OutputV2LeaveFullscreenFunc (void* data,
                                                      OutputV2 output);

    [CCode (has_target = false)]
    public delegate void OutputV2ToggleMenuFunc (void* data,
                                                 OutputV2 output);

    // -------------------------------------------------------------------------
    // zwf_hotspot_v2
    // -------------------------------------------------------------------------

    [CCode (cname = "struct zwf_hotspot_v2", free_function = "zwf_hotspot_v2_destroy")]
    [Compact]
    public class HotspotV2 : Wl.Proxy {
        [CCode (cname = "zwf_hotspot_v2_add_listener")]
        public int add_listener (HotspotV2Listener listener, void* data = null);

        [CCode (cname = "zwf_hotspot_v2_destroy")]
        [DestroysInstance]
        public void destroy ();

        [CCode (cname = "zwf_hotspot_v2_set_user_data")]
        public void set_user_data (void* user_data);

        [CCode (cname = "zwf_hotspot_v2_get_user_data")]
        public void* get_user_data ();

        [CCode (cname = "zwf_hotspot_v2_get_version")]
        public uint32 get_version ();
    }

    [CCode (cname = "struct zwf_hotspot_v2_listener", has_type_id = false)]
    public struct HotspotV2Listener {
        [CCode (cname = "enter")]
        public unowned HotspotV2EnterFunc? enter;

        [CCode (cname = "leave")]
        public unowned HotspotV2LeaveFunc? leave;
    }

    [CCode (has_target = false)]
    public delegate void HotspotV2EnterFunc (void* data,
                                             HotspotV2 hotspot);

    [CCode (has_target = false)]
    public delegate void HotspotV2LeaveFunc (void* data,
                                             HotspotV2 hotspot);

    // -------------------------------------------------------------------------
    // zwf_surface_v2
    // -------------------------------------------------------------------------

    [CCode (cname = "struct zwf_surface_v2", free_function = "zwf_surface_v2_destroy")]
    [Compact]
    public class SurfaceV2 : Wl.Proxy {
        [CCode (cname = "zwf_surface_v2_interactive_move")]
        public void interactive_move ();

        [CCode (cname = "zwf_surface_v2_destroy")]
        [DestroysInstance]
        public void destroy ();

        [CCode (cname = "zwf_surface_v2_set_user_data")]
        public void set_user_data (void* user_data);

        [CCode (cname = "zwf_surface_v2_get_user_data")]
        public void* get_user_data ();

        [CCode (cname = "zwf_surface_v2_get_version")]
        public uint32 get_version ();
    }
}
