wlr_toplevel_header = custom_target(
	'wlr-foreign-toplevel-management-unstable-v1-client-header',
	input: '/usr/share/wlr-protocols/unstable/wlr-foreign-toplevel-management-unstable-v1.xml',
	output: 'wlr-foreign-toplevel-management-unstable-v1.h',
	command: [
	'wayland-scanner',
	'client-header',
	'@INPUT@',
	'@OUTPUT@',
	],
)

wlr_toplevel_code = custom_target(
  'wlr-foreign-toplevel-management-unstable-v1-client-code',
  input: '/usr/share/wlr-protocols/unstable/wlr-foreign-toplevel-management-unstable-v1.xml',
  output: 'wlr-foreign-toplevel-management-unstable-v1.c',
  command: [
    'wayland-scanner',
    'public-code',
    '@INPUT@',
    '@OUTPUT@',
  ],
)

wf_shell_header = custom_target(
	'wayfire-shell-unstable-v2-client-header',
	input: '/usr/share/wayfire/protocols/unstable/wayfire-shell-unstable-v2.xml',
	output: 'wayfire-shell-unstable-v2.h',
	command: [
	'wayland-scanner',
	'client-header',
	'@INPUT@',
	'@OUTPUT@',
	],
)

wf_shell_code = custom_target(
	'wayfire-shell-unstable-v2-client-code',
	input: '/usr/share/wayfire/protocols/unstable/wayfire-shell-unstable-v2.xml',
	output: 'wayfire-shell-unstable-v2.c',
	command: [
	'wayland-scanner',
	'public-code',
	'@INPUT@',
	'@OUTPUT@',
	],
)

#tg_dodge_header = custom_target(
#	'together-dock-dodge-v1-client-header',
#	input: '/usr/share/wayfire/protocols/together-dock-dodge-v1.xml',
#	output: 'together-dock-dodge-v1.h',
#	command: [
#	'wayland-scanner',
#	'client-header',
#	'@INPUT@',
#	'@OUTPUT@',
#	],
#)

#wg_dodge_code = custom_target(
#	'together-dock-dodge-v1-client-code',
#	input: '/usr/share/wayfire/protocols/together-dock-dodge-v1.xml',
#	output: 'together-dock-dodge-v1.c',
#	command: [
#	'wayland-scanner',
#	'public-code',
#	'@INPUT@',
#	'@OUTPUT@',
#	],
#)

libtogethershell_deps = [
	dependency('gtk4'),
	dependency('json-glib-1.0'),
	dependency('gtk4-layer-shell-0'),
	dependency('gmodule-2.0'),
	dependency('libadwaita-1', version: '>= 1.4'),
	dependency('gee-0.8'),
	dependency('wayland-client'),
	dependency('gio-unix-2.0'),
	dependency('gtk4-wayland'),
	dependency('astal-wireplumber-0.1'),
	dependency('astal-mpris-0.1'),
	config_dep,
]

libtogethershell_sources += [
	'application.vala',
	'appinfo-manager.vala',
	'plugins/plugin-interface.vala',
	'plugins/plugin-loader.vala',
	'panel/panel.vala',
	'desktop/background.vala',
	'desktop/background-manager.vala',
	'wayland/vapi/wayland-client.vapi',
#	'wayland/vapi/together-dock-dodge-v1.vapi',
	'wayland/vapi/wlr-foreign-toplevel-management-unstable-v1.vapi',
	'wayland/vapi/wayfire-shell-unstable-v2.vapi',
	'wayland/outputs.vala',
	'wayland/registry.vala',
	'wayland/toplevel-management.vala',
	'wayland/wf-shell.vala',
	'wayfire/ipc.vala',
	'wayfire/command/bindings.vala',
	'shell_ui/level_popup.vala',
	'shell_ui/popups_manager.vala',
	'shell_ui/panel_popup.vala',
	wlr_toplevel_code,
	wf_shell_code,
#	wg_dodge_code,
]

libtogethershell_dep_sources = [
	wf_shell_header,
	wlr_toplevel_header,
#	tg_dodge_header,
	'wayland/vapi/wayland-client.vapi',
	'wayland/vapi/wlr-foreign-toplevel-management-unstable-v1.vapi',
	'wayland/vapi/together-dock-dodge-v1.vapi',
]

libtogethershell = shared_library(
	'togethershell',
	libtogethershell_sources,
	vala_args: ['--pkg','posix'],
	dependencies: libtogethershell_deps,
	include_directories: config_inc,
	install: true,
	install_dir: [
		get_option('libdir'),
		get_option('includedir'),
        get_option('datadir') / 'vala' / 'vapi'
    ]
)

libtogethershell_dep = declare_dependency(
	link_with: libtogethershell,
	include_directories: include_directories('.'),
	sources: libtogethershell_dep_sources,
	dependencies: libtogethershell_deps,
)

subdir('panel/plugins')