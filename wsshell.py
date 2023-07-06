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
DATE = subprocess.getoutput('date')
UPTIME = subprocess.getoutput('uptime')
welcome_msg = """Welcome to %s (%s %s)

 * Date: %s
 * Uptime: %s

%s
 * Only support non-interactive commands!
 * Complicated shell commands should be: bash -c 'XX | YY >a.out'
 * Change the working directory by 'cd', like 'cd ~', 'cd', 'cd /xxx'
 * Set timeout for next commands by 'wsshell-timeout Number'.

""" % (HOST, OSNAME, KERNEL, DATE, UPTIME, DESCRIPTION)


def info(msg):
    s = time.strftime('%F %H:%M:%S')
    print('[%s] - %s' % (s, msg))


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
            authorization = request_headers['Authorization']
        except KeyError:
            info("Miss authorization for %s:%s" % self.remote_address)
            return http.HTTPStatus.UNAUTHORIZED, [], b'Missing credentials\n'
        # info("get authorization: %s" % authorization)
        u = parse_authorization_basic(authorization)[0]
        if authorization not in AUTHORIZATION:
            info("Incorrect authorization for %s from %s:%s"
                 % (u, *self.remote_address))
            return http.HTTPStatus.FORBIDDEN, [], b'Incorrect credentials\n'
        info("Get correct authorization for %s from %s:%s"
             % (u, *self.remote_address))


def _cmd_timeout(cmdlist, oldt=30):
    '''
    Check and change the timeout for asyncio.wait_for.
    Return 'timeout' value and output str.
    '''
    if len(cmdlist) > 1:
        if cmdlist[-1].isdigit():
            t = int(cmdlist[-1])
            if t > 0:
                return t, 'New timeout=%d.' % t
        return oldt, 'Invalid timeout: %s' % cmdlist[-1]
    return oldt, 'The timeout=%d.' % oldt


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
        errput = ('[ErrCode %d] ' % proc.returncode) + stderr.decode()
        output.append(errput.strip())
    stdout = await proc.stdout.read()
    if stdout:
        output.append(stdout.decode().strip())
    return '\n\n'.join(output) + '\n'


async def ws_shell(ws, path):
    info("Client connection from %s:%s" % ws.remote_address)
    await ws.send(welcome_msg)
    await ws.send(PS1)
    TIMEOUT = 15  # default 15s
    CWD = None
    while True:
        try:
            cmd = await ws.recv()
            try:
                cmd = cmd.decode().strip()
                cmdlist = shlex.split(cmd)
                cmd = shlex.join(cmdlist)
                if cmdlist:
                    info("Client %s:%s run cmd: %s"
                         % (*ws.remote_address, cmd))
                    if cmdlist[0] == 'wsshell-timeout':
                        TIMEOUT, output = _cmd_timeout(
                            cmdlist,
                            oldt=TIMEOUT)
                    elif cmdlist[0] == 'cd':
                        CWD, output = _cmd_cd(
                            cmdlist,
                            oldCWD=CWD)
                    else:
                        output = await _cmd_default(
                            cmd,
                            timeout=TIMEOUT,
                            cwd=CWD)
                else:
                    output = ''
            except Exception as e:
                info("Client %s:%s: %s" % (*ws.remote_address, e))
                output = '%s' % e
            await ws.send(output + '\n' + PS1)
        except (websockets.exceptions.ConnectionClosedError,
                websockets.exceptions.ConnectionClosedOK) as e:
            info("Client %s:%s closed!" % ws.remote_address)
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
                        help='Authorization file path. '
                             '(default: %(default)s)')
    parser.add_argument('--pfile', metavar='<path>',
                        default='./simple-wsshell-run.pid',
                        help='PID file path (default: %(default)s)')
    parser.add_argument('-h', '--help', action='store_true',
                        help='Show this help message and exit')
    args = parser.parse_args()
    # print(args)
    if args.help:
        parser.print_help()
        sys.exit()
    info("USER=%s, PID=%d in '%s', auth info in '%s'"
         % (USER, os.getpid(), args.pfile, args.auth))
    with open(args.pfile, 'w', encoding='utf8') as p:
        p.write(str(os.getpid()))
    # authorization: ws-XXXXXX
    user_pass = []
    for i in range(3):
        user_pass.append(('ws-%s' % random_str(6), random_str(12)))
    with open(args.auth, 'w', encoding='utf8') as a:
        for u, p in user_pass:
            AUTHORIZATION.append(build_authorization_basic(u, p))
            a.write('%s:%s\n' % (u, p))
    info(f"Serving wsshell on {args.bind} port {args.port} "
         f"(ws://{args.bind}:{args.port}) ...")
    shell = websockets.serve(ws_shell, args.bind, args.port,
                             create_protocol=BasicAuthServerProtocol)
    loop = asyncio.get_event_loop()
    loop.run_until_complete(shell)

    def shutdown(sig):
        if sig.name == 'SIGINT':
            print("\nKeyboard interrupt received, exiting.")
        else:
            print("\n%s signal received, exiting." % sig.name)
        os.remove(args.auth)
        os.remove(args.pfile)
        loop.stop()

    for s in [signal.SIGINT, signal.SIGTERM]:
        loop.add_signal_handler(s, functools.partial(shutdown, s))
    loop.run_forever()
    sys.exit(0)


if __name__ == '__main__':
    main()
