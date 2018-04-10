-- @Author  : Linsir (root@linsir.org)
-- @Link    : http://linsir.org

local cjson = require "cjson"
local ipip = require "resty.ipip.ipip"

local _M = {}
_M._VERSION = '0.0.2'

function _M.go()
    local ip_address = ngx.var.remote_addr
    -- local ip_address = '202.103.026.255'
    local success = function(data, token)
        if token then
            return cjson.encode({
                success = true,
                token = token,
                data = data
            })
        else
            return cjson.encode({
                success = true,
                ip = ip_address,
                data = data
            })
        end
    end

    local failure = function(err, token)
        if token then
            return cjson.encode({
                success = false,
                token = token,
                data = data
            })
        else
            return cjson.encode({
                success = false,
                ip = ip_address,
                data = data
            })
        end
    end
    
    local opts = {
        path = '/usr/local/openresty/site/lualib/resty/ipip/data/17monipdb.datx',
        token = '0c9cb5a116e69b156550b9590bb2920dc66b1a2a',
        timeout  = '2000',
    }
    local ipipc = ipip:new(opts)
    -- local data, err = ipipc:query_file(ip_address)
    -- local data, err = ipipc:query_free_api(ip_address)
    local data, err = ipipc:query_api(ip_address)
    -- local data, err = ipipc:api_status()
    -- local token = "0c9cb5a116e69b156550b9590bb2920dc66b1a2a"
    -- local data, err = ipipc:api_status(token)

    ngx.log(ngx.INFO, "sss:", data)
    if not data then
        ngx.say(failure(err, token))
        return
    end
    ngx.say(success(data, token))
end

return _M
