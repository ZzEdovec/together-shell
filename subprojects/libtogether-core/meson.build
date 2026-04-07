project('together-core',
	['c', 'vala',],
	version: '0.1',
	meson_version: '>= 1.0.0',
	default_options: ['warning_level=2', 'werror=false',])

name = meson.project_name()
version = meson.project_version()
api_version = '0.1'

subdir('src')

libtogether_core_dep = declare_dependency(
	link_with: lib,
	dependencies: lib_deps,
)