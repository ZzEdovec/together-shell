/**
 * Complete Vala bindings for wlr-foreign-toplevel-management-unstable-v1
 * (c) Kai Neumann (ZzEdovec), 2026
 */

[CCode (cheader_filename = "wlr-foreign-toplevel-management-unstable-v1.h")]
namespace Zwlr {
    [CCode (cname = "zwlr_foreign_toplevel_manager_v1_interface")]
    public static extern Wl.Interface foreign_toplevel_manager_v1_interface;

    [CCode (cname = "struct zwlr_foreign_toplevel_manager_v1", free_function = "zwlr_foreign_toplevel_manager_v1_destroy")]
    [Compact]
    public class ForeignToplevelManagerV1 : Wl.Proxy {
        [CCode (cname = "zwlr_foreign_toplevel_manager_v1_stop")]
        public void stop ();

        [CCode (cname = "zwlr_foreign_toplevel_manager_v1_add_listener")]
        public int add_listener (ForeignToplevelManagerV1Listener listener, void* data = null);

        [CCode (cname = "zwlr_foreign_toplevel_manager_v1_set_user_data")]
        public void set_user_data (void* user_data);

        [CCode (cname = "zwlr_foreign_toplevel_manager_v1_get_user_data")]
        public void* get_user_data ();

        [CCode (cname = "zwlr_foreign_toplevel_manager_v1_get_version")]
        public uint32 get_version ();
    }

    [CCode (cname = "struct zwlr_foreign_toplevel_manager_v1_listener", has_type_id = false)]
    public struct ForeignToplevelManagerV1Listener {
        [CCode (cname = "toplevel")]
        public unowned ManagerToplevelFunc? toplevel;

        [CCode (cname = "finished")]
        public unowned ManagerFinishedFunc? finished;
    }

    [CCode (has_target = false)]
    public delegate void ManagerToplevelFunc(void* data,
                                            ForeignToplevelManagerV1 manager,
                                            ForeignToplevelHandleV1 toplevel);

    [CCode (has_target = false)]
    public delegate void ManagerFinishedFunc(void* data,
                                            ForeignToplevelManagerV1 manager);

    [CCode (cname = "struct zwlr_foreign_toplevel_handle_v1", free_function = "zwlr_foreign_toplevel_handle_v1_destroy")]
    [Compact]
    public class ForeignToplevelHandleV1 : Wl.Proxy {
        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_set_maximized")]
        public void set_maximized();

        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_unset_maximized")]
        public void unset_maximized();

        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_set_minimized")]
        public void set_minimized();

        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_unset_minimized")]
        public void unset_minimized();

        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_activate")]
        public void activate(Wl.Seat seat);

        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_close")]
        public void close();

        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_destroy")]
        [DestroysInstance]
        public void destroy(); // Taken out separately, because most likely you will not be able to own the handle (only unowned), which is why vala will not call free_function on its own.

        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_set_rectangle")]
        public void set_rectangle(Wl.Surface surface, int32 x, int32 y, int32 width, int32 height);

        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_set_fullscreen")]
        public void set_fullscreen(Wl.Output? output);

        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_unset_fullscreen")]
        public void unset_fullscreen();

        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_add_listener")]
        public int add_listener(ForeignToplevelHandleV1Listener listener, void* data = null);

        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_set_user_data")]
        public void set_user_data(void* user_data);

        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_get_user_data")]
        public void* get_user_data();

        [CCode (cname = "zwlr_foreign_toplevel_handle_v1_get_version")]
        public uint32 get_version();
    }

    [CCode (cname = "struct zwlr_foreign_toplevel_handle_v1_listener", has_type_id = false)]
    public struct ForeignToplevelHandleV1Listener {
        [CCode (cname = "title")]
        public unowned HandleTitleFunc? title;

        [CCode (cname = "app_id")]
        public unowned HandleAppIdFunc? app_id;

        [CCode (cname = "output_enter")]
        public unowned HandleOutputEnterFunc? output_enter;

        [CCode (cname = "output_leave")]
        public unowned HandleOutputLeaveFunc? output_leave;

        [CCode (cname = "state")]
        public unowned HandleStateFunc? state;

        [CCode (cname = "done")]
        public unowned HandleDoneFunc? done;

        [CCode (cname = "closed")]
        public unowned HandleClosedFunc? closed;

        [CCode (cname = "parent")]
        public unowned HandleParentFunc? parent;
    }

    [CCode (has_target = false)]
    public delegate void HandleTitleFunc(void* data,
                                        ForeignToplevelHandleV1 handle,
                                        string title);

    [CCode (has_target = false)]
    public delegate void HandleAppIdFunc(void* data,
                                        ForeignToplevelHandleV1 handle,
                                        string app_id);

    [CCode (has_target = false)]
    public delegate void HandleOutputEnterFunc(void* data,
                                              ForeignToplevelHandleV1 handle,
                                              Wl.Output output);

    [CCode (has_target = false)]
    public delegate void HandleOutputLeaveFunc(void* data,
                                              ForeignToplevelHandleV1 handle,
                                              Wl.Output output);

    [CCode (has_target = false)]
    public delegate void HandleStateFunc(void* data,
                                        ForeignToplevelHandleV1 handle,
                                        Wl.Array state);

    [CCode (has_target = false)]
    public delegate void HandleDoneFunc(void* data,
                                       ForeignToplevelHandleV1 handle);

    [CCode (has_target = false)]
    public delegate void HandleClosedFunc(void* data,
                                         ForeignToplevelHandleV1 handle);

    [CCode (has_target = false)]
    public delegate void HandleParentFunc(void* data,
                                         ForeignToplevelHandleV1 handle,
                                         ForeignToplevelHandleV1? parent);

    [CCode (cname = "enum zwlr_foreign_toplevel_handle_v1_state", cprefix = "ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_")]
    public enum ForeignToplevelHandleV1State {
        MAXIMIZED,
        MINIMIZED,
        ACTIVATED,
        FULLSCREEN
    }

    [CCode (cname = "enum zwlr_foreign_toplevel_handle_v1_error", cprefix = "ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_ERROR_")]
    public enum ForeignToplevelHandleV1Error {
        INVALID_RECTANGLE
    }
}



