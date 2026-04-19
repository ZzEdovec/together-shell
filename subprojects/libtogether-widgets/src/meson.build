deps = [
	dependency('libadwaita-1'),
	dependency('gtk4-wayland'),
	dependency('gee-0.8'),
]

lib_deps = [
	dependency('libadwaita-1'),
	dependency('gtk4-wayland'),
]

sources = [
	'draggable-area.vala',
	'panel-popup.vala',
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
	description: 'Together Widgets library',
	subdirs: name,
	requires: lib_deps,
	install_dir: get_option('libdir') / 'pkgconfig',
)

libtogether_widgets_dep = declare_dependency(
	link_with: lib,
	dependencies: lib_deps,
	include_directories: include_directories('.'),
)