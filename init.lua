#!/usr/bin/env tarantool

require'strict'.on()
local fiber = require 'fiber'
local under_tarantoolctl = fiber.name() == 'tarantoolctl'

local fio = require('fio');
local luaroot = debug.getinfo(1,"S")
local source  = fio.abspath(luaroot.source:match('^@(.+)'));
local symlink = fio.readlink(source);
local script_path = (symlink and fio.abspath(symlink) or source):match("^(.*/)")
local appname = script_path:match("^.*/([^/]+)/")
local instance_name = (function()
	if symlink then
		return (source:match("/([^/]+)$"):gsub('%.lua$',''))
	else
		return (source:gsub('/init%.lua$',''):match('/([^/]+)$'))
	end
end)()
rawset(_G,'who',string.format("%s#%s",appname,instance_name))

print(string.format("Starting app %s, instance %s", appname, instance_name))

local function single_config_path()
	local env_conf = os.getenv('CONF')
	if env_conf then return env_conf end

	if ( symlink and source:match('^/etc/') ) or source:match('^/usr/') then
		-- system wide. /etc/{appname}/conf.lua
		return string.format("/etc/%s/conf.lua", appname)
	else
		-- local user
		return string.format("%s/etc/conf.lua", script_path)
	end
end

-- luacheck: ignore
local function addpaths(dst,...) local cwd = script_path; local pp = {}; for s in package[dst]:gmatch("([^;]+)") do pp[s] = 1 end; local add = ''; for _, p in ipairs({...}) do if not pp[cwd..p] then add = add..cwd..p..';'; end end;package[dst]=add..package[dst];return end
addpaths('path',
	'?.lua', '?/init.lua',
	'app/?.lua', 'app/?/init.lua',
	'libs/share/lua/5.1/?.lua', 'libs/share/lua/5.1/?/init.lua')

addpaths('cpath', 'libs/lib/lua/5.1/?.so', 'libs/lib/lua/?.so', 'libs/lib64/lua/5.1/?.so')

require 'package.reload'
require 'kit'

require 'config' {
	instance_name = instance_name,
	-- file          = config_path(),
	file          = single_config_path(),
	on_load       = function(_,cfg)
		if cfg.box.background ~= nil and not cfg.box.background and under_tarantoolctl then
			cfg.box.background = true
		end
	end;
	mkdir         = true,
	master_selection_policy = 'etcd.cluster.master',
}
local spacer = require 'spacer'.new {
	migrations = script_path .. "app/migrations",
}
rawset(_G, 'spacer', spacer)

box.once('access:v1', function()
	box.schema.user.grant('guest', 'read,write,execute', 'universe')
	spacer:migrate_up()
end)

local app = require(appname)
rawset(_G, appname, app )
if type(app) == 'table' then
	if app.destroy then
		package.reload:register(app)
	end
	if app.start then
		app.start(require('config').get('app'))
	end
end

if not os.getenv("NO_CONSOLE") and not box.cfg.background and not under_tarantoolctl and package.reload.count == 1 then
	require 'log'.info("Running console")
	require('console').start()
	os.exit(0)
end
