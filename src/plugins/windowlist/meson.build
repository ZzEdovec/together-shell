window_list_sources = [
	'window-list.vala',
	'window-button.vala',
]

window_list_plugin = shared_library(
	'window-list',
	window_list_sources,
	dependencies: deps, # TODO
	install: true,
	install_dir: get_option ('libdir') / 'TogetherShell',
)

install_data('window-list.plugin', install_dir: get_option ('libdir') / 'TogetherShell')