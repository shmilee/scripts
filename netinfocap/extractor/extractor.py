# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

import os
import py
import shutil
import shlex


class Extractor(object):
    '''
    Choose information from some packets then bring them together as a dict.
    '''

    def __init__(self, field_keys=(), workers=(), tw=None):
        '''
        :param field_keys: necessary keys in :attr:`result`
        :param workers: method's names to choose information from a packet
        :param tw: py.io.TerminalWriter instance
        '''
        self.field_keys = field_keys
        self.workers = workers
        if isinstance(tw, py.io.TerminalWriter):
            self.tw = tw
        else:
            self.tw = py.io.TerminalWriter()
        self.result = {'Number': 0}

    @property
    def intro(self):
        return type(self).__name__

    def reset(self):
        num = self.result['Number'] + 1
        self.result = {'Number': num}

    @property
    def complete(self):
        '''
        If the dict has all field_keys, complete state is True.
        '''
        state = True
        for key in self.field_keys:
            if key not in self.result:
                state = False
                break
        return state

    def extract(self, packet):
        '''
        Use workers to choose information and update :attr:`result`.
        '''
        for worker in self.workers:
            method = getattr(self, worker)
            method(packet)

    def pretty_print(self):
        ''':param tw: py.io.TerminalWriter instance'''
        res = self.result
        self.tw.write(os.linesep + '*'*50 + os.linesep*2)
        self.tw.write('(%s) ' % type(self).__name__, yellow=True, bold=True)
        self.tw.write('Number: %d' % res['Number'], yellow=True, bold=True)
        self.tw.write(os.linesep)
        extra = [k for k in res if k not in self.field_keys and k != 'Number']
        for k in list(self.field_keys) + extra:
            val = res.get(k, None)
            self.tw.write('\t%s: ' % k, green=True, bold=True)
            self.tw.write(val, bold=True)
            self.tw.write(os.linesep)
        self.tw.write(os.linesep)


class StreamingExtractor(Extractor):
    '''Streaming media extractor with player'''

    def __init__(self, field_keys=('fullurl',), player=None, **kwargs):
        '''
        :param player: player used in :meth:`play`

        Note: *fullurl* is necessary!
        '''
        if type(player) is str and shutil.which(shlex.split(player)[0]):
            self.player = player
        else:
            self.player = None
        super(StreamingExtractor, self).__init__(
            field_keys=field_keys, **kwargs)

    @property
    def intro(self):
        if self.player:
            return "%s, with player '%s'" % (type(self).__name__, self.player)
        else:
            return type(self).__name__

    def askplay(self, prompt):
        if self.player:
            askyes = input('[ASK] ' + prompt)
            if askyes in ('y', 'yes', 'Y', 'YES'):
                return True
        else:
            self.tw.write('[Error] Cannot find player!', red=True, bold=True)
        return False

    def play(self, askprompt="Play this fullurl? [y/n] "):
        URL = self.result.get('fullurl', None)
        if URL:
            if self.askplay(askprompt):
                import subprocess
                playcmd = shlex.split(self.player) + [URL]
                self.tw.write("[Info] Playcmd: %s" % playcmd)
                subprocess.run(playcmd, shell=False)
        else:
            self.tw.write('[Error] Cannot find fullurl!', red=True, bold=True)
