deps = [
	dependency('gio-unix-2.0'),
	dependency('json-glib-1.0'),
	dependency('gee-0.8'),
]

sources = [
	'ipc.vala',
	'command/bindings.vala',
]

lib = library(
	name,
	sources,
	dependencies: deps + [meson.get_compiler('vala').find_library('posix'),],
	vala_header: name + '-' + api_version + '.vapi',
	version: version,
	install: true,
	install_dir: [true, true, true]
)

import('pkgconfig').generate(
	lib,
	name: name,
	filebase: name + '-' + api_version,
	version: version,
	description: 'WayfireIPC for GLib',
	subdirs: name,
	requires: deps,
	install_dir: get_option('libdir') / 'pkgconfig',
)