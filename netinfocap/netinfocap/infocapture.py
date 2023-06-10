# -*- coding: utf-8 -*-

# Copyright (c) 2021-2022 shmilee

import os
import pyshark
import multiprocessing

from .extractor import get_extractor


class InfoCapture(pyshark.LiveCapture):
    '''
    Collect packets from the network interface.
    Choose infor from each packet and bring them together as a dict.
    '''

    manager = multiprocessing.Manager()

    def __init__(self, extractors, max_result=999, **kwargs):
        '''
        :param extractors: dict, {name: extractor_kws, ...}
        :param max_result: max results to capture, then stop.
        :param kwargs: LiveCapture kwargs
            (interface, tshark_path, display_filter, debug, etc.)
        '''
        self.extractors = []
        for name in extractors:
            ex = get_extractor(name, **extractors[name])  # initial state
            if ex:
                self.extractors.append(ex)
        self.Info_Results = self.manager.list()
        self.max_result = max_result
        filters = set([ex.display_filter for ex in self.extractors])
        kwargs['display_filter'] = ' or '.join(filters)
        super(InfoCapture, self).__init__(**kwargs)
        tw = self.extractors[0].tw
        tw.write("Capturing on '")
        tw.write(self.interfaces[0], bold=True)
        tw.write("', with display_filter: ")
        tw.write(self._display_filter, bold=True)
        tw.write(os.linesep)
        for ex in self.extractors:
            tw.write("Using extractor: %s" % ex.intro)
            tw.write(os.linesep)

    def collect_isfull(self):
        return len(self.Info_Results) >= self.max_result

    def collect_info(self, start_index=1, mrpp=5):
        '''
        :param start_index: int, start index for results
        :param mrpp: int, max results for per tshark process
        '''
        if len(self.extractors) == 0:
            self._log.critical('No extractors!')
            return
        tw = self.extractors[0].tw
        tw.write(os.linesep + "[Info] Start collecting ..." + os.linesep)
        _run = self.eventloop.run_until_complete
        index, count, process, packet = start_index, mrpp, None, None
        parser = self._setup_tshark_output_parser()
        try:
            while not self.collect_isfull():
                if count >= mrpp:  # reset process
                    if process and process in self._running_processes:
                        tw.write("Restarting tshark process ..." + os.linesep)
                        _run(self._cleanup_subprocess(process))
                    process = _run(self._get_tshark_process())
                    count, packets_captured, data = 0, 0, b""
                try:
                    packet, data = _run(parser.get_packets_from_stream(
                        process.stdout, data,
                        got_first_packet=packets_captured > 0))
                except EOFError:
                    self._log.debug("EOF reached (sync)")
                    self._eof_reached = True
                    break
                if packet:
                    packets_captured += 1
                    number = int(packet.number.get_default_value())
                    self._log.debug('Packet %d' % number)
                    for ex in self.extractors:
                        try:
                            ex.extract(packet)
                            if ex.complete:  # extractor complete state
                                ex.pretty_print(index=index)
                                try:
                                    if ex.player:  # for play streaming
                                        ex.play()
                                    if ex.ffmpeg:  # for save streaming
                                        ex.convert()
                                finally:
                                    self.Info_Results.append(ex.result)
                                    ex.reset()
                                index += 1
                                count += 1
                        except Exception as e:
                            self._log.critical(
                                "Can't extract info from packet %s"
                                % number, exc_info=1)
        except KeyboardInterrupt:
            self._log.critical("[Interrupt] InfoCapture (collect)!")
        except pyshark.capture.capture.TSharkCrashException:
            self._log.critical("[Error] TShark seems to have crashed!")
        finally:
            if process and process in self._running_processes:
                _run(self._cleanup_subprocess(process))
