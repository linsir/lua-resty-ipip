#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : 2016-03-14 15:58:57
# @Author  : Linsir (root@linsir.org)
# @Link    : http://linsir.org
# OpenResty module fabric scripts for developers.

import os
# from fabric.api import local,cd,run,env,put
from fabric.colors import *
from fabric.api import *

prefix = '/usr/local/openresty'
M_PATH = 'lib/resty/ipip'
APP_NAME = "ipip-demo"
PORT = "8000"

import paramiko
paramiko.util.log_to_file('/tmp/paramiko.log')


# 2. using sshd_config
env.hosts = [
        'master',# master
]

env.use_ssh_config = True

def local_update():
    print(yellow("copy %s and configure..." %APP_NAME ))

    local("sudo cp -r %s %s/site/lualib/resty" %(M_PATH, prefix))

    if os.path.exists("%s/%s/" %(prefix, APP_NAME)):
        local("sudo rm -rf %s/%s/" %(prefix, APP_NAME))

    local("sudo cp -r %s %s" %(APP_NAME, prefix))
    if os.path.exists("%s/nginx/conf/conf.d/%s.conf" %(prefix, APP_NAME)):
        local("sudo rm -rf %s/nginx/conf/conf.d/%s.conf" %(prefix, APP_NAME))
    local("sudo ln -s  %s/%s/%s.conf %s/nginx/conf/conf.d/%s.conf" %(prefix, APP_NAME, APP_NAME, prefix, APP_NAME))
    restart()
    local('curl 127.0.0.1:%s/' %PORT)

def remote_update():
    print(yellow("copy %s and configure..." %APP_NAME))
    run('sudo rm -rf %s/%s/' %(prefix, APP_NAME))
    put(APP_NAME, '%s/')

    put("%s/", "%s/site/site/lualib/resty" %(M_PATH, prefix))

    with cd('%s/nginx/conf/conf.d/' %prefix):
        if not os.path.exists("%s/nginx/conf/conf.d/%s.conf" %(prefix, APP_NAME)):
            run('sudo ln -s  %s/%s/%s.conf %s.conf' %(APP_NAME, APP_NAME, APP_NAME))

    print(green("nginx restarting..."))
    run('/etc/init.d/nginx restart')

def restart():
    print(green("nginx restarting..."))
    local('sudo systemctl restart nginx')

def update():
    # local update
    local_update()

    # remote update
    # remote_update()

    pass
if __name__ == '__main__':
    pass