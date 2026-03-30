[CCode (cheader_filename = "wayland-client.h")]
namespace Wl {
    [CCode (cname = "wl_seat_interface")]
    public static extern Wl.Interface seat_interface;

    [CCode (cname = "wl_output_interface")]
    public static extern Wl.Interface output_interface;
}

