appmenu_sources = [
	'appmenu.vala'
]

subdir('data')

appmenu_plugin = shared_library(
	'togethershell-panel-plugin-appmenu',
	appmenu_sources,
	dependencies: [
		libtogethershell_dep,
		dependency('gtk4'),
		dependency('libadwaita-1', version: '>= 1.4'),
	],
	install: true,
	install_dir: get_option ('libdir') / 'together-shell' / 'plugins'
)
