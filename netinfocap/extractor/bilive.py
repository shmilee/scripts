# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

from .extractor import StreamingExtractor


class Bilive_Url_Extractor(StreamingExtractor):
    '''Get Bilibili live(HTTP-FLV) URI from Packet.'''

    def __init__(self, player=None, tw=None):
        field_keys = ('fullurl',)
        workers = ('get_http_live',)
        super(Bilive_Url_Extractor, self).__init__(
            field_keys=field_keys, workers=workers, player=player, tw=tw)

    def get_http_live(self, packet):
        '''Get fullurl from packet'''
        try:
            if packet.http.request_uri_path.startswith('/live-bvc/'):
                fulluri = packet.http.request_full_uri
                path = fulluri.split('?')[0]
                self.result['id'] = '/'.join(path.split('/')[-2:])
                self.result['fullurl'] = fulluri
        except Exception:
            pass
