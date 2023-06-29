#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2023 shmilee

import os
import sys
import time
import getpass
import argparse
import asyncio
import signal
import functools
import subprocess
import websockets

USER = getpass.getuser()
HOST = subprocess.getoutput('hostname')
if USER == 'root':
    PS1 = '[%s@%s]# ' % (USER, HOST)
else:
    PS1 = '[%s@%s]$ ' % (USER, HOST)


def info(msg):
    s = time.strftime('%F %H:%M:%S')
    print('[%s] - %s' % (s, msg))


async def ws_shell(ws, path):
    info("Client connection from %s:%s" % ws.remote_address)
    await ws.send(PS1)
    while True:
        try:
            cmd = await ws.recv()
            info("Client %s:%s run cmd:  %s"
                 % (*ws.remote_address, cmd.decode().strip()))
            output = subprocess.getoutput(cmd) + '\n'
            await ws.send(output + PS1)
        except websockets.exceptions.ConnectionClosedError as e:
            info("Client %s:%s closed!" % ws.remote_address)
            return


def main():
    parser = argparse.ArgumentParser(
        description="A simple websocket shell v0.1 by shmilee",
        add_help=False,
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-b', dest='bind', metavar='<address>',
                        default='127.0.0.1',
                        help='Alternate bind address '
                             '(default: %(default)s)')
    parser.add_argument('-p', dest='port', metavar='<port>',
                        nargs=1, default=8000, type=int,
                        help='Server port (default: %(default)d)')
    parser.add_argument('--pfile', metavar='<file>',
                        default='./simple-wsshell-run.pid',
                        help='PID file path (default: %(default)s)')
    parser.add_argument('-h', '--help', action='store_true',
                        help='Show this help message and exit')
    args = parser.parse_args()
    # print(args)
    if args.help:
        parser.print_help()
        sys.exit()
    info("USER=%s, PID=%d in file: %s"
         % (getpass.getuser(), os.getpid(), args.pfile))
    with open(args.pfile, 'w', encoding='utf8') as p:
        p.write(str(os.getpid()))
    info(f"Serving wsshell on {args.bind} port {args.port}"
         f"(ws://{args.bind}:{args.port}) ...")
    shell = websockets.serve(ws_shell, args.bind, args.port)
    loop = asyncio.get_event_loop()
    loop.run_until_complete(shell)

    def shutdown(sig):
        if sig.name == 'SIGINT':
            print("\nKeyboard interrupt received, exiting.")
        else:
            print("\n%s signal received, exiting." % sig.name)
        os.remove(args.pfile)
        loop.stop()

    for s in [signal.SIGINT, signal.SIGTERM]:
        loop.add_signal_handler(s, functools.partial(shutdown, s))
    loop.run_forever()
    sys.exit(0)


if __name__ == '__main__':
    main()
