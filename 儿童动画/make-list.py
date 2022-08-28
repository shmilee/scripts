#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2020 shmilee

import urllib.parse

video_dir = (
    #'巴巴爸爸.Barbapapa'
    #'巴塔木流行儿歌'
    #'巴塔木童谣'
    #'巴塔木ABC'
    #'超级宝贝JOJO'
    '海底小纵队'
    #'小猪佩奇'
)
vlc_list = 'shmilee.m3u8'


def decode(s):
    return urllib.parse.unquote(s, encoding='utf-8', errors='replace')

with open('./%s/%s' % (video_dir, vlc_list), 'r') as fin:
    new_lines = [
        s if s.startswith('#EXT') else '%s/%s' % (video_dir, decode(s))
        for s in fin.readlines()
    ]
    with open('./%s.m3u8' % video_dir,'w') as out:
        for l in new_lines:
            out.write(l)
