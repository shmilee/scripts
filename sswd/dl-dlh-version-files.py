#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2022 shmilee

import os
import time
import requests
import zipfile
import json
from multiprocessing import Pool
from contextlib import closing


class ProgressBar(object):
    # ref: https://www.zhihu.com/question/41132103

    def __init__(self, title, count=0.0, run_status=None, fin_status=None,
                 total=100.0, unit='', sep='/', chunk_size=1.0):
        self.info = "[%s] %s %.2f %s %s %.2f %s"
        self.title, self.count, self.total = title, count, total
        self.chunk_size = chunk_size
        self.status = run_status or ""
        self.fin_status = fin_status or " " * len(self.statue)
        self.unit = unit
        self.seq = sep

    def __get_info(self):
        # 【名称】状态 进度 单位 分割线 总数 单位
        return self.info % (self.title, self.status,
                            self.count / self.chunk_size, self.unit, self.seq,
                            self.total / self.chunk_size, self.unit)

    def refresh(self, count=1, status=None):
        self.count += count
        # if status is not None:
        self.status = status or self.status
        end_str = "\r"
        if self.count >= self.total:
            end_str = '\n'
            self.status = status or self.fin_status
        print(self.__get_info(), end=end_str)


def dl_file(url, out, order, name=None, overwrite=False):
    '''return PASS, DONE, or failed (url,out)'''
    title = '(%s) %s -> %s' % (order, url, name or out)
    if not overwrite and os.path.exists(out):
        print('\033[32m[%s]\033[0m exists, pass.' % title)
        return 'PASS'
    try:
        with closing(requests.get(
                url, stream=True, timeout=30,
                headers={'User-Agent': 'Wget/1.21.3 (linux-gnu)'})) as rp:
            chunk_size = 1024
            content_size = int(rp.headers['content-length'])
            progress = ProgressBar(title, total=content_size, unit="KB",
                                   chunk_size=chunk_size,
                                   run_status="正在下载",
                                   fin_status="下载完成")
            with open(out, "wb") as file:
                for data in rp.iter_content(chunk_size=chunk_size):
                    file.write(data)
                    progress.refresh(count=len(data))
    except Exception as err:
        print('\033[31m[Download %s Error]\033[0m' % name, err)
        if os.path.exists(out):
            os.remove(out)
        return url, out
    finally:
        if not os.path.exists(out):
            print('\033[31m[%s]\033[0m Download failed!' % name)
            return url, out
        return 'DONE'


def mkdirs(dirpath):
    if not os.path.exists(dirpath):
        dirpath = dirpath.split('/')
        for i in range(1, len(dirpath)+1):
            thisdir = '/'.join(dirpath[:i])
            if not os.path.exists(thisdir):
                print(f' >> mkdir: {thisdir}')
                os.mkdir(thisdir)


def download_versionzip(host, zfile='version.zip', CDir='sswd-static',
                        others=()):
    start = time.time()
    now = int(start*1000)

    def cdir(path):
        return os.path.join(CDir, path)

    mkdirs(CDir)
    r = dl_file(f'{host}/{zfile}?{now}', cdir(zfile), '#', overwrite=True)
    if r == 1:
        return
    with zipfile.ZipFile(cdir(zfile), mode='r') as z:
        with z.open('version.json') as f:
            data = json.load(f)
    # pre dirs
    for keydir in [os.path.dirname(key)
                   for key in list(data.keys()) + list(others)]:
        if keydir:  # not ''
            mkdirs(cdir(keydir))
    input('Enter to start downloading ... ')
    p = Pool(10)
    N = len(data)
    order_tmp = f'%{len(str(N))}s/{N}'
    result = []
    for i, key in enumerate(data, 1):
        ver = data[key]
        name, ext = os.path.splitext(key)
        path = f'{name}{ver}{ext}'
        url = f'{host}/{path}'
        order = order_tmp % i
        result.append(p.apply_async(dl_file, args=(url, cdir(path), order)))
    p.close()
    p.join()
    failed = f"dl-{zfile.replace('/','-')}.failed"
    with open(failed, "w") as f:
        for res in result:
            if res.get() not in ('PASS', 'DONE'):
                f.write('%s -> %s\n' % res.get())
    end = time.time()
    print('==> [%s] Task runs %0.2f seconds.' % (zfile, (end - start)))
    if not os.path.getsize(failed):
        os.remove(failed)
    for f in others:
        dl_file(f'{host}/{f}', cdir(f.split('?')[0]), '#')


if __name__ == '__main__':
    # /favicon.ico  # /process.png  # /version.zip?1666179211583
    # 1. /code.js?2407  # js-beautify -o sswd-new.js code.js
    import base64
    bstr = 'aHR0cDovL2RsaC1oNS56aHVvaHVhbWcuY29t'.encode()
    download_versionzip(base64.b64decode(bstr).decode(),
                        others=('process.png', 'code.js?2407'))
    # 2./mengdan_app3.js?2022092703 # js-beautify -o md-new.js mengdan_app3.js
    #bstr = 'aHR0cHM6Ly94aGwtc3RhdGljLmJvb21lZ2cuY24vd2ViL21kc3N3ZDM2X2FwcC5odG1sP2JaSE1pbmkmY2hhbm5lbGlkPTExMDA1MTE2MDE='.encode()
    # download_versionzip(os.path.dirname(base64.b64decode(bstr).decode()),
    #                    CDir='md-static',
    #                    others=('process.png', 'mengdan_app3.js?2022092703'))
