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
    display_filter = None

    def __init__(self, field_keys=(), workers=()):
        '''
        :param field_keys: necessary keys in :attr:`result`
        :param workers: method's names to choose information from a packet
        '''
        self.field_keys = field_keys
        self.workers = workers
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
    '''Streaming media extractor with player, ffmpeg'''

    def __init__(self, player=None, ffmpeg=None, **kwargs):
        '''
        :param player: player used in :meth:`play`
        :param ffmpeg: ffmpeg used to convert(save) media in :meth:`convert`

        Note:
        1. *fullurl* is necessary!
        2. ffmpeg can add "-i #(INPUT)#" to set options order.
        '''
        if type(player) is str and shutil.which(shlex.split(player)[0]):
            self.player = player
        else:
            self.player = None
        if type(ffmpeg) is str and shutil.which(shlex.split(ffmpeg)[0]):
            self.ffmpeg = ffmpeg
        else:
            self.ffmpeg = None
        super(StreamingExtractor, self).__init__(**kwargs)

    @property
    def intro(self):
        s = type(self).__name__
        if self.player:
            s += ", with player='%s'" % self.player
        if self.ffmpeg:
            s += ", with ffmpeg='%s'" % self.ffmpeg
        return s

    def ask(self, prompt, attr='player'):
        if getattr(self, attr, None):
            askyes = input('[ASK] ' + prompt)
            if askyes in ('y', 'yes', 'Y', 'YES'):
                return True
        else:
            self.tw.write('[Error] Cannot find %s!' % attr,
                          red=True, bold=True)
            self.tw.write(os.linesep)
        return False

    def play(self, askprompt=None, urlkey='fullurl'):
        URL = self.result.get(urlkey, None)
        if URL:
            if not askprompt:
                askprompt = "Play this %s? [y/n] " % urlkey
            if self.ask(askprompt, attr='player'):
                import subprocess
                playcmd = shlex.split(self.player) + [URL]
                self.tw.write("[Info] Play cmd: %s" % playcmd)
                self.tw.write(os.linesep)
                subprocess.run(playcmd, shell=False)
        else:
            self.tw.write('[Error] Cannot find %s!' % urlkey,
                          red=True, bold=True)
            self.tw.write(os.linesep)

    def convert(self, askprompt=None, urlkey='fullurl'):
        URL = self.result.get(urlkey, None)
        if URL:
            if not askprompt:
                askprompt = "Convert this %s? [y/n] " % urlkey
            if self.ask(askprompt, attr='ffmpeg'):
                import subprocess
                convcmd = shlex.split(self.ffmpeg)
                if '#(INPUT)#' in convcmd:
                    # ffmpeg inopt -i #(INPUT)# outopt OUT
                    idx = convcmd.index('#(INPUT)#')
                    convcmd[idx] = URL
                    if convcmd[idx-1] != '-i':
                        convcmd.insert(idx, '-i')
                else:
                    # ffmpeg -i URL opt OUT
                    convcmd.insert(1, '-i')
                    convcmd.insert(2, URL)
                output = input('[ASK] Set output file: ')
                if not output:
                    output = 'stream-output-%d.ts' % self.result['Number']
                convcmd.append(output)
                self.tw.write("[Info] Convert cmd: %s" % convcmd)
                self.tw.write(os.linesep)
                subprocess.run(convcmd, shell=False)
        else:
            self.tw.write('[Error] Cannot find %s!' % urlkey,
                          red=True, bold=True)
            self.tw.write(os.linesep)
