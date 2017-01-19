# lua-resty-ipip

lua-resty-ipip - ipip.net(17MonIP) parsing library for OpenResty.

# Status

Ready for testing. Probably production ready in most cases, though not yet proven in the wild. Please check the issues list and let me know if you have any problems / questions.

## Description

IP query based on [http://www.ipip.net](http://www.ipip.net/), the best IP database for China.

## Install

    opm get linsir/lua-resty-ipip # use root

## Synopsis

````lua
lua_package_path "/path/to/lua-resty-ipip/lib/?.lua;;";

init_by_lua '
    local ipip = require "resty.ipip.ipip"
    ipipc = ipip:new()
';

server {

    listen 8000;

    location /ip {
        content_by_lua '
            local ipipc = ipipc
            local res, err = ipipc:query_file("202.103.026.255")
            if not res then
                ngx.say(err)
                return
            end
            ngx.say(res)
        ';
    }

}
````

A typical output of the `/ip` location defined above is:

```
{"country":"中国","city":"武汉","province":"湖北"}
```

# Methods

## new

`syntax: ipip:new(token, data_path)`

```

ipipc = ipip:new()

ipipc = ipip:new('9a8bc1a059db4a14b4feb0f38db38bbf4d5353ab1')

ipipc = ipip:new('9a8bc1a059db4a14b4feb0f38db38bbf4d5353ab1', '/path/to/lua-resty-ipip/lib/resty/ipip/data/17monipdb.dat')
```


* `token`: The token of ipip.net.
* `data_path`: Sets the 17monipdb.dat ([download free version](http://s.qdcdn.com/17mon/17monipdb.zip)) file path.


## query

`syntax: res, err = ipipc:query(ip)`
```
data, err = ipipc:query_free_api(ip)
data, err = ipipc:query_api(ip)
data, err = ipipc:query_file(ip)
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
