--- This is API of this Tarantool
local ctx_t  = require 'ctx'
local ffi    = require 'ffi'
local clock  = require 'clock'
local json   = require 'json'
local File   = require 'File'
local Token  = require 'Token'
local Discovery  = require 'Discovery'
local Proof  = require 'Proof'

-- Simplieset routing:
local api = {}

local function validate(args, schema)
	assert(type(schema) == 'table', "schema must be a table")

	if type(args) ~= 'table' then
		return false, 400, { error = "ARGUMENTS/REQUIRED" }
	end

	for field, opts in pairs(schema) do
		if opts.optional and args[field] == nil then
			goto continue
		end

		if args[field] == nil then
			return false, 400, { error = "ARGUMENTS/REQUIRED", fields = { field } }
		end

		if opts.type and type(args[field]) ~= opts.type then
			return false, 400, { error = "ARGUMENTS/INVALID", fields = { field } }
		end

		::continue::
	end

	return true
end

-- @brief API method `example`
-- @param args.say
-- @return 200, { }
function api.example(ctx, args)
	local ok, status, body = validate(args, {
		say = { type = "string" },
	})
	if not ok then
		return status, body
	end

	return 200, { answer = args.say }
end

local default_headers = {
	["Content-Type"] = "application/json",
}

local function traceback(err)
	local trace = debug.traceback()

	if ffi.istype('struct error', err) then
		return {
			error = err,
			trace = trace,
		}
	end

	if type(err) ~= 'table' then
		return {
			error = box.error.new(box.error.PROC_LUA, tostring(err)),
			trace = trace,
		}
	end

	local message = err.message or "INTERNAL"
	return {
		error = box.error.new(box.error.PROC_LUA, message),
		trace = trace,
	}
end

local function finalize(ctx, pcall_ok, ...)
	local status, body, headers

	local elapsed = clock.time() - ctx.started
	if not pcall_ok then
		local err = ...

		ctx.log:error("Execution of '%s' raised an error: %s", ctx.method, err.error)
		for msg in err.trace:gmatch('([^\n]+)') do
			ctx.log:error("trace: %s", msg)
		end

		-- @TODO: add verbose checks for errors here
		-- to support exceptions?
		status, body = 500, { error = "INTERNAL" }
	else
		status, body, headers = ...
	end

	tarantoolapp.graphite:send(("res.api.%s.%s"):format(ctx.method, status), elapsed)

	ctx.log:info("[END=%s] %s finished in %.4f", status, ctx.method, elapsed)
	return status, body, headers or default_headers
end

for method, func in pairs(api) do
	api[method] = function(args)
		if type(args) ~= 'table' then
			return 400, { error = "ARGUMENTS/NOT_OBJECT" }, default_headers
		end

		local started = clock.time()
		local reqid = args.reqid or args.x_req_id or args["x-req-id"] or args.id
		local ctx = ctx_t(reqid)
		ctx.started = started
		ctx.method = method
		ctx.args = args
		ctx.log.store = nil

		ctx.log:info("Calling '%s' with %s", method, json.encode(args))

		ctx:suffix(("<%s:%s>"):format(args.email, args.uid))

		return finalize(ctx, xpcall(func, traceback, ctx, args))
	end
end

return api
