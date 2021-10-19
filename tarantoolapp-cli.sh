#!/bin/bash

##### Functions
start()
{
	tarantoolctl start tarantoolapp_001
	tarantoolctl start tarantoolapp_002
}

reload()
{
	tarantoolctl enter tarantoolapp_001 <<< 'package.reload()'
	tarantoolctl enter tarantoolapp_002 <<< 'package.reload()'

}

stop()
{
	tarantoolctl stop tarantoolapp_001
	tarantoolctl stop tarantoolapp_002
}

logs()
{
	tail -n1 -f data/*.log
}

dep()
{
	LUAROCKS_CONFIG=.luarocks-config luarocks --lua-version 5.1 --tree=./libs install --only-deps rockspecs/tarantoolapp-scm-1.rockspec
}

build()
{
	rpmbuild -ba --define "SRC_DIR ${PWD}" rpm/tarantoolapp.spec
}

usage()
{
	echo "Usage: $0 [run|build|help|dep]"
}

##### Main
case "$1" in
	'start' )
		start
		exit
		;;
	'reload' )
		reload
		exit
		;;
	'stop' )
		stop
		exit
		;;
	'logs' )
		logs
		exit
		;;
	'dep' )
		dep
		;;
	'build' )
		build
		;;
	'help' )
		usage
		exit
		;;
	* )
		usage
		exit 1
esac
