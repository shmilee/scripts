# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import os
import sys
import pyshark
import argparse


class InfoCapture(pyshark.LiveCapture):
    '''
    Collect packets from the network interface.
    Choose infor from each packet and bring them together as a dict.
    '''

    def __init__(self, extractors, **kwargs):
        # (interface, tshark_path, display_filter, debug, etc.)
        super(InfoCapture, self).__init__(**kwargs)
        self.extractors = extractors

    def collect(self, packet_count=None, save=True, show=True):
        '''
        :param packet_count: an amount of packets to capture, then stop.
        :param save: save each result dict to a list.
        :param show: show each result dict in terminal.
        '''
        if save:
            results = []
        if len(self.extractors) == 0:
            self._log.critical('No extractors!')
            return
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
        count = 1
        for packet in self.sniff_continuously(packet_count=packet_count):
            number = int(packet.number.get_default_value())
            self._log.debug('Packet %d, count: %d' % (number, count))
            count += 1
            for ex in self.extractors:
                try:
                    ex.extract(packet)
                    if ex.complete:  # extractor complete state
                        res = ex.result
                        if save:
                            results.append(res)
                        if show:
                            ex.pretty_print()
                        if ex.player:  # for play streaming
                            ex.play()
                        if ex.ffmpeg:  # for save streaming
                            ex.convert()
                        ex.reset()
                except Exception as e:
                    self._log.critical('Cannot extract info from packet %s'
                                       % number, exc_info=1)
        if save:
            return results


def main():
    parser = argparse.ArgumentParser(
        description="Netinfo Capture v0.1 by shmilee",
        add_help=False,
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('extractor', nargs='*', default='bilive',
                        choices=['bilive', 'hls', 'rtmpt'],
                        help='Extractors to use (default: %(default)s)\n')
    parser.add_argument('-i',  dest='interface', metavar='<interface>',
                        nargs=1, default='ap0', type=str,
                        help='name of interface (default: %(default)s)')
    parser.add_argument('-p', dest='player', metavar='<player>',
                        help='Stream extracted URL to a <player>')
    parser.add_argument('-f', dest='ffmpeg', metavar='<ffmpeg>',
                        help='<ffmpeg> used to convert streaming media')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Show debug information')
    parser.add_argument('-h', '--help', action='store_true',
                        help='Show this help message and exit')
    args = parser.parse_args()
    if args.help:
        parser.print_help()
        sys.exit()

    if isinstance(args.extractor, str):
        args.extractor = [args.extractor]
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
    filters = set([ex.display_filter for ex in extractors])
    infocap = InfoCapture(
        tuple(extractors), interface=args.interface,
        display_filter=' or '.join(filters), debug=args.debug)
    infocap.collect(show=True)
