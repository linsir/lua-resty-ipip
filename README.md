# lua-resty-ipip

lua-resty-ipip - ipip.net(17MonIP) parsing library for OpenResty.

# Status

Ready for testing. Probably production ready in most cases, though not yet proven in the wild. Please check the issues list and let me know if you have any problems / questions.

## Description

IP query based on [http://www.ipip.net](http://www.ipip.net/), the best IP database for China.

## Install
    opm install pintsized/lua-resty-http
    opm get linsir/lua-resty-ipip # use root

## Synopsis

````lua
    lua_package_path "/usr/local/openresty/demo/?.lua;;";
    lua_code_cache on;
    resolver 223.5.5.5;
    init_by_lua '
        local ipip = require "resty.ipip.client"
        cjson = require "cjson"
        local opts = {
            path = "/path/to/17monipdb.datx",
            token = "your token",
            timeout  = "2000",
        }
        ipipc = ipip:new(opts)
    ';
    server {
        listen 8000;
        charset utf-8;
        # server_name ip.linsir.org;
        default_type text/plain;
        root /usr/local/openresty/nginx/html;

        location /ip {
            content_by_lua '
                local ipipc = ipipc
                local cjson = cjson
                local res, err = ipipc:query_file("202.103.026.255")
                if not res then
                    ngx.say(err)
                    return
                end
                ngx.say(cjson.encode(res))
            ';
        }

        location /free_api {
            content_by_lua '
                local ipipc = ipipc
                local cjson = cjson
                local res, err = ipipc:query_free_api("202.103.026.255")
                if not res then
                    ngx.say(err)
                    return
                end
                ngx.say(cjson.encode(res))
            ';
        }

        location /api {
            content_by_lua '
                local ipipc = ipipc
                local cjson = cjson
                local res, err = ipipc:query_api("202.103.026.255")
                if not res then
                    ngx.say(err)
                    return
                end
                ngx.say(cjson.encode(res))
            ';
        }

        location /api_status {
            content_by_lua '
                local ipipc = ipipc
                local cjson = cjson
                local res, err = ipipc:api_status()
                # local res, err = ipipc:api_status("your token")
                if not res then
                    ngx.say(err)
                    return
                end
                ngx.say(cjson.encode(res))
            ';
        }

        error_log  logs/ip_error.log info;
    }

}
````

- A typical output of the `/ip` location defined above is:

```
{"country":"中国","city":"武汉","province":"湖北"}
```

- A typical output of the `/free_api` location defined above is:

```
{"place":"","country":"中国","city":"武汉","province":"湖北","carriers":"电信"}
```

- A typical output of the `/api` location defined above is:

```
{"carriers":"电信","longitude":"114.298572","city":"武汉","province":"湖北","china_area_code":"420100","place":"","country":"中国","nation_code":"CN","phone_code":"86","tz_name":"Asia\/Shanghai","continents_code":"AP","latitude":"30.584355","tz_utc":"UTC+8"}
```

- A typical output of the `/api_status` location defined above is:

```
{"ret":"ok","service":{"service_id":10,"expired":"2019-08-13"},"data":{"day":1,"hour":1,"limit":false}}
```

# Methods

## new

`syntax: ipip:new(opts)`

```
local opts = {
    path = "/path/to/17monipdb.datx",
    token = "your token",
    timeout  = "2000",
}
ipipc = ipip:new(opts)

```


* `path`: Sets the 17monipdb.datx ([download free version](https://www.ipip.net/free_download/)) file path.
* `token`: The token of ipip.net.
* `timeout`: The timeout for http request.


## query

`syntax: res, err = ipipc:query(ip)`
```
data, err = ipipc:query_free_api(ip)
data, err = ipipc:query_api(ip)
data, err = ipipc:query_file(ip)

```

## api status

```
data, err = ipipc:api_status()
data, err = ipipc:api_status("9a8bc1a059db4a14b4feb0f38db38bbf4d5353ab1")
```

# Author

Linsir <root@linsir.org>

# Licence

This module is licensed under the 2-clause BSD license.

Copyright (c) 2017, Linsir <root@linsir.org>

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
