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

vapi_dir = meson.current_source_dir() / 'vapi'
vala_comp = meson.get_compiler('vala')

deps = [
	dependency('gio-2.0'),
	dependency('wayland-client'),
	dependency('gee-0.8'),
	dependency('gtk4'),
]

vala_deps = [
	vala_comp.find_library('wayfire-shell-unstable-v2', dirs: vapi_dir),
	vala_comp.find_library('wlr-foreign-toplevel-management-unstable-v1', dirs: vapi_dir),
	vala_comp.find_library('wayland-client', dirs: vapi_dir),
]

sources = [
	wlr_toplevel_code,
	wf_shell_code,
	wlr_toplevel_header,
	wf_shell_header,
	'outputs.vala',
	'registry.vala',
	'toplevel.vala',
	'wf-shell.vala',
]

lib = library(
	name,
	sources,
	dependencies: deps + vala_deps,
	vala_header: name + '-' + api_version + '.vapi',
	version: version,
	install: true,
	install_dir: [true, true, true],
)

import('pkgconfig').generate(
	lib,
	name: name,
	filebase: name + '-' + api_version,
	description: 'GLib Wayland client',
	version: version,
	subdirs: name,
	requires: deps,
	install_dir: get_option('libdir') / 'pkgconfig',
)

libtogether_wayland_dep = declare_dependency(
	link_with: lib,
	include_directories: include_directories('.'),
)