show_desktop_sources = [
	'show_desktop.vala',
]

show_desktop_plugin = shared_library(
	'togethershell-panel-plugin-showdesktop',
	show_desktop_sources,
	dependencies: [
		libtogethershell_dep,
	],
	install: true,
	install_dir: get_option ('libdir') / 'together-shell' / 'plugins'
)
