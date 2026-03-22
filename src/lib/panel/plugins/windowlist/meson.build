window_list_sources = [
	'window_list.vala',
]

window_list_plugin = shared_library(
	'togethershell-panel-plugin-windowlist',
	window_list_sources,
	dependencies: [
		libtogethershell_dep,
	],
	install: true,
	install_dir: get_option ('libdir') / 'together-shell' / 'plugins'
)
