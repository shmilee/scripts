# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import os
import re
import tempfile
import contextlib
import requests

from .extractor import StreamingExtractor


REQUESTS_KWS = dict(
    stream=True,
    timeout=10,
    headers={
        'User-Agent': 'Wget/1.17.1 (linux-gnu)'
    }
)


class HLS_Url_Extractor(StreamingExtractor):
    '''Get HLS uri from Packet.'''
    display_filter = 'http.request.method==GET'

    def __init__(self, player=None, tw=None):
        field_keys = ('fullurl',)
        workers = ('get_http_m3u8_or_key',)
        if player == 'mpv':
            player += ' --demuxer-lavf-o-append=allowed_extensions=ts,key'
            player += ' --demuxer-lavf-o-append=protocol_whitelist=http,tcp,file,crypto,data'
        super(HLS_Url_Extractor, self).__init__(
            field_keys=field_keys, workers=workers, player=player, tw=tw)
        self.tmpdir = os.path.join(tempfile.gettempdir(), 'netinfocap-hls')
        if not os.path.exists(self.tmpdir):
            os.mkdir(self.tmpdir)

    def download_tmpfile(self, url, fpath=None):
        if fpath is None:
            suffix = os.path.splitext(url.split('?')[0])[-1]
            fpath = tempfile.mktemp(prefix='%d-' % self.result['Number'],
                                    suffix=suffix, dir=self.tmpdir)
        try:
            with contextlib.closing(requests.get(url, **REQUESTS_KWS)) as rp:
                with open(fpath, "wb") as file:
                    for data in rp.iter_content(chunk_size=1024):
                        file.write(data)
            return fpath
        except Exception as err:
            self.tw.write(
                '[Error] Download %s, %s\n' % (url, err), red=True, bold=True)
            return None

    def check_need_key(self, m3u8):
        localm3u8 = self.download_tmpfile(m3u8)
        key = None
        if localm3u8:
            with open(localm3u8, 'r') as file:
                for i in range(20):  # check 20 lines
                    line = file.readline()
                    if line.startswith('#EXT-X-KEY:'):
                        m = re.match('''.*URI=["'](?P<key>.*)["'].*''', line)
                        if m:
                            key = m.groupdict()['key']
                            break
        if key:
            prefix = os.path.splitext(os.path.basename(localm3u8))[0]
            newkey = '%s-%s' % (prefix, key)
            # edit localm3u8
            with open(localm3u8, 'r') as file:
                datalines = file.readlines()
            with open(localm3u8, 'w') as file:
                for line in datalines:
                    if line.startswith('#EXT-X-KEY:'):
                        # edit key name
                        file.write(line.replace(key, newkey))
                    else:
                        if (line.startswith('#') or line.startswith('http')
                                or re.match('\s*\n', line)):
                            file.write(line)
                        else:
                            # relative path -> URL
                            file.write(os.path.dirname(m3u8))
                            file.write('/' + line)
            self.result['localm3u8'] = localm3u8
            # need key
            self.field_keys = ('fullurl', 'key')
            # mark localkey file
            self.result['localkey'] = os.path.join(
                os.path.dirname(localm3u8), newkey)

    def get_http_m3u8_or_key(self, packet):
        '''Get full uri from packet'''
        try:
            if packet.http.request_method == 'GET':
                fullurl = packet.http.request_full_uri
                path = fullurl.split('?')[0]
                if path.endswith('.m3u8'):
                    self.result['id'] = '/'.join(path.split('/')[3:-1])
                    self.result['fullurl'] = fullurl
                    self.check_need_key(fullurl)
                elif path.endswith('.key'):
                    # after check_need_key
                    if 'localkey' in self.result:
                        localkey = self.download_tmpfile(
                            fullurl, fpath=self.result['localkey'])
                        if localkey:
                            self.result['key'] = fullurl
        except Exception:
            pass

    def play(self):
        super(HLS_Url_Extractor, self).play(urlkey='localm3u8')
