#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2022 shmilee

import os
import sys
import json
import argparse
from http import HTTPStatus
from http.server import HTTPServer, SimpleHTTPRequestHandler


class HandlerClass(SimpleHTTPRequestHandler):

    local_directory = None
    local_msg_file = None

    @classmethod
    def set_local_directory(cls, directory):
        cls.local_directory = os.fspath(directory)

    @classmethod
    def set_local_msg_file(cls, file):
        cls.local_msg_file = file

    def translate_path(self, path):
        path = super().translate_path(path)
        CWD = os.getcwd()  # 3.0<=3.6,>=3.7 CWD/XXXX
        if self.local_directory in (None, '.', CWD):
            return path
        # 3.7 add directory parameter
        if self.local_directory == getattr(self, 'directory', None):
            return path
        return path.replace(CWD, self.local_directory, 1)

    def do_GET(self):
        f = self.send_head()
        if f:
            try:
                self.copyfile(f, self.wfile)
            except BrokenPipeError as e:
                cip = self.client_address[0]
                self.log_message('%s from %s' % (e, cip))
            finally:
                f.close()

    def _response_ok(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()

    error_message_format = ('{"code": %(code)d,"Message": "%(message)s",'
                            '"explanation": "%(code)s - %(explain)s"}')
    error_content_type = 'application/json'

    def msg_append_to_file(self):
        ''' data example: b'{"who":, "addr":, "time": "msg": }' '''
        try:
            data = json.loads(self._get_post_data().decode())
            who, addr, time = data['who'], data['addr'], data['time']
            msg = data['msg']
        except Exception as e:
            self.send_error(HTTPStatus.BAD_REQUEST, "Invalid POST data")
            return False
        INTERNAL_ERROR = HTTPStatus.INTERNAL_SERVER_ERROR
        if self.local_msg_file == None:
            self.send_error(INTERNAL_ERROR, "Msg file not set")
            return False
        if not os.access(self.local_msg_file, os.W_OK):
            d = os.path.abspath(os.path.dirname(self.local_msg_file))
            if not os.access(d, os.W_OK):
                self.send_error(INTERNAL_ERROR, "Msg file not writeable")
                return False
        try:
            with open(self.local_msg_file, 'a') as f:
                f.write('[{0}] - {1} - {2} - {3}\n'.format(
                    time, addr, who, msg))
            self._response_ok()
        except Exception as e:
            self.send_error(INTERNAL_ERROR, "Msg file write-err")
            return False
        return True

    def _get_post_data(self):
        content_length = int(self.headers['Content-Length'])
        return self.rfile.read(content_length)

    _post_routes = {
        '/jsonmsg': 'msg_append_to_file',
    }

    def do_POST(self):
        if self.path in self._post_routes:
            meth = getattr(self, self._post_routes[self.path])
            meth()
        else:
            self.send_error(HTTPStatus.NOT_FOUND,
                            "Path %s not found" % self.path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--bind', '-b', metavar='ADDRESS',
                        default='127.0.0.1',
                        help='specify alternate bind address '
                             '(default: 127.0.0.1)')
    parser.add_argument('--directory', '-d', default=os.getcwd(),
                        help='specify alternate directory '
                             '(default: current directory)')
    parser.add_argument('--msgfile', '-m',
                        help='specify a file path to save POST msg')
    parser.add_argument('port', action='store', default=8000, type=int,
                        nargs='?',
                        help='specify alternate port (default: 8000)')
    args = parser.parse_args()
    HandlerClass.set_local_directory(args.directory)
    HandlerClass.set_local_msg_file(args.msgfile)
    with HTTPServer((args.bind, args.port), HandlerClass) as httpd:
        host, port = httpd.socket.getsockname()[:2]
        url_host = f'[{host}]' if ':' in host else host
        print(
            f"Serving HTTP on {host} port {port} "
            f"(http://{url_host}:{port}/) ..."
        )
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nKeyboard interrupt received, exiting.")
            sys.exit(0)


if __name__ == '__main__':
    main()
