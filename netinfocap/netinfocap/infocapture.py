# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import os
import pyshark
import json
import multiprocessing

from .extractor import get_extractor


class InfoCapture(pyshark.LiveCapture):
    '''
    Collect packets from the network interface.
    Choose infor from each packet and bring them together as a dict.
    '''

    manager = multiprocessing.Manager()

    def __init__(self, extractors, mresult=999, mrestart=0, **kwargs):
        '''
        :param extractors: dict, {name: extractor_kws, ...}
        :param mresult: max results to capture, then stop.
        :param mrestart: max restart :meth:`collect`, <=0 -> min(8,mresult)
        :param kwargs: LiveCapture kwargs
            (interface, tshark_path, display_filter, debug, etc.)
        '''
        self.extractors = []
        for name in extractors:
            ex = get_extractor(name, **extractors[name])
            if ex:
                self.extractors.append(ex)
        self.Info_Results = self.manager.list()
        self.max_result = mresult
        self.max_restart = mrestart if mrestart > 0 else min(8, mresult)
        self.restart_count = -1
        filters = set([ex.display_filter for ex in self.extractors])
        kwargs['display_filter'] = ' or '.join(filters)
        super(InfoCapture, self).__init__(**kwargs)
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

    def collect_isfull(self):
        if (len(self.Info_Results) >= self.max_result
                or self.restart_count >= self.max_restart):
            return True
        else:
            return False

    def collect(self, output=None):
        '''
        :param output: save results to output.json file
        '''
        if len(self.extractors) == 0:
            self._log.critical('No extractors!')
            return
        tw = self.extractors[0].tw
        self.restart_count += 1
        start = 'Restart' if self.restart_count > 0 else 'Start'
        tw.write(os.linesep + "[Info] %s collecting ..." % start + os.linesep)
        try:
            for packet in self.sniff_continuously(packet_count=None):
                number = int(packet.number.get_default_value())
                self._log.debug('Packet %d' % number)
                for ex in self.extractors:
                    try:
                        ex.extract(packet)
                        if ex.complete:  # extractor complete state
                            self.Info_Results.append(ex.result)
                            try:
                                ex.pretty_print(count=len(self.Info_Results))
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
                if len(self.Info_Results) >= self.max_result:
                    break
        except KeyboardInterrupt:
            self._log.critical("[Interrupt] InfoCapture (collect)!")
        except EOFError:
            self._log.critical("[EOFError]!")
        except pyshark.capture.capture.TSharkCrashException:
            self._log.critical("[Error] TShark seems to have crashed!")
        if output:
            with open('%s.json' % output, 'w') as out:
                tw.write(os.linesep)
                tw.write("[Info] Save results to %s.json ..." % output)
                json.dump(list(self.Info_Results), out)
                tw.write(os.linesep)

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
