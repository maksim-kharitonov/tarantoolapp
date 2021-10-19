package = "tarantoolapp"
version = "scm-1"
source = {
	url = "git+ssh://git@gitlab.corp.mail.ru:tarantool/tarantoolapp.git",
}
description = {
	homepage = "https://gitlab.corp.mail.ru/tarantool/tarantoolapp",
	license = "Proprietary",
}
dependencies = {
	"kit scm-2",
	"config scm-4",
	"package-reload scm-1",

	"spacer scm-3",

	"moonwalker scm-1",
	"net-graphite",

	"ctx",
}
build = {
	type = "builtin",
	modules = {
	}
}
