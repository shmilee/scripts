# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import os
import re

from .extractor import StreamingExtractor


class RTMPT_Url_Extractor(StreamingExtractor):
    '''Get RTMPT connect/play url from Packet.'''
    display_filter = 'rtmpt'

    def __init__(self, player=None, tw=None):
        field_keys = ('connect', 'play', 'fullurl')
        workers = ('get_rtmpt_connect', 'get_rtmpt_play')
        super(RTMPT_Url_Extractor, self).__init__(
            field_keys=field_keys, workers=workers, player=player, tw=tw)

    def get_rtmpt_connect(self, packet):
        ''' TCP/RTMPT Packet -> Layer RTMPT -> amf_string 'connect' '''
        try:
            if packet.rtmpt.amf_string == 'connect':
                alt = packet.rtmpt.amf_string.alternate_fields
                if alt[2].get_default_value() == 'tcUrl':
                    self.result['connect'] = alt[3].get_default_value()
                    self.join_connect_play()
        except Exception:
            pass

    def get_rtmpt_play(self, packet):
        ''' TCP/RTMPT Packet -> Layer RTMPT -> amf_string 'play' '''
        try:
            if packet.rtmpt.amf_string == 'play':
                alt = packet.rtmpt.amf_string.alternate_fields
                self.result['play'] = alt[0].get_default_value()
                play = self.result['play'].split('?')[0]
                self.result['id'] = play.split('_')[0]
                self.join_connect_play()
        except Exception:
            pass

    def join_connect_play(self):
        '''join connect/play -> fullurl'''
        if 'connect' in self.result and 'play' in self.result:
            fullurl = '/'.join((self.result['connect'], self.result['play']))
            if (re.match('rtmp.*live/s.*wsSecret=.*wsTime=.*sign.*', fullurl)
                    and len(fullurl) > 250):
                fullurl = fullurl + os.linesep
            self.result['fullurl'] = fullurl
