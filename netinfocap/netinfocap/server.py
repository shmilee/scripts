# -*- coding: utf-8 -*-

# Copyright (c) 2021-2022 shmilee

import os
import re
import http.server
import mimetypes
import json
import shutil
import urllib.parse as urlparse
import multiprocessing
import traceback

from .extractor import Extractor
from .vcsi import vcsi

HTML_template = '''<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<link rel="icon" href="data:;base64,iVBORw0KGgo=">
<title>NetInfo results list</title>
<style type="text/css">
li {
    width: 720px;
    word-break: break-all;
}
li.fix-n > p {
    margin: 4px 8px;
    width: 400px;
    font-weight: bold;
}
</style>
</head>
<body>
<div id="ALL" style="margin-left:8px;width:100%%;">
    <h2>NetInfo results list (%d of %d)</h2>%s
</div>
</body>
</html>
'''  # % n, Num, results div
HTML_result_template = '''
    %s
    <div class="panel-primary">
        <div class="panel-heading" id="%s"><b>%s</b></div>
        <div class="panel-body" style="margin-left:8px;">
        <ul>%s
        </ul>
        </div>
    </div>
'''  # % starsep, id, title, ul


def _result2div(res, count, control_keys=Extractor.control_keys,
                copy_dest=None, thumbnails_dest=None, thumbnails_kwargs=None):
    '''
    res: dict, results
    count: int
    control_keys: tuple
    copy_dest: str, copy files shown in results to *copy_dest*
    thumbnails_dest: str
        try to create thumbnails in *thumbnails_dest* for fullurl or not
    thumbnails_kwargs: dict, for vcsi.main()
    '''
    linesep = '<br>'
    starsep = linesep + '*'*50 + linesep
    _idx = res['Index']
    title = '(%s) UID: %s, Index: %d, Count: %d' % (
        res['Family'], res['UniqID'], _idx, count)
    extra = [k for k in res if k not in res['Field_Keys']
             and k not in control_keys]
    li = ''
    for k in list(res['Field_Keys']) + extra:
        v = res.get(k, None)
        if not v:
            continue
        if v.startswith('http') or v.startswith('rtmp'):
            li += '\n<li>%s: <a href="%s">%s</a></li>' % (k, v, v)
        elif os.path.isfile(v):
            if copy_dest and os.path.isdir(copy_dest):
                newv = shutil.copy2(v, copy_dest)
                _li_tuple = (k, newv, newv)
            else:
                _li_tuple = (k, v, v)
            li += '\n<li>%s: <a href="%s">%s</a></li>' % _li_tuple
        else:
            li += '\n<li>%s: %s</li>' % (k, v)
        # try to fix some keys in html
        if v.endswith(os.linesep):
            m = re.match('(rtmp.*live/s.*wsSecret.*sign=.{3}).*', v)
            if m:
                v = '<p>%s%s@@<p>' % (m.groups()[0], linesep)
                li += '\n<li class="fix-n"> fix-%s: %s</li>' % (k, v)
    if (thumbnails_dest and os.path.isdir(thumbnails_dest)
            and res['Family'] in ['Bilive_Url', 'HLS_Url', 'RTMPT_Url']):
        tfile = 'thumb-%d-%s.jpg' % (res['Index'], res['UniqID'])
        tpath = os.path.join(thumbnails_dest, tfile)
        text = 'snapshot:' + linesep
        if os.path.isfile(tpath):
            print("[Info] Use created thumbnail '%s'" % tfile)
            li += '\n<li>%s<img src="%s" width="400" alt="%s"></li>' % (
                text, tpath, tpath)
        elif os.path.exists(tpath+'.mask'):
            print("[Info] Skip to create thumbnail '%s'" % tfile)
        else:
            kwargs = thumbnails_kwargs or {}
            args = [
                '-t', '-w', kwargs.get('width', '600'),
                '-g', kwargs.get('grid', '1x1'),
                '--grid-spacing', kwargs.get('grid_spacing', '8'),
                '--start-delay-percent', kwargs.get(
                    'start_delay_percent', '8'),
                '--end-delay-percent', kwargs.get('end_delay_percent', '8'),
                '--metadata-font', kwargs.get(
                    'metadata_font',
                    '/usr/share/fonts/wenquanyi/wqy-zenhei/wqy-zenhei.ttc'),
            ]
            try:
                print("[Info] Creating thumbnail '%s' ..." % tpath)
                vcsi.main(argv=args+[res['fullurl'], '-o', tpath])
            except Exception:
                if 'localm3u8' in res:
                    vcsi.main(argv=args+[res['localm3u8'], '-o', tpath])
            if os.path.isfile(tpath):
                li += '\n<li>%s<img src="%s" width="400" alt="%s"></li>' % (
                    text, tpath, tpath)
            else:
                print("[Error] Failed to create '%s'! Mask it!" % tfile)
                with open(tpath+'.mask', 'w') as fp:
                    fp.write('')
    return HTML_result_template % (starsep, _idx, title, li)


