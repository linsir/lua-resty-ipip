-- @Author  : Linsir (root@linsir.org)
-- @Link    : http://linsir.org

local ngx = require('ngx')
local bit = require "bit"
local cjson = require "cjson"
local http = require "resty.http"

local setmetatable = setmetatable
local byte = string.byte
local match = string.match
local lshift = bit.lshift

--[[
    The 17mon dat file format in bytes:
        -----------
        | 4 bytes |                     <- offset number
        -----------------
        | 256 * 4 bytes |               <- first ip number index
        -----------------------
        | offset - 1028 bytes |         <- ip index
        -----------------------
        |    data  storage    |
        -----------------------
]]--

local _M = {}

local mt = { __index = _M }

_M._VERSION = '0.1.3'
-- local debug_log_level = "DEBUG"
local debug_log_level = "INFO"

local default_timeout = 600000
-- local headers = {
--     ["User-agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36"
-- }

local function _uint32(a, b, c, d)
    if not a or not b or not c or not d then
        return nil
    end

    local u = lshift(a, 24) + lshift(b, 16) + lshift(c, 8) + d
    if u < 0 then
        u = u + math.pow(2, 32)
    end
    return u
end

local function _split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

-- 返回数据模版
local data_template = {
    "country", -- // 国家
    "province", -- // 省会或直辖市（国内）
    "city", -- // 地区或城市 （国内）
    "org", -- // 学校或单位 （国内）
    "isp", -- // 运营商字段（只有购买了带有运营商版本的数据库才会有）
    "lat", -- // 纬度     （每日版本提供）
    "lng", -- // 经度     （每日版本提供）
    "time_zone", -- // 时区一, 可能不存在  （每日版本提供）
    "time_zone_2", -- // 时区二, 可能不存在  （每日版本提供）
    "china_code", -- // 中国行政区划代码    （每日版本提供）
    "phone_prefix", -- // 国际电话代码        （每日版本提供）
    "iso_2", -- // 国家二位代码        （每日版本提供）
    "continent", -- // 世界大洲代码        （每日版本提供）
    "is_idc", -- // 三合一版本提供
    "is_base_station" -- // 三合一版本提供
}

-- 用模版格式化数据
local function to_table(location)
    local r = {}
    for k, v in ipairs(location) do
        r[data_template[k]] = v
    end
    return r
end

-- 初始化
function _M.new(self, opts)

    local obj = {
        api_url = "https://ipapi.ipip.net/"
    }

    obj.token = opts.token or nil
    obj.timeout = opts.timeout or nil
    if opts.path then
        ngx.log(ngx[debug_log_level], "The data file path at: " .. opts.path)
        local file = io.open(opts.path)
        if file == nil then
            ngx.log(ngx.ERR, "The data file path not initialized")
            return nil, "IO error: the data file ."
        end
        local data = file:read("*all")
        obj.data = data
    else
        ngx.log(ngx.ERR, "The data file path not exsits")
    end

    return setmetatable(obj, mt)
end


-- 从文件获取 IP 信息
function _M.query_file(self, ip)

    local data = self.data
    local index_size = _uint32(byte(data, 1), byte(data, 2), byte(data, 3), byte(data, 4))

    local mid = 0
    local pos = 0
    local low = 0
    local high = (index_size - 262148 - 262144) / 9 - 1
    
    local pos1 = 0
    local suffix = 0 --- end 
    local prefix = 0 --- start
    ngx.log(ngx[debug_log_level], "ip: " .. ip)
    local ip1, ip2, ip3, ip4 = match(ip, "(%d+).(%d+).(%d+).(%d+)")
    local val = _uint32(ip1, ip2, ip3, ip4)
    
    while low <= high do
        mid = math.ceil((low + high) / 2)
        pos = mid * 9 + 262148
        if mid > 0 then
            pos1 = math.ceil(mid - 1) * 9 + 262148
            prefix = _uint32(
                byte(data, pos1+1),
                byte(data, pos1+2),
                byte(data, pos1+3),
                byte(data, pos1+4)
            )
        end
    
        suffix = _uint32(
            byte(data, pos + 1),
            byte(data, pos + 2),
            byte(data, pos + 3),
            byte(data, pos + 4)
        )
    
        if val < prefix then
            high = mid - 1
        elseif val > suffix then
            low = mid + 1        
        else
            off = _uint32(
                0,
                byte(data, pos + 7),
                byte(data, pos + 6),
                byte(data, pos + 5)
            )
            len = _uint32(
                0,
                0,
                byte(data, pos + 8),
                byte(data, pos + 9)
            )
            pos = off - 262144 + index_size
            
            loc = _split(string.sub(data, pos+1, pos+len), "\t")

            return to_table(loc)
        end 
    end
end

-- 通过 ipip.net API 获取 IP 信息
function _M.query_api(self, ip)

    local token = self.token

    local url = self.api_url .. "find?addr=" .. ip

    local headers = {
        ["Token"] = token
    }
    local httpc = http.new()
    local timeout = self.timeout or default_timeout
    httpc.set_timeout(timeout)

    local res, err = httpc:request_uri(url, {
            ssl_verify = ssl_verify or false,
            method = "GET",
            headers = headers
        })

    if not res then
        info = "failed to http request: " .. url .. " headers: " .. cjson.encode(headers) .." status: " .. res.status .. " body: " .. res.body
        ngx.log(ngx.ERR, info)
        return nil, err
    end

    if 200 ~= res.status then
        info = "failed to http request: " .. url .. " headers: " .. cjson.encode(headers) .." status: " .. res.status .. " body: " .. res.body
        ngx.log(ngx.ERR, info)
        return nil, res.status
    end

    local response = cjson.decode(res.body)

    ngx.log(ngx[debug_log_level], res.body)
    if response.data then
        return to_table(response.data)
    else
        -- if response.ret == "err" then
        return nil, response.msg
    end

end

-- 通过 ipip.net 免费的 API 获取 IP 信息
function _M.query_free_api(self, ip)
    local url = "https://freeapi.ipip.net/" .. ip

    local httpc = http.new()
    local timeout = self.timeout or default_timeout
    httpc.set_timeout(timeout)

    local res, err = httpc:request_uri(url, {
            ssl_verify = ssl_verify or false,
            method = "GET",
            headers = headers
        })

    if not res then
        info = "failed to http request: " .. url .. " headers: " .. cjson.encode(headers) .." status: " .. res.status .. " body: " .. res.body
        ngx.log(ngx.ERR, info)
        return nil, err
    end

    if 200 ~= res.status then
        info = "failed to http request: " .. url .. " headers: " .. cjson.encode(headers) .." status: " .. res.status .. " body: " .. res.body
        ngx.log(ngx.ERR, info)
        return nil, res.status
    end

    return to_table(cjson.decode(res.body))
end

-- 获取 ipip.net API 当前访问状态
function _M.api_status(self, _token)

    local token = _token or self.token
    if not token then
        return nil, "the token have not value."
    end

    local url = self.api_url .. "find_status"

    local headers = {
        ["Token"] = token
    }

    local httpc = http.new()
    local timeout = self.timeout or default_timeout
    httpc.set_timeout(timeout)

    local res, err = httpc:request_uri(url, {
            ssl_verify = ssl_verify or false,
            method = "GET",
            headers = headers
        })

    if 200 ~= res.status then
        info = "failed to http request: " .. url .. " headers: " .. cjson.encode(headers) .." status: " .. res.status .. " body: " .. res.body
        ngx.log(ngx.ERR, info)
        return nil, 'bad token'
    end

    info = url .. " headers: " .. cjson.encode(headers) .." status: " .. res.status .. " body: " .. res.body
    ngx.log(ngx[debug_log_level], info)
    if (res.body == nil and res.body == '') then
        return nil, 'bad token'
    end
    return cjson.decode(res.body)
end

return _M
