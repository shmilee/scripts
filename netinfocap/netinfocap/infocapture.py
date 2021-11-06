# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import os
import sys
import pyshark
import argparse
import json


class InfoCapture(pyshark.LiveCapture):
    '''
    Collect packets from the network interface.
    Choose infor from each packet and bring them together as a dict.
    '''

    def __init__(self, extractors, **kwargs):
        # (interface, tshark_path, display_filter, debug, etc.)
        super(InfoCapture, self).__init__(**kwargs)
        self.extractors = extractors
        for ex in self.extractors:
            ex.reset()  # reset extractor to initial state
        tw = self.extractors[0].tw
        tw.write("Capturing on '")
        tw.write(self.interfaces[0], bold=True)
        tw.write("', with display_filter: ")
        tw.write(self._display_filter, bold=True)
        tw.write(os.linesep)
        for ex in self.extractors:
            tw.write("Using extractor: %s" % ex.intro)
            tw.write(os.linesep)

    def collect(self, result_count, show=True):
        '''
        :param result_count: an amount of results to capture, then stop.
        :param show: show each result dict in terminal.
        '''
        if len(self.extractors) == 0:
            self._log.critical('No extractors!')
            return
        results = []
        try:
            for packet in self.sniff_continuously(packet_count=None):
                number = int(packet.number.get_default_value())
                self._log.debug('Packet %d' % number)
                for ex in self.extractors:
                    try:
                        ex.extract(packet)
                        if ex.complete:  # extractor complete state
                            results.append(ex.result)
                            try:
                                if show:
                                    ex.pretty_print()
                                if ex.player:  # for play streaming
                                    ex.play()
                                if ex.ffmpeg:  # for save streaming
                                    ex.convert()
                            except KeyboardInterrupt:
                                self._log.critical("[Interrupt] Extractor!")
                            finally:
                                ex.reset()
                    except Exception as e:
                        self._log.critical("Can't extract info from packet %s"
                                           % number, exc_info=1)
                if result_count and result_count > 0:
                    if len(results) >= result_count:
                        break
        except KeyboardInterrupt:
            self._log.critical("[Interrupt] InfoCapture (collect)!")
            return results
        except EOFError:
            self._log.critical("[EOFError]!")
            return results
        except pyshark.capture.capture.TSharkCrashException:
            self._log.critical("[Error] TShark seems to have crashed!")
            return results
        return results

    def _packets_from_tshark_sync(self, packet_count=None, existing_process=None):
        tshark_process = existing_process or self.eventloop.run_until_complete(
            self._get_tshark_process())
        psml_structure, data = self.eventloop.run_until_complete(
            self._get_psml_struct(tshark_process.stdout))
        packets_captured = 0

        data = b""
        try:
            while True:
                try:
                    packet, data = self.eventloop.run_until_complete(
                        self._get_packet_from_stream(tshark_process.stdout, data, psml_structure=psml_structure,
                                                     got_first_packet=packets_captured > 0))

                except EOFError:
                    self._log.debug("EOF reached (sync)")
                    self._eof_reached = True
                    break
                except KeyboardInterrupt:  # add this
                    self._log.critical("[Interrupt] Capture (sync)!")
                    break
                if packet:
                    packets_captured += 1
                    yield packet
                if packet_count and packets_captured >= packet_count:
                    break
        finally:
            if tshark_process in self._running_processes:
                self.eventloop.run_until_complete(
                    self._cleanup_subprocess(tshark_process))


allextractors = ['bilive', 'hls', 'rtmpt']


def main():
    parser = argparse.ArgumentParser(
        description="Netinfo Capture v0.1 by shmilee",
        add_help=False,
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('extractor', nargs='*', default='all',
                        choices=['all'] + allextractors,
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
        args.extractor = allextractors
    extractors = []
    for ex in args.extractor:
        if ex == 'bilive':
            from .extractor.bilive import Bilive_Url_Extractor
            extractors.append(Bilive_Url_Extractor(
                player=args.player, ffmpeg=args.ffmpeg))
        elif ex == 'hls':
            from .extractor.hls import HLS_Url_Extractor
            extractors.append(HLS_Url_Extractor(
                player=args.player, ffmpeg=args.ffmpeg))
        elif ex == 'rtmpt':
            from .extractor.rtmpt import RTMPT_Url_Extractor
            extractors.append(RTMPT_Url_Extractor(
                player=args.player, ffmpeg=args.ffmpeg))
    filters = ' or '.join(set([ex.display_filter for ex in extractors]))
    if isinstance(args.number, list):
        args.number = args.number[0]
    try:
        res = []
        interrupt = 0
        with InfoCapture(
                tuple(extractors), interface=args.interface,
                display_filter=filters, debug=args.debug) as infocap:
            while len(res) < args.number and interrupt < args.number:
                start = 'Restart' if interrupt > 0 else 'Start'
                print("\n[Main Info] %s collecting ...\n" % start)
                res.extend(infocap.collect(args.number-len(res), show=True))
                interrupt += 1
    except pyshark.capture.capture.TSharkCrashException:
        print("\n[Main Error] TShark seems to have crashed!\n")
    finally:
        with open('%s.json' % args.output, 'w') as out:
            json.dump(res, out)
