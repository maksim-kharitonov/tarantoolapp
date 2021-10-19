require 'schema'

local log    = require 'log'
local config = require 'config'
local M = {}

M.api = require 'api'
M.graphite = require 'net.graphite'(config.get('app.graphite'))

function M.start()
    require 'indexpiration'( box.space.tokens, {
        -- debug = true,
        field   = 'etime',
        kind = 'time',
        on_delete = function(tuple)
            log.info('[-] Expired session %s to file %s for %s',
                tuple.token, tuple.fileid, tuple.email)
        end
    } )

    require 'lock_expiration'.start()
end

return M
