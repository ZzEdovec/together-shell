project('together-core',
	['c', 'vala',],
	version: '0.1',
	meson_version: '>= 1.0.0',
	default_options: ['warning_level=2', 'werror=false',])

name = meson.project_name()
version = meson.project_version()
api_version = '0.1'

config_h = configuration_data()
config_h.set_quoted ('LIBDIR', get_option('prefix') / get_option('libdir'))
configure_file(output: 'config.h', configuration: config_h)

config_dep = meson.get_compiler('vala').find_library ('config', dirs: meson.project_source_root())
config_inc = include_directories('.')

subdir('src')

libtogether_core_dep = declare_dependency(
	link_with: lib,
	include_directories: config_inc,
	dependencies: deps,
)
