subdir('lib')

together_shell_deps = [
	libtogethershell_dep,
	config_dep,
]

executable('together-shell',
	'main.vala',
	dependencies: together_shell_deps,
	include_directories: config_inc,
	install: true,
)
