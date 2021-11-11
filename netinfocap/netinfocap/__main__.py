# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import sys
import argparse

from .extractor import all_extractors
from .infocapture import InfoCapture


def main():
    parser = argparse.ArgumentParser(
        description="Netinfo Capture v0.1 by shmilee",
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
    parser.add_argument('-o', dest='output', metavar='<output>', default='output',
                        help='save to <output>.json file (default: %(default)s)')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Show debug information')
    parser.add_argument('-h', '--help', action='store_true',
                        help='Show this help message and exit')
    args = parser.parse_args()
    if args.help:
        parser.print_help()
        sys.exit()

    if args.extractor == 'all' or 'all' in args.extractor:
        args.extractor = all_extractors
    ex_kws = dict(player=args.player, ffmpeg=args.ffmpeg)
    extractors = {ex: ex_kws for ex in args.extractor}
    if isinstance(args.number, list):
        args.number = args.number[0]
    try:
        with InfoCapture(extractors, mresult=args.number, debug=args.debug,
                         interface=args.interface) as infocap:
            from .server import InfoServer
            server = InfoServer()
            while not infocap.collect_isfull():
                server.start(infocap.Info_Results, port=8000)
                infocap.collect(output=args.output)
                server.stop()
    except Exception as e:
        print("\n[Main Error] %s!\n" % e)


if __name__ == "__main__":
    main()
