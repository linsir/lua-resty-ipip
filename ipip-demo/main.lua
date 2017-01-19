-- @Author  : Linsir (root@linsir.org)
-- @Link    : http://linsir.org

local cjson = require "cjson"
local ipip = require "resty.ipip.ipip"

local _M = {}
_M._VERSION = '0.01'

function _M.go()
    -- local ip_address = ngx.var.remote_addr
    local ip_address = '202.103.026.255'
    local success = function(data)
        return cjson.encode({
            success = true,
            ip = ip_address,
            data = data
        })
    end

    local failure = function(err)
        return cjson.encode({
            success = false,
            ip = ip_address,
            error_msg = err
        })
    end

    local ipipc = ipip:new()
    -- local data, err = ipipc:query_free_api(ip_address)
    -- local data, err = ipipc:query_api(ip_address)
    local data, err = ipipc:query_file(ip_address)
    -- local data, err = ipipc:api_status("9a8bc1a059db4a14b4feb0f38db38bbf4d5353ab1")
    if not data then
        ngx.log(ngx.ERR, err)
        ngx.say(failure(err))
        return
    end
    ngx.say(success(data))
end

return _M
