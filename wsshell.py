#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2023 shmilee

'''
See also:
* https://github.com/shelld3v/wsshell/blob/main/wsshell.py
* https://gist.github.com/nvgoldin/30cea3c04ee0796ebd0489aa62bcf00a
* https://stackoverflow.com/questions/48562893/
* https://github.com/MagicStack/uvloop/blob/v0.17.0/tests/test_process.py
* https://docs.python.org/3.9/library/asyncio-task.html#asyncio.wait_for
'''

import os
import sys
import time
import getpass
import random
import argparse
import asyncio
import signal
import functools
import shlex
import subprocess
import websockets
import http
import urllib.parse as urlparse
from websockets.headers import (
    build_authorization_basic, parse_authorization_basic)
# print(websockets)

VERSION = '0.1'
DESCRIPTION = "A simple websocket shell v%s by shmilee." % VERSION

USER = getpass.getuser()
HOST = subprocess.getoutput('hostname')
if USER == 'root':
    PS1 = '[%s@%s]# ' % (USER, HOST)
else:
    PS1 = '[%s@%s]$ ' % (USER, HOST)
AUTHORIZATION = []
CHARS = "abcdefghijklmnopqrstuvwxyz-ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789"

OSNAME = subprocess.getoutput('uname -o')
KERNEL = subprocess.getoutput('uname -r')
welcome_msg = """Welcome to %s (%s %s)

 * Date: %%s
 * Uptime: %%s

%s
 * Only support non-interactive commands!
 * Complicated shell commands should be: bash -c 'CMD1 | CMD2  >a.out'
 * Set timeout for next commands by 'wsshell-timeout Number'.
 * Change the working directory by 'cd', like 'cd ~', 'cd', 'cd /xxx'
 * Set bash mode for running next commands by 'wsshell-bash on/off'.
   Then 'bash -c' can be omitted for CMD1, CMD2.
 * Transfer file URL: ws://user:passwd@IP:Port/PATH
    - client command: 'websocat -n -U --binary URL >local/save/path
    - relative PATH: /download/path/to/file?chunk_size=5242880
    - absolute PATH: /download//path/to/file
    - userhome PATH: /download/~/path/to/file

""" % (HOST, OSNAME, KERNEL, DESCRIPTION)
LOGFILE = './simple-wsshell-%d.log' % os.getpid()


def info(msg):
    s = time.strftime('%F %H:%M:%S')
    msg = '[%s] - %s' % (s, msg)
    print(msg)
    try:
        with open(LOGFILE, 'a+') as l:
            l.write(msg)
            l.write('\n')
    except Exception:
        pass


def random_str(length):
    return ''.join(random.sample(CHARS, min(len(CHARS), length)))


class BasicAuthServerProtocol(websockets.WebSocketServerProtocol):
    '''
    ref: https://github.com/python-websockets/websockets/issues/373
    '''
    async def process_request(self, path, request_headers):
        # info("AUTHORIZATION: %s" % AUTHORIZATION)
        # print(dir(self), self.remote_address)
        info("Client authorization for %s:%s" % self.remote_address)
        try:
            # print('\nRequest headers:', request_headers, sep='\n')
            authorization = request_headers['Authorization']
        except KeyError:
            info("Miss authorization for %s:%s" % self.remote_address)
            return http.HTTPStatus.UNAUTHORIZED, [], b'Missing credentials\n'
        # info("get authorization: %s" % authorization)
        u = parse_authorization_basic(authorization)[0]
        if authorization not in AUTHORIZATION:
            info("Incorrect authorization of %s from %s:%s"
                 % (u, *self.remote_address))
            return http.HTTPStatus.FORBIDDEN, [], b'Incorrect credentials\n'
        info("Get correct authorization of %s from %s:%s"
             % (u, *self.remote_address))


def _cmd_timeout(cmdlist, oldt=15):
    '''
    Check and change the timeout for asyncio.wait_for.
    Return 'timeout' value and output str.
    '''
    if len(cmdlist) > 1:
        if cmdlist[-1].isdigit():
            t = int(cmdlist[-1])
            if t > 0:
                return t, 'New TIMEOUT=%d.' % t
        return oldt, 'Invalid TIMEOUT: %s' % cmdlist[-1]
    return oldt, 'The TIMEOUT=%d.' % oldt


def _cmd_cd(cmdlist, oldCWD=None):
    '''
    Check and change the working directory for next commands
    by passing 'cwd' to asyncio.create_subprocess_shell.
    Return 'cwd' value and output str.
    '''
    # os.chdir(cmdlist[-1])  # will affects all connections!
    if len(cmdlist) > 1:
        p = os.path.expanduser(cmdlist[-1])
        if os.path.isdir(p):
            return p, p
        else:
            return oldCWD, 'No such directory: %s' % cmdlist[-1]
    return None, os.getcwd()


