window_list_sources = [
	'window-list.vala',
]

window_list_plugin = shared_library(
	'togethershell-panel-plugin-windowlist',
	window_list_sources,
	dependencies: deps, # TODO
	install: true,
	install_dir: get_option ('libdir') / 'together-shell' / 'plugins'
)

install_data('window-list.plugin', install_dir: get_option ('libdir') / 'together-shell' / 'plugins')