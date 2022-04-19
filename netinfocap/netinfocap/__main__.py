# -*- coding: utf-8 -*-

# Copyright (c) 2021-2022 shmilee

import os
import sys
import json
import argparse
import readline

from .extractor import all_extractors
from .infocapture import InfoCapture
from .server import InfoServer


def main():
    parser = argparse.ArgumentParser(
        description="Netinfo Capture v0.8 by shmilee",
        add_help=False,
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('extractor', nargs='*', default='all',
                        choices=['all'] + all_extractors,
                        help='Extractors to use (default: all)\n')
    parser.add_argument('-i', dest='interface', metavar='<interface>',
                        nargs=1, default='ap0', type=str,
                        help='Name of interface (default: %(default)s)')
    parser.add_argument('-n', dest='number', metavar='<number>',
                        nargs=1, default=99, type=int,
                        help='An amount of results to capture, then stop (default: 99)')
    parser.add_argument('-p', dest='player', metavar='<player>',
                        help='Stream extracted URL to a <player>')
    parser.add_argument('-f', dest='ffmpeg', metavar='<ffmpeg>',
                        help='<ffmpeg> used to convert streaming media')
    parser.add_argument('-o', dest='output', metavar='<output>',
                        help='Save results to <output>.json file')
    parser.add_argument('--overwrite', action='store_true',
                        help='Overwrite existing <output>.json, default false')
    parser.add_argument('-s', '--server', action='store_true',
                        help='Start an InfoServer')
    parser.add_argument('--port', dest='port', metavar='<port>',
                        nargs=1, default=8000, type=int,
                        help='Port of InfoServer (default: %(default)d)')
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
    output = '%s.json' % args.output if args.output else None
    try:
        old_results = []
        if output and os.path.exists(output):  # os.path.isfile
            if args.overwrite:
                print("[WARNING] Results in %s will be overwritten, "
                      "if we get new results!" % output)
            else:
                with open(output, 'r', encoding='utf8') as out:
                    old_results = json.load(out)['results']
        L_old = len(old_results)
        if L_old > 0:
            print("[Info] Reload %d results in '%s'." % (L_old, output))
        control_keys = ('Index', 'Number', 'Family', 'Field_Keys')  # default
        with InfoCapture(
                extractors, max_result=number, debug=args.debug,
                interface=args.interface, override_prefs=prefs) as infocap:
            control_keys = infocap.extractors[0].control_keys
            if args.server:
                server = InfoServer()
            while not infocap.collect_isfull():
                if args.server:
                    server.start(infocap.Info_Results, port=port)
                L_new = len(infocap.Info_Results)
                infocap.collect_info(start_index=L_old+L_new+1)
                if args.server:
                    server.stop()
                if not infocap.collect_isfull():
                    askyes = input("\n[Interrupt] Stop collecting?")
                    if askyes in ('y', 'yes', 'Y', 'YES'):
                        break
            old_results.extend(list(infocap.Info_Results))
        L_all = len(old_results)
        if output and L_all > 0 and L_all > L_old:
            with open(output, 'w', encoding='utf8') as out:
                print()
                print("[Info] Save %d results to %s ..." % (L_all, output))
                json.dump(dict(
                    version=1,
                    control_keys=control_keys,
                    results=old_results,
                ), out, ensure_ascii=False)
    except Exception as e:
        print("\n[Main Error] %s!\n" % e)


if __name__ == "__main__":
    main()
