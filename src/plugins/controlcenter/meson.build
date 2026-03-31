control_center_sources = [
	'control_center.vala',
	'pages/connection_page.vala',
	'pages/sound_page.vala',
	'pages/wireless_page.vala',
]

subdir('data')

control_center_deps = [
	dependency('astal-bluetooth-0.1'),
	dependency('astal-wireplumber-0.1'),
	dependency('astal-battery-0.1'),
	dependency('astal-network-0.1'),
	dependency('libnm'), # astal-network moment
]

control_center_plugin = shared_library(
	'togethershell-panel-plugin-controlcenter',
	control_center_sources,
	dependencies: [
		control_center_deps,
		libtogethershell_dep,
	],
	install: true,
	install_dir: get_option ('libdir') / 'together-shell' / 'plugins'
)
