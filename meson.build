project('together-shell', ['c', 'vala'],
          version: '0.1.0',
    meson_version: '>= 1.0.0',
  default_options: [ 'warning_level=2', 'werror=false', ],
)

i18n = import('i18n')
gnome = import('gnome')
valac = meson.get_compiler('vala')


srcdir = meson.project_source_root() / 'src'

config_h = configuration_data()
config_h.set_quoted('PACKAGE_VERSION', meson.project_version ())
config_h.set_quoted('GETTEXT_PACKAGE', 'together-shell')
config_h.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_h.set_quoted('PLUGINS_DIR', get_option('prefix') / get_option('libdir'))
config_h.set_quoted('VERSION', '0.1')
configure_file(output: 'config.h', configuration: config_h)

config_dep = valac.find_library ('config', dirs: srcdir)
config_inc = include_directories('.')

add_project_arguments('-DGETTEXT_PACKAGE="' + meson.project_name () + '"', language: 'c')

#subdir('subprojects/libtogether-shell-plugin-api')
#subdir('subprojects/libtogether-wayfire')
#subdir('subprojects/libtogether-wayland')
#wayfire_dep = libtogether_wayfire_dep
#wayland_dep = libtogether_wayland_dep
#api_dep = libtogether_api_dep

wayland_dep = dependency('together-wayland-0.1', fallback: ['libtogether-wayland', 'libtogether_wayland_dep'])
core_dep = dependency('together-core-0.1', fallback: ['libtogether-core', 'libtogether_core_dep'])

subdir('data')
subdir('src')
subdir('po')

gnome.post_install(
     glib_compile_schemas: true,
)