def _cmd_bash_toggle(cmdlist, oldBASH='off'):
    ''' Toggle BASH = on/off. '''
    if len(cmdlist) > 1:
        onoff = cmdlist[-1].lower()
        if onoff in ('on', 'off'):
            return onoff, 'New BASH-mode=%s.' % onoff
        else:
            return oldBASH, 'Invalid BASH-mode: %s. (on/off)' % cmdlist[-1]
    return oldBASH, 'The BASH-mode=%s.' % oldBASH


async def _cmd_default(cmd, timeout=None, cwd=None):
    '''
    Call asyncio.create_subprocess_shell to run cmd.
    Return output str.
    '''
    proc = await asyncio.create_subprocess_shell(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=cwd)
    output = []
    try:
        await asyncio.wait_for(proc.wait(), timeout=timeout)
    except asyncio.TimeoutError as e:
        proc.kill()
        timerr = "Cmd '%s' timed out after %d seconds." % (cmd, timeout)
        output.append(timerr)
    if proc.returncode:
        stderr = await proc.stderr.read()
        errput = ('[ErrCode %d]\n' % proc.returncode) + stderr.decode()
        output.append(errput.strip())
    stdout = await proc.stdout.read()
    if stdout:
        output.append(stdout.decode().strip())
    return '\n\n'.join(output)


async def ws_download(ws, path):
    # transfer file:
    #    - relative: /download/path/to/file?chunk_size=5242880
    #    - absolute: /download//path/to/file
    #    - homepath: /download/~/path/to/file or /download/~user/path/to/file
    querypath = urlparse.urlparse(path)
    filepath = urlparse.unquote(querypath.path[10:])  # utf8 decode
    query = urlparse.parse_qs(querypath.query)
    if filepath.startswith('~'):  # homepath
        filepath = os.path.expanduser(filepath)
    try:
        size = max(int(query.get('chunk_size')[0]), 1024)  # min 1k
    except Exception:
        size = 1024*1024*5  # default 5M
    try:
        if os.path.isfile(filepath):
            with open(filepath, 'rb') as data:
                info("Sending file '%s' to client %s:%s ..."
                     % (filepath, *ws.remote_address))
                total = data.seek(0, os.SEEK_END)
                start = data.seek(0, os.SEEK_SET)
                chunk = data.read(size)
                while chunk:
                    await ws.send(chunk)
                    offset = data.seek(0, os.SEEK_CUR)
                    info("Sending file '%s' to client %s:%s ... %.0f%%"
                         % (filepath, *ws.remote_address, offset/total*100))
                    if offset > total:
                        info("'%s' still changing for client %s:%s. Break!"
                             % (filepath, *ws.remote_address))
                        break
                    chunk = data.read(size)
                info("Send file '%s' to client %s:%s. Done."
                     % (filepath, *ws.remote_address))
        else:
            info("Client %s:%s, file '%s' not found!"
                 % (*ws.remote_address, filepath))
            await ws.send("'%s' not found!" % filepath)
    # -ws.close()
    except (websockets.exceptions.ConnectionClosedError,
            websockets.exceptions.ConnectionClosedOK) as e:
        info("Client %s:%s closed!" % ws.remote_address)
    else:
        info("Close client connection from %s:%s!" % ws.remote_address)


