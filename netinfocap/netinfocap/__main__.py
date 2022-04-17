# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import os
import sys
import argparse

from .extractor import all_extractors
from .infocapture import InfoCapture
from .server import InfoServer


def main():
    parser = argparse.ArgumentParser(
        description="Netinfo Capture v0.6 by shmilee",
        add_help=False,
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('extractor', nargs='*', default='all',
                        choices=['all'] + all_extractors,
                        help='Extractors to use (default: all)\n')
    parser.add_argument('-i', dest='interface', metavar='<interface>',
                        nargs=1, default='ap0', type=str,
                        help='name of interface (default: %(default)s)')
    parser.add_argument('-n', dest='number', metavar='<number>',
                        nargs=1, default=99, type=int,
                        help='an amount of results to capture, then stop (default: 99)')
    parser.add_argument('-p', dest='player', metavar='<player>',
                        help='Stream extracted URL to a <player>')
    parser.add_argument('-f', dest='ffmpeg', metavar='<ffmpeg>',
                        help='<ffmpeg> used to convert streaming media')
    parser.add_argument('-o', dest='output', metavar='<output>',
                        help='save to <output>.json file')
    parser.add_argument('-s', '--server', action='store_true',
                        help='Start an InfoServer')
    parser.add_argument('--port', dest='port', metavar='<port>',
                        nargs=1, default=8000, type=int,
                        help='port of InfoServer (default: %(default)d)')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Show debug information')
    parser.add_argument('-h', '--help', action='store_true',
                        help='Show this help message and exit')
    args = parser.parse_args()
    # print(args)
    if args.help:
        parser.print_help()
        sys.exit()

    if args.extractor == 'all' or 'all' in args.extractor:
        args.extractor = all_extractors
    ex_kws = dict(player=args.player, ffmpeg=args.ffmpeg)
    extractors = {ex: ex_kws for ex in args.extractor}
    number = args.number[0] if isinstance(args.number, list) else args.number
    port = args.port[0] if isinstance(args.port, list) else args.port
    prefs = {}
    sslkeylog = os.getenv("SSLKEYLOGFILE", None)
    if sslkeylog and os.path.isfile(sslkeylog):
        prefs['ssl.keylog_file'] = sslkeylog
    try:
        with InfoCapture(
                extractors, mresult=number, debug=args.debug,
                interface=args.interface, override_prefs=prefs) as infocap:
            if args.server:
                server = InfoServer()
            while not infocap.collect_isfull():
                if args.server:
                    server.start(infocap.Info_Results, port=port)
                infocap.collect(output=args.output)
                if args.server:
                    server.stop()
    except Exception as e:
        print("\n[Main Error] %s!\n" % e)


if __name__ == "__main__":
    main()
