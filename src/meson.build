deps = [
	dependency('json-glib-1.0'),
	dependency('gtk4-layer-shell-0'),
	dependency('libpeas-2'),
	dependency('libadwaita-1', version: '>= 1.4'),
	dependency('gee-0.8'),
	dependency('gio-unix-2.0'),
	dependency('gtk4-wayland'),
	dependency('astal-wireplumber-0.1'),
	dependency('astal-mpris-0.1'),
	config_dep,
	wayland_dep,
	core_dep,
]

subdir ('plugins')

sources += [
	'application.vala',
	'managers/popups-manager.vala',
	'managers/background-manager.vala',
	'widgets/background.vala',
	'widgets/level-popup.vala',
	'widgets/panel-popup.vala',
	'widgets/panel.vala',
]

executable('together-shell',
	sources,
	dependencies: deps,
	include_directories: config_inc,
	install: true,
)
