# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import os
import re
import tempfile
import contextlib
import requests
import urllib.parse

from .extractor import Streaming_Extractor


REQUESTS_KWS = dict(
    stream=True,
    timeout=10,
    headers={
        'User-Agent': 'Wget/1.17.1 (linux-gnu)'
    }
)


class HLS_Url_Extractor(Streaming_Extractor):
    '''Get HLS uri from Packet.'''
    display_filter = 'http.request.method==GET'

    def __init__(self, player=None, ffmpeg=None):
        field_keys = ('fullurl',)
        workers = ('get_http_m3u8_or_key',)
        super(HLS_Url_Extractor, self).__init__(
            field_keys=field_keys, workers=workers,
            player=player, ffmpeg=ffmpeg)
        self.tmpdir = os.path.join(self.TMPDIR, 'HLS')
        if not os.path.exists(self.tmpdir):
            os.mkdir(self.tmpdir)

    def download_tmpfile(self, url, fpath=None):
        if fpath is None:
            suffix = os.path.splitext(url.split('?')[0])[-1]
            fpath = os.path.join(self.tmpdir, 'hls-%d-%s%s' % (
                self.result['Number'], self.result['UniqID'], suffix))
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
        key, method = None, None
        if localm3u8:
            with open(localm3u8, 'r') as file:
                for line in file.readlines():  # check every lines
                    if line.startswith('#EXT-X-KEY:'):
                        m = re.match('.*METHOD=(?P<method>(?:NONE|AES-128))',
                                     line)
                        if m:
                            method = m.groupdict()['method']
                        m = re.match('''.*URI=["'](?P<key>.*)["'].*''', line)
                        if m:
                            key = m.groupdict()['key']
                            break
        newkey = None
        if key:
            prefix = os.path.splitext(os.path.basename(localm3u8))[0]
            newkey = '%s-%s' % (prefix, key)
            # need key
            self.field_keys = ('fullurl', 'key')
            self.result['Field_Keys'] = ('fullurl', 'key')
            # mark localkey file
            self.result['localkey'] = os.path.join(
                os.path.dirname(localm3u8), newkey)
        # edit localm3u8
        u = urllib.parse.urlparse(m3u8)
        hosturl = '%s://%s' % (u.scheme, u.hostname)
        with open(localm3u8, 'r') as file:
            datalines = file.readlines()
        with open(localm3u8, 'w') as file:
            for line in datalines:
                if line.startswith('#EXT-X-KEY:'):
                    # edit key name
                    if key and newkey:
                        file.write(line.replace(key, newkey))
                    else:
                        if method != 'NONE':
                            self.tw.write('[Error] Lost EXT-X-KEY: %s' % line,
                                          red=True, bold=True)
                        file.write(line)
                else:
                    if (line.startswith('#') or line.startswith('http')
                            or re.match('\s*\n', line)):
                        file.write(line)
                    elif line.startswith('/'):
                        # root, add host url
                        file.write(hosturl + line)
                    else:
                        # relative path -> URL
                        file.write(os.path.dirname(m3u8))
                        file.write('/' + line)
        self.result['localm3u8'] = localm3u8

    def _more_print_segments(self, fullurl):
        '''print segments '.ts' url'''
        if fullurl.endswith('.ts'):
            self.tw.write('[More] ', green=True, bold=True)
            self.tw.write('segment: %s' % fullurl, bold=True)
            self.tw.write(os.linesep)

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
                if self.MoreInfo:
                    self._more_print_segments(fullurl)
        except Exception:
            pass

    def play(self):
        if 'key' in self.result:
            if self.player == 'mpv':
                opt = ' --demuxer-lavf-o-append=allowed_extensions=ts,key'
                opt += ' --demuxer-lavf-o-append=protocol_whitelist=http,tcp,file,crypto,data'
                self.player = 'mpv %s' % opt
            super(HLS_Url_Extractor, self).play(urlkey='localm3u8')
            self.player = 'mpv'
        else:
            super(HLS_Url_Extractor, self).play(urlkey='fullurl')

    def convert(self):
        if 'key' in self.result:
            if self.ffmpeg == 'ffmpeg':
                opt = ' -allowed_extensions ts,key'
                opt += ' -protocol_whitelist http,tcp,file,crypto,data'
                self.ffmpeg = 'ffmpeg %s -i #(INPUT)#' % opt
            super(HLS_Url_Extractor, self).convert(urlkey='localm3u8')
            self.ffmpeg = 'ffmpeg'
        else:
            super(HLS_Url_Extractor, self).convert(urlkey='fullurl')
