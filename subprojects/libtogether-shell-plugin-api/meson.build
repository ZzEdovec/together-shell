project('together-plugin-api',
	['c', 'vala',],
	version: '0.1',
	meson_version: '>= 1.0.0',
	default_options: ['warning_level=2', 'werror=false',])

name = meson.project_name()
version = meson.project_version()
api_version = '0.1'

deps = [
	dependency('gtk4'),
	dependency('libadwaita-1'),
	dependency('libpeas-2'),
]

lib = library(
	name,
	['src/plugin-interface.vala'],
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
	description: 'Together Shell Plugin API',
	subdirs: name,
	requires: deps,
	install_dir: get_option('libdir') / 'pkgconfig',
)

libtogether_api_dep = declare_dependency(
	link_with: lib,
	include_directories: include_directories('src'),
)
