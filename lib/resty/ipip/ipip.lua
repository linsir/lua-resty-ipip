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

_M._VERSION = '0.01'

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

local function _split(s, p)
    local rt = {}
    string.gsub(s, '[^' .. p .. ']+', function(w) table.insert(rt, w) end)
    return rt
end

-- 返回数据模版
local data_template = {
    "country", -- // 国家
    "province", -- // 省会或直辖市（国内）
    "city", -- // 地区或城市 （国内）
    "place", -- // 学校或单位 （国内）
    "carriers", -- // 运营商字段（只有购买了带有运营商版本的数据库才会有）
    "latitude", -- // 纬度     （每日版本提供）
    "longitude", -- // 经度     （每日版本提供）
    "tz_name", -- // 时区一, 可能不存在  （每日版本提供）
    "tz_utc", -- // 时区二, 可能不存在  （每日版本提供）
    "china_area_code", -- // 中国行政区划代码    （每日版本提供）
    "phone_code", -- // 国际电话代码        （每日版本提供）
    "nation_code", -- // 国家二位代码        （每日版本提供）
    "continents_code" -- // 世界大洲代码        （每日版本提供）
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
function _M.new(self, token, path)
    local url = "http://freeapi.ipip.net/"
    if token then
        url = "http://ipapi.ipip.net/"
    end
    if not path then
        path = "/usr/local/openresty/site/lualib/resty/ipip/data/17monipdb.dat"
    end
    
    return setmetatable({api_url = url, token = token, data_path = path}, mt)
end


-- 从文件获取 IP 信息
function _M.query_file(self, ipstr)
    if not self.data_path then
        ngx.log(ngx.ERR, self.data_path)
        return nil, "The data file path not initialized"
    end

    local ip1, ip2, ip3, ip4 = match(ipstr, "(%d+).(%d+).(%d+).(%d+)")
    local ip_uint32 = _uint32(ip1, ip2, ip3, ip4)
    local file = io.open(self.data_path)
    if file == nil then
        return nil, "io error."
    end

    local str = file:read(4)
    local offset_length = _uint32(byte(str, 1), byte(str, 2), byte(str, 3), byte(str, 4))

    local index_buff = file:read(offset_length - 4)

    local tmp_offset = ip1 * 4
    local start_length = _uint32(byte(index_buff, tmp_offset + 4), byte(index_buff, tmp_offset + 3), byte(index_buff, tmp_offset + 2), byte(index_buff, tmp_offset + 1))

    local max_comp_len = offset_length - 1028
    local start = start_length * 8 + 1024 + 1
    local index_offset = -1
    local index_length = -1
    while start < max_comp_len do
        local find_uint32 = _uint32(byte(index_buff, start), byte(index_buff, start + 1), byte(index_buff, start + 2), byte(index_buff, start + 3))
        if ip_uint32 <= find_uint32 then
            index_offset = _uint32(0, byte(index_buff, start + 6), byte(index_buff, start + 5), byte(index_buff, start + 4))
            index_length = byte(index_buff, start + 7)
            break
        end
        start = start + 8
    end

    if index_offset == -1 or index_length == -1 then
        return nil, "io error, please check the data file."
    end

    local offset = offset_length + index_offset - 1024

    file:seek("set", offset)

    -- return file:read(index_length)
    local data = file:read(index_length)
    return to_table(_split(data, "%s+"))
end

-- 通过 ipip.net API 获取 IP 信息
function _M.query_api(self, ip)

    local token = self.token

    local url = self.api_url .. "find?addr=" .. ip

    local headers = {
        ["Token"] = token
    }
    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
            method = "GET",
            headers = headers
        })

    if not res then
        ngx.log(ngx.ERR, "failed to http request: " .. err .. url)
        return nil, err
    end

    if 200 ~= res.status then
        ngx.log(ngx.ERR, res.status)
        return nil, res.status
    end

    local response = cjson.decode(res.body)

    if not response.data then
        return response
    end

    return to_table(response.data)
end

-- 通过 ipip.net 免费的 API 获取 IP 信息
function _M.query_free_api(self, ip)
    local api_url = "http://freeapi.ipip.net/"
    local url = api_url .. ip

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
            method = "GET",
            headers = headers
        })

    if not res then
        ngx.log(ngx.ERR, "failed to request: " .. err .. url)
        return nil, err
    end

    if 200 ~= res.status then
        ngx.log(ngx.ERR, res.status)
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
    local res, err = httpc:request_uri(url, {
            method = "GET",
            headers = headers
        })

    if not res then
        ngx.log(ngx.ERR, "failed to request: " .. err .. url)
        return nil, err
    end

    if (res.body == '' or res.body) then
        return nil, 'bad token.'
    end

    return cjson.decode(res.body)
end

return _M