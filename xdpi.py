#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2022 shmilee

import subprocess
import shlex
import re

# monitors number N
NPAT = re.compile(r'Monitors:\s*(?P<N>\d+?)')
# monitors WxH(resolution), wxh(physical), X+Y(resolution)
# eg: 3840/1220x2160/690+1366+0
WHwhXY = r'(?P<W>\d+?)/(?P<w>\d+?)x(?P<H>\d+?)/(?P<h>\d+?)\+(?P<X>\d+?)\+(?P<Y>\d+?)'
# monitors i(index), p(primary), n1(name), n2(name)
MPAT = re.compile(
    r'\s*(?P<i>\d+?):\s*(\+){0,1}(?P<p>\*){0,1}(?P<n1>\w+)\s*' + WHwhXY + r'\s*(?P<n2>\w+)$')


class Monitors(object):
    '''
    List monitor's infor.
    '''

    def __init__(self, xrandr=None):
        self.xrandr = xrandr or "xrandr"
        self.cmd = shlex.split(self.xrandr + " --listmonitors")
        self.info = self.parse(self.output)

    def update(self):
        self.info = self.parse(self.output)

    @property
    def output(self):
        return subprocess.check_output(self.cmd).decode("utf-8")

    def parse(self, output):
        '''
        output like this:
        Monitors: 2
         0: +*eDP1 1366/310x768/170+0+0  eDP1
         1: +HDMI1 3840/1220x2160/690+1366+0  HDMI1
        '''
        res = {}
        outputs = output.split('\n')
        m = re.match(NPAT, outputs[0])
        if m:
            N = int(m.groupdict()['N'])
            res['N'] = N
        else:
            N = 0
        res['highW>1920'] = []
        res['lowDPI<96'] = []
        for line in outputs[1:N+1]:
            m = re.match(MPAT, line)
            if m:
                gd = m.groupdict()
                NAME = 'm' + gd['i']
                if gd['p']:
                    res['primary'] = NAME
                W = int(gd['W'])
                if W > 1920:
                    res['highW>1920'].append((NAME, round(W/1920, 2)))
                H = int(gd['H'])
                w = int(gd['w'])
                h = int(gd['h'])
                dpix = round(W/(w/10/2.54), 2)
                dpiy = round(H/(h/10/2.54), 2)
                DPI = round((W**2+H**2)**0.5/((w**2+h**2)**0.5/10/2.54), 2)
                if DPI < 96:
                    res['lowDPI<96'].append((NAME, round(96/DPI, 2)))
                res[NAME] = dict(
                    index=int(gd['i']),
                    name1=gd['n1'],
                    name2=gd['n2'],
                    W=W, H=H,
                    w=w, h=h,
                    X=int(gd['X']),
                    Y=int(gd['Y']),
                    dpix=dpix, dpiy=dpiy, DPI=DPI,
                )
        return res


# TODO: https://blog.summercat.com/configuring-mixed-dpi-monitors-with-xrandr.html
if __name__ == '__main__':
    import pprint
    M = Monitors()
    pprint.pprint(M.parse(M.output))
