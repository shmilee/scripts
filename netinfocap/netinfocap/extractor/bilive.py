# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import re
from .extractor import Streaming_Extractor


class Bilive_Url_Extractor(Streaming_Extractor):
    '''Get Bilibili live(HTTP-FLV) URI from Packet.'''
    display_filter = 'http.request.method==GET'

    def __init__(self, player=None, ffmpeg=None):
        field_keys = ('fullurl',)
        workers = ('get_http_live',)
        super(Bilive_Url_Extractor, self).__init__(
            field_keys=field_keys, workers=workers,
            player=player, ffmpeg=ffmpeg)

    def __match_uri(self, request_uri):
        uri = request_uri.split('?')[0]
        if re.match('^/live-bvc/.*flv$', uri):
            return True
        elif re.match('^/live/.*flv$', uri):
            return True
        else:
            return False

    def __get_id(self, request_full_uri):
        for pat in (
                '.*/live-bvc/(.*)/live_([_\d]+)\.flv\?.*',
                '.*/live/flv\?.*stream=(\d+)_.*',
                '.*/live/(.*)\.flv.*',
        ):
            m = re.match(pat, request_full_uri)
            if m:
                return '-'.join(m.groups())
        return '/'.join(request_full_uri.split('?')[0].split('/')[-2:])

    def get_http_live(self, packet):
        '''Get fullurl from packet'''
        try:
            if self.__match_uri(packet.http.request_uri):
                fulluri = packet.http.request_full_uri
                self.result['id'] = self.__get_id(fulluri)
                self.result['fullurl'] = fulluri
        except Exception:
            pass