class InfoRequestHandler(http.server.BaseHTTPRequestHandler):

    def _set_ok_headers(self, path='html'):
        self.send_response(200)
        if path == 'html':
            ct = 'text/html; charset=utf-8'
        elif path == 'json':
            ct = 'application/json; charset=utf-8'
        else:
            ct = mimetypes.guess_type(path)[0]
        if ct:
            self.send_header('Content-type', ct)
        else:
            self.send_header('Content-type', 'application/octet-stream')
        self.end_headers()

    def do_HEAD(self):
        self._set_ok_headers()

    @classmethod
    def set_source_data(cls, RESULTS):
        cls.RESULTS = RESULTS

    def _pre_response_data(self, query):
        query = urlparse.parse_qs(query)
        n = int(query.get('n', ['10'])[0])
        last = query.get('last', ['1'])[0]
        li = self.RESULTS
        #print('SERVER:', li)
        Num = len(li)
        if n <= 0:
            n = Num
        if last == '1':  # reverse
            if n < Num:
                data = list(li[:Num-n-1:-1])
            else:
                data = list(li[::-1])
        else:
            if n < Num:
                data = list(li[:n])
            else:
                data = list(li)
        return {
            'Num': Num, 'n': n, 'last': 1 if last == '1' else 0,
            'data': data,
        }

    def _list_d_to_html(self, data):
        Num, n, lst, data = data['Num'], data['n'], data['last'], data['data']
        div_res = ''
        for i, res in enumerate(data):
            if lst == 1:  # reverse
                count = Num - i
            else:
                count = i + 1
            div_res += _result2div(res, count,
                                   thumbnails_dest=Extractor.TMPDIR)
        return HTML_template % (n, Num, div_res)

    def do_GET(self):
        '''
        default: "GET /" -> "GET /html?n=10&last=1"
        "GET /json?n=0"
        "GET /html?n=10&last=0"

        path: json or html
        query:
            n, number, 0: return all
            last, 1: True, 0: False

        path: real file path contains '/netinfocap-hls/', return file
        '''
        try:
            querypath = urlparse.urlparse(self.path)
            filepath, query = querypath.path, querypath.query
            data = self._pre_response_data(query)
            if os.path.isfile(filepath) and (
                    filepath.startswith(Extractor.TMPDIR)):
                self._set_ok_headers(path=filepath)
                with open(filepath, 'rb') as data:
                    self.wfile.write(data.read())
            elif filepath.endswith('json'):
                self._set_ok_headers(path='json')
                self.wfile.write(json.dumps(data).encode())
            else:
                self._set_ok_headers(path='html')
                self.wfile.write(self._list_d_to_html(data).encode())
        except BrokenPipeError as e:
            traceback.print_exc()
            try:
                estr = '%s. HTTPServer may need to restart now!' % e
                self.send_error(500, 'INTERNAL SERVER ERROR: %s' % estr)
            except Exception:
                pass
        except Exception as e:
            self.send_error(500, 'INTERNAL SERVER ERROR: %s' % e)
            traceback.print_exc()
        return


class InfoServer(object):
    '''Serve info results as json/html'''

    def __init__(self):
        self.httpd = None
        self.process = None

    def _run(self, info_result, port):
        InfoRequestHandler.set_source_data(info_result)
        self.httpd = http.server.HTTPServer(('', port), InfoRequestHandler)
        print('[Info] Start running server on port %d ...' % port)
        try:
            self.httpd.serve_forever()
        # except BrokenPipeError:
        #    print("[BrokenPipe] InfoServer (restarting)!")
        #    self.stop()
        #    self.start()
        except KeyboardInterrupt:
            print("[Interrupt] InfoServer (serve_forever)!")

    def start(self, info_result, port=8000):
        self.process = multiprocessing.Process(
            target=self._run, args=(info_result, port))
        self.process.start()

    def stop(self):
        if self.httpd:
            self.httpd.shutdown()
        self.httpd = None
        if self.process:
            self.process.terminate()
            # self.process.close()
        self.process = None
