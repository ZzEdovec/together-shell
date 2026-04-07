config = configure_file (
	input: 'config.vala.in',
	output: 'config.vala',
	configuration : {
		'LIBDIR': get_option('prefix') / get_option('libdir'),
	}
)

config_dep = declare_dependency(
	sources: [config]
)

deps = [
	dependency('gio-unix-2.0'),
	dependency('gee-0.8'),
	dependency('gtk4'),
	dependency('libadwaita-1'),
	dependency('libpeas-2'),
	config_dep,
]

lib_deps = [
	dependency('gio-unix-2.0'),
	dependency('gee-0.8'),
	dependency('gtk4'),
	dependency('libadwaita-1'),
	dependency('libpeas-2'),
]

sources = [
	'interfaces/shell/plugin-interface.vala',
	'managers/appinfo-manager.vala',
	'managers/plugins-manager.vala',
	'settings/shell.vala',
]

lib = library(
	name,
	sources,
	dependencies: deps,
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
	description: 'Together Core library',
	subdirs: name,
	requires: lib_deps,
	install_dir: get_option('libdir') / 'pkgconfig',
)