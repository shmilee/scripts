# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import os
import re
import requests
import tempfile

from .extractor import StreamingExtractor


REQUESTS_KWARGS = dict(
    stream=True,
    timeout=10,
    headers={
        'User-Agent': 'Wget/1.17.1 (linux-gnu)'
    }
)


class HLS_Url_Extractor(StreamingExtractor):
    '''Get HLS uri from Packet.'''

    def __init__(self, player=None):
        field_keys = ('fullurl',)
        workers = ('get_http_m3u8_or_key',)
        super(HLS_Url_Extractor, self).__init__(
            field_keys=field_keys, workers=workers, player=player, tw=tw)
        self.tmpdir = os.path.join(tempfile.gettempdir(), 'netinfocap-hls')
        if not os.path.exists(self.tmpdir):
            os.mkdir(self.tmpdir)

    def download_tmpfile(self, url, fpath=None):
        suffix = os.path.splitext(url.split('?')[0])[-1]
        if fpath is None:
            fpath = tempfile.mktemp(prefix='%d-' % self.result['Number'],
                                    suffix=suffix, dir=self.tmpdir)
        try:
            with closing(requests.get(url, **REQUESTS_KWARGS)) as rp:
                with open(fpath, "w") as file:
                    for data in rp.iter_content(chunk_size=1024):
                        file.write(data)
            return fpath
        except Exception as err:
            print('\033[31m[Download %s Error]\033[0m' % url, err)
            return None

    def check_need_key(self, m3u8):
        key = None
        with open(m3u8, 'r') as file:
            for i in range(20):  # check 20 lines
                line = file.readline()
                if line.startswith('#EXT-X-KEY:'):
                    m = re.match('''.*URI=["'](?P<key>.*)["'].*''', line)
                    key = m.groupdict['key']
        return key

    def get_http_m3u8_or_key(self, packet):
        '''Get full uri from packet'''
        try:
            if packet.http.request.method == 'GET':
                fullurl = packet.http.request_full_uri
                if fullurl.split('?')[0].endswith('.m3u8'):
                    self.result['fullurl'] = fullurl
                    # TODO -> mv code to check_need_key
                    localm3u8 = self.download_tmpfile(fullurl)
                    if localm3u8:
                        key = self.check_need_key(localm3u8)
                        if key:
                            self.field_keys = ('fullurl', 'key')
                elif packet.http.request_full_uri.endswith('.key'):
                    return 'key', packet.http.request_full_uri
        except Exception:
            pass

    @staticmethod
    def result_callback(result):
        '''set id'''
        if 'fulluri' in result:
            path = result['fulluri'].split('?')[0]
            result['id'] = '/'.join(path.split('/')[-2:])
            os.remove()
            return True
