-- 1. init spaces by creating migration
-- spacer:makemigration('init_spaces')
-- 2. apply migration by
-- spacer:migrate_up()
spacer:space {
	name = 'myspace',
	format = {
		{ name = 'id',       type = 'string' },
		{ name = 'name',     type = 'string' },
	},
	indexes = {
		{ name = 'primary', type = 'tree', unique = true,  parts = { 'id' } },
	},
}
