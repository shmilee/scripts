# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import os
import re
import http.server
import mimetypes
import json
import urllib.parse as urlparse
import multiprocessing


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

    def _list_d_to_html(self, data):
        Num, n, lst, data = data['Num'], data['n'], data['last'], data['data']
        linesep = '<br>'
        starsep = linesep + '*'*50 + linesep
        div_res = ''
        for i, res in enumerate(data):
            if lst == 1:  # reverse
                count = Num - i
            else:
                count = i + 1
            _id = res['Number']
            title = '(%s) Number: %d, Count: %d' % (res['Family'], _id, count)
            extra = [k for k in res if k not in res['Field_Keys']
                     and k not in ('Number', 'Family', 'Field_Keys')]
            li = ''
            for k in list(res['Field_Keys']) + extra:
                v = res.get(k, None)
                if v and (
                        v.startswith('http') or
                        v.startswith('rtmp') or
                        os.path.isfile(v)):
                    li += '\n<li>%s: <a href="%s">%s</a></li>' % (k, v, v)
                else:
                    li += '\n<li>%s: %s</li>' % (k, v)
                # try to fix some keys in html
                if v and v.endswith(os.linesep):
                    m = re.match('(rtmp.*live/s.*wsSecret.*sign=.{3}).*', v)
                    if m:
                        v = '<p>%s%s@@<p>' % (m.groups()[0], linesep)
                        li += '\n<li class="fix-n"> fix-%s: %s</li>' % (k, v)
            div_res += self.HTML_result_template % (starsep, _id, title, li)
        return self.HTML_template % (n, Num, div_res)

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
                    '/netinfocap-hls/' in filepath):
                self._set_ok_headers(path=filepath)
                with open(filepath, 'rb') as data:
                    self.wfile.write(data.read())
            elif filepath.endswith('json'):
                self._set_ok_headers(path='json')
                self.wfile.write(json.dumps(data).encode())
            else:
                self._set_ok_headers(path='html')
                self.wfile.write(self._list_d_to_html(data).encode())
        except Exception as e:
            self.send_error(500, 'INTERNAL SERVER ERROR: %s' % e)
            print(e)
        return


class InfoServer(object):
    '''Server info results as json/html'''

    def __init__(self):
        self.httpd = None
        self.process = None

    def _run(self, info_result, port):
        InfoRequestHandler.set_source_data(info_result)
        self.httpd = http.server.HTTPServer(('', port), InfoRequestHandler)
        print('[Info] Start running server on port %d ...' % port)
        try:
            self.httpd.serve_forever()
        except KeyboardInterrupt:
            print("[Interrupt] InfoServer (serve_forever)!")

    def start(self, info_result, port=8000):
        self.process = multiprocessing.Process(
            target=self._run, args=(info_result, port))
        self.process.start()

    def stop(self):
        if self.httpd:
            self.httpd.shutdown()
        if self.process:
            self.process.terminate()
            # self.process.close()
