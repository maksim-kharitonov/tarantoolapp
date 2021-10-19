std = "luajit"
codes = true

read_globals = {
	-- Tarantool vars:
	"box",
	"tonumber64",

	-- spacer
	"spacer",
	"F",
	"T",

	package = {
		fields = {
			reload = {
				fields = {
					"count",
					"register",
				}
			}
		}
	},

	table = {
		fields = {
			deepcopy = {}
		}
	},

	string = {
		fields = {
			split = {}
		}
	},

	-- Defined in app/init.lua
	"tarantoolapp",

	-- Exported by package 'config'
	"config",
}

max_line_length = 200

ignore = {
	"212",
	"213",
}

local conf_rules = {
	read_globals = {
		"instance_name",
	},
	globals = {
		"box", "etcd",
	}
}

files["etc/*.lua"] = conf_rules
