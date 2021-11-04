#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import subprocess


def subruncmd(cmd, **kwargs):
    with subprocess.Popen(cmd, **kwargs) as process:
        try:
            print('b here')
            stdout, stderr = process.communicate()
            print('c here')
        except KeyboardInterrupt:
            process.kill()
            #process.terminate()
            # We don't call process.wait() as .__exit__ does that for us.
            # raise # ctrl-c stop here
            print('kill sub')
        retcode = process.poll()
    #res = subprocess.run(cmd, shell=False)
    #   p.terminate()
    print('finish sub')
    return retcode


if __name__ == '__main__':
    for i in range(3):
        subruncmd(['sleep', '10'])
