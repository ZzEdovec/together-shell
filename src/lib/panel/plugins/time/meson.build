time_sources = [
	'time.vala',
]

time_plugin = shared_library(
	'togethershell-panel-plugin-time',
	time_sources,
	dependencies: [
		libtogethershell_dep,
	],
	install: true,
	install_dir: get_option ('libdir') / 'together-shell' / 'plugins'
)
