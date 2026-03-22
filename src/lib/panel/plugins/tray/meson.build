tray_plugin_sources = [
	'tray.vala',
	'tray_widgets.vala',
]

tray_plugin_deps = [
	dependency('astal-tray-0.1'),
]

tray_plugin = shared_library(
	'togethershell-panel-plugin-tray',
	tray_plugin_sources,
	dependencies: [
		tray_plugin_deps,
		libtogethershell_dep,
	],
	install: true,
	install_dir: get_option ('libdir') / 'together-shell' / 'plugins'
)
