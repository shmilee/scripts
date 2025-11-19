# -*- coding: utf-8 -*-

# Copyright (c) 2025 shmilee

import re
import time
import requests
from urllib.parse import urlparse
from contextlib import closing
from . import m3u8


class SpeedTest(object):

    def __init__(self, timeout=10, UA=None, default_headers=None):
        self.timeout = timeout
        self.UA = UA or 'Mozilla/5.0 (Windows NT 10.0; Win64) Firefox/142.0'
        self.default_headers = default_headers or {}

    def _get_rqkwargs(self, url):
        parsed_url = urlparse(url)
        host = parsed_url.netloc  # .hostname
        kws = dict(timeout=self.timeout, allow_redirects=True)
        kws['headers'] = self.default_headers.copy()
        kws['headers'].update({
            'User-Agent': self.UA,
            'Host': host,
            'Referer': url,
        })
        return kws

    def _get_errno(self, error):
        errno = getattr(error, 'errno', None)
        if errno == None:
            err = error
            while isinstance(err, Exception):
                if len(err.args) > 0:
                    err = err.args[-1]
                    eno = getattr(err, 'errno', None)
                    if eno:
                        errno = eno
                        break
                    else:
                        m = re.match(r'.*\[Errno (\d+)\]', str(err))
                        if m:
                            errno = int(m.groups()[0])
                            break
                else:
                    break
        return errno

    def test_connection(self, url, desc):
        '''return True/False'''
        print("(%s) connecting %s ..." % (desc, url))
        try:
            with closing(requests.get(url, **self._get_rqkwargs(url))) as rp:
                if 200 <= rp.status_code < 400:
                    print('(%s) \033[32m[connected]\033[0m, %s' % (desc, url))
                    return True
                else:
                    print('(%s) \033[32m[status %d]\033[0m, %s'
                          % (desc, rp.status_code, url))
        except Exception as error:
            errno = self._get_errno(error)
            print('(%s) \033[32m[error %s]\033[0m, %s' % (desc, errno, url))
        return False

    def fetch(self, url, desc):
        '''
        Return 1. response content bytes and 2. test info: {
          time:Epoch-seconds, status:int, size:data-size, speed:KB/s,
        }
        '''
        print("(%s) fetching %s ..." % (desc, url))
        data = b''
        info = dict(time=int(time.time()), status=1000, size=0, speed=0)
        try:
            start = time.monotonic()
            with closing(requests.get(url, **self._get_rqkwargs(url))) as rp:
                status = rp.status_code
                start_transfer = time.monotonic()
                if status == 200:
                    data = rp.content
                else:
                    print('===%d=== %s\n' % (status, url), rp.headers)
            now = time.monotonic()
            size = len(data)
            speed = round(size/(now-start)/1024, 3)
        except Exception as error:
            errno = self._get_errno(error)
            if errno:
                status = 1000 + errno
            print('(%s) \033[31m[Error %d]\033[0m, %s'
                  % (desc, status, url), error)
            info.update(status=status)
        else:
            info.update(status=status)
            if status == 200:
                print('(%s) \033[32m[ok, %.2f KB/s]\033[0m, %s'
                      % (desc, speed, url))
                info.update(size=size, speed=speed)
            else:
                print('(%s) \033[31m[Error %d]\033[0m, %s'
                      % (desc, status, url))
        return data, info

    def fetch_m3u8_playlist(self, m3u8_url, desc, max_depth=3):
        '''
        Return 1. m3u8.model.M3U8 instance or None, and 2. test info: {
          time:Epoch-seconds, status:int, size:data-size, speed:KB/s,
        }
        '''
        data, info = self.fetch(m3u8_url, desc)
        try:
            for depth in range(max_depth):
                playlist = m3u8.loads(data.decode(), uri=m3u8_url)
                if playlist.is_endlist and playlist.segments:
                    return playlist, info
                elif (depth < max_depth - 1 and len(playlist.playlists) > 0
                      and playlist.playlists[0].uri.endswith('.m3u8')):
                    uri = playlist.playlists[0].uri  # Handle relative URI
                    # set sub playlist m3u8_url to test
                    m3u8_url = requests.compat.urljoin(m3u8_url, uri)
                    data, info = self.fetch(m3u8_url, desc)
            print('Cannot get M3U8 playlist!')
        except Exception as e:
            print(f"Error loading M3U8 playlist: {e}")
        return None, info

    def fetch_m3u8_segments(
            self, m3u8_playlist, desc,
            time_limit=60, count_limit=10, size_limit=15*1024*1024):
        '''
        Return 1. list of segments bytes and 2. test info: {
            time:Epoch-seconds, status:[int,...],
            size:[data-size,...], speed:[KB/s,...],
        }
        '''
        segments_data = []
        info = dict(time=int(time.time()), status=[], size=[], speed=[])
        if not isinstance(m3u8_playlist, m3u8.M3U8):
            print('Invalid m3u8 playlist!')
            return [], info
        segments = m3u8_playlist.segments[:count_limit]
        rqkwargs = self._get_rqkwargs(m3u8_playlist.base_uri)
        with requests.Session() as session:
            session.headers.update(rqkwargs.pop('headers', {}))
            ts_time, ts_size = 0, 0
            for idx, seg in enumerate(segments, 1):
                segdesc = f'{desc},seg-{idx}/{count_limit}'
                url = seg.absolute_uri
                print("(%s) fetching %s ..." % (segdesc, url))
                start = time.monotonic()
                data, status, size, speed = b'', 1000, 0, 0
                try:
                    rp = session.get(url, timeout=self.timeout)
                    status = rp.status_code
                    if status == 200:
                        data = rp.content
                    else:
                        print('===%d=== %s\n' % (status, url), rp.headers)
                    now = time.monotonic()
                    size = len(data)
                    speed = size/(now-start)/1024
                except Exception as error:
                    errno = self._get_errno(error)
                    if errno:
                        status = 1000 + errno
                    print('(%s) \033[31m[Error %d]\033[0m, %s'
                          % (segdesc, status, url), error)
                else:
                    if status == 200:
                        print('(%s) \033[32m[ok, %.2f KB/s]\033[0m, %s'
                              % (segdesc, speed, url))
                    else:
                        print('(%s) \033[31m[Error %d]\033[0m, %s'
                              % (segdesc, status, url))
                # update data, info
                segments_data.append(data)
                info['status'].append(status)
                info['size'].append(size)
                info['speed'].append(round(speed, 4))
                # check limit
                ts_time += seg.duration
                ts_size += size
                if ts_time > time_limit:
                    print("(%s) download ts time: %.3f > %.3f ..."
                          % (segdesc, ts_time, time_limit))
                    break
                if ts_size >= size_limit:
                    print("(%s) download ts size: %.3f > %.3f ..."
                          % (segdesc, ts_size, size_limit))
                    break
        return segments_data, info