async def ws_shell(ws, path):
    # fake shell
    # DATE = subprocess.getoutput('date')
    # UPTIME = subprocess.getoutput('uptime')
    DATE = await _cmd_default('date')
    UPTIME = await _cmd_default('uptime')
    await ws.send(welcome_msg % (DATE, UPTIME))
    await ws.send(PS1)
    TIMEOUT = 15  # default 15s
    CWD = None
    BASH = 'off'
    info("Client %s:%s default TIMEOUT=%d, CWD=%s, BASH mode=%s"
         % (*ws.remote_address, TIMEOUT, CWD or os.getcwd(), BASH))
    while True:
        try:
            bytecmd = await ws.recv()
            try:
                rawcmd = bytecmd.decode().strip()
                cmdlist = list(map(os.path.expanduser, shlex.split(rawcmd)))
                if cmdlist:
                    info("Client %s:%s get rawcmd: %s"
                         % (*ws.remote_address, rawcmd))
                    if cmdlist[0] == 'wsshell-timeout':
                        TIMEOUT, output = _cmd_timeout(
                            cmdlist,
                            oldt=TIMEOUT)
                        info("Client %s:%s TIMEOUT is: %d"
                             % (*ws.remote_address, TIMEOUT))
                    elif cmdlist[0] == 'cd':
                        CWD, output = _cmd_cd(
                            cmdlist,
                            oldCWD=CWD)
                        info("Client %s:%s CWD is: %s"
                             % (*ws.remote_address, CWD))
                    elif cmdlist[0] == 'wsshell-bash':
                        BASH, output = _cmd_bash_toggle(
                            cmdlist,
                            oldBASH=BASH)
                        info("Client %s:%s BASH mode is: %s"
                             % (*ws.remote_address, BASH))
                    else:
                        if cmdlist[0] == 'ls' and '--color' not in cmdlist:
                            cmdlist.insert(1, '--color')
                        if BASH == 'on':  # update cmdlist
                            if cmdlist[0] != 'bash':
                                # print('%r' % cmdlist)
                                cmdlist = ['bash', '-c', ' '.join(cmdlist)]
                        cmd = shlex.join(cmdlist)
                        info("Client %s:%s run cmd: %s"
                             % (*ws.remote_address, cmd))
                        output = await _cmd_default(
                            cmd,
                            timeout=TIMEOUT,
                            cwd=CWD)
                        if BASH == 'on':
                            output = ('RUN CMD: %s \n\n' % cmd) + output
                else:
                    output = ''
            except Exception as e:
                info("Client %s:%s: %s" % (*ws.remote_address, e))
                output = '%s' % e
            await ws.send(output + '\n\n' + PS1)
        except (websockets.exceptions.ConnectionClosedError,
                websockets.exceptions.ConnectionClosedOK) as e:
            info("Client %s:%s closed!" % ws.remote_address)
            return


async def ws_serve(ws, path):
    info("Client connection from %s:%s" % ws.remote_address)
    # print("ws get path: %s" % path)
    if path and path.startswith('/download/'):  # transfer file
        await ws_download(ws, path)
        return
    else:  # fake shell
        await ws_shell(ws, path)
        return


def main():
    parser = argparse.ArgumentParser(
        description=DESCRIPTION, add_help=False,
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-b', dest='bind', metavar='<address>',
                        default='127.0.0.1',
                        help='Alternate bind address '
                             '(default: %(default)s)')
    parser.add_argument('-p', dest='port', metavar='<port>',
                        default=8000, type=int,
                        help='Server port (default: %(default)d)')
    parser.add_argument('--auth', metavar='<path>',
                        default='./simple-wsshell-auth.txt',
                        help='Authorization file path.\n'
                             '  default: %(default)s')
    parser.add_argument('--pid', metavar='<path>',
                        default='./simple-wsshell-run.pid',
                        help='PID file path\n  default: %(default)s')
    parser.add_argument('--log', metavar='<path>',
                        default='./simple-wsshell-<pid>.log',
                        help='Log file path\n  default: %(default)s')
    parser.add_argument('-h', '--help', action='store_true',
                        help='Show this help message and exit')
    args = parser.parse_args()
    # print(args)
    if args.help:
        parser.print_help()
        sys.exit()
    global LOGFILE
    LOGFILE = args.log.replace('<pid>', str(os.getpid()))
    info("USER=%s, PID=%d in '%s', auth info in '%s', log in '%s'"
         % (USER, os.getpid(), args.pid, args.auth, LOGFILE))
    with open(args.pid, 'w', encoding='utf8') as p:
        p.write(str(os.getpid()))
    # authorization: ws-XXXXXX
    user_pass = []
    for i in range(3):
        user_pass.append(('ws-%s' % random_str(6), random_str(12)))
    with open(args.auth, 'w', encoding='utf8') as a:
        for u, p in user_pass:
            AUTHORIZATION.append(build_authorization_basic(u, p))
            a.write('%s:%s\n\t%s\n' % (u, p, AUTHORIZATION[-1]))
    info(f"Serving wsshell on {args.bind} port {args.port} "
         f"(ws://{args.bind}:{args.port}) ...")
    shell = websockets.serve(ws_serve, args.bind, args.port,
                             create_protocol=BasicAuthServerProtocol)
    loop = asyncio.get_event_loop()
    loop.run_until_complete(shell)

    def shutdown(sig):
        if sig.name == 'SIGINT':
            print("\nKeyboard interrupt received, exiting.")
        else:
            print("\n%s signal received, exiting." % sig.name)
        os.remove(args.auth)
        os.remove(args.pid)
        loop.stop()

    for s in [signal.SIGINT, signal.SIGTERM]:
        loop.add_signal_handler(s, functools.partial(shutdown, s))
    loop.run_forever()
    sys.exit(0)


if __name__ == '__main__':
    main()
