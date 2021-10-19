#!/usr/bin/env tarantool

-- LUAROCKS_CONFIG=.luarocks-config luarocks install lua-etcd --local
local argparse = require 'argparse'()
	:name "bootstrap"
	:description "Inititalizes ETCD cluster with yaml config"
	:add_help_command()
	:help_vertical_space(1)
	:help_description_margin(40)

local bootstrap = argparse
	:command "bootstrap"
	:summary "Upload cluster config to ETCD cluster"

bootstrap:option "-e" "--endpoint"
	:description "Url to ETCD cluster"
	:default "http://127.0.0.1:2379"

bootstrap:option "-r" "--root"
	:description "Prefix inside ETCD tree which will be "
	:default "/"

bootstrap:argument "config"
	:description "Path to yaml configuration of the cluster"

local args = argparse:parse()

local etcd = require 'etcd'.new {
	endpoints = { args.endpoint },
	prefix = args.root,
}

etcd:connect()
etcd.endpoints[1] = args.endpoint

local yaml = require 'yaml'
local cfg = assert(yaml.decode(assert(assert(io.open(args.config, "r")):read "*all")))
require 'log'.info("Uploading config: \n%s", yaml.encode(cfg))

etcd:rm(args.root .. "/", { recursive = true })
etcd:fill(args.root.."/", cfg)
