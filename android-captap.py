#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2022 shmilee

'''
screencap
input tap
'''

import io
import os
import sys
import time
import numpy as np
import random
import subprocess
import pytesseract
from PIL import Image, ImageDraw


class Task(object):
    '''
    Task TODO.
    '''

    def __int__(self):
        pass

    def capture_screen(self):
        '''Get screenshot, png data bytes, return PIL Image instance'''
        cmd = 'adb shell screencap -p'
        with subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE) as p:
            s = p.stdout.read()
            if sys.platform == 'win32':
                s = s.replace(b'\r\n', b'\n')
            return Image.open(io.BytesIO(s))

    def find_text(self, im, x, y, w, h, greyscale=False):
        '''Return text get from Box(x,y,w,h) in image *im*'''
        img = im if isinstance(im, Image.Image) else Image.open(im)
        region = img.crop((x, y, x+w, y+h))
        if greyscale:
            region = region.convert('L')
        text = pytesseract.image_to_string(region, lang='chi_sim').strip()
        print(f' >> Find text: {text}')
        return text

    def locate_xy(self, im, pat, samples=9, partial=1):
        '''
        Find position of *pat* image over *im* image, return x,y,w,h
        partial: search area.
             1 | 2
            ---|---
             3 | 4
        '''
        # ref: https://stackoverflow.com/questions/21338431
        img = im if isinstance(im, Image.Image) else Image.open(im)
        pattern = pat if isinstance(pat, Image.Image) else Image.open(pat)
        pixels = []
        for i in range(samples):
            x = random.randint(0, pattern.size[0] - 1)
            y = random.randint(0, pattern.size[1] - 1)
            pixel = pattern.getpixel((x, y))
            if pixel[-1] > 200:  # ?alpha?
                pixels.append(((x, y), pixel[:-1]))

        def diff(a, b):
            return sum((a - b) ** 2 for a, b in zip(a, b))
        best = []
        x, y = img.size
        xrange = range(x//2) if partial in (1, 3) else range(x//2, x)
        yrange = range(y//2) if partial in (1, 2) else range(y//2, y)
        for x in xrange:
            for y in yrange:
                d = 0
                for coor, pixel in pixels:
                    try:
                        ipixel = img.getpixel((x + coor[0], y + coor[1]))
                        d += sum((a-b)**2 for a, b in zip(ipixel, pixel))
                    except IndexError:
                        d += 3*256**2
                if d == 0:
                    print(f' >> Find x,y= {x}, {y}')
                    return x, y, pattern.size[0], pattern.size[1]
                best.append((d, x, y))
                best.sort(key=lambda x: x[0])
                best = best[:3]
        print(' >> Best 3 matches:', best)
        d, x, y = map(int, np.array(best).mean(axis=0))
        print(f' >> Find mean x,y= {x}, {y}')
        return x, y, pattern.size[0], pattern.size[1]

    def touch_screen(self, cmd, *args):
        '''Run input cmd for touchscreen'''
        if cmd in ['text', 'tap', 'swipe', 'draganddrop']:
            full_cmd = f'adb shell input {cmd} ' + ' '.join(map(str, args))
            with subprocess.Popen(full_cmd, shell=True) as p:
                pass
        else:
            print('Invalid cmd:', cmd)


def task1(limit=1600e4//2, sleep=1, max_try=100):
    print('==TEST TASK 1==')
    refresh = os.path.expanduser('~/图片/sswd/1-refresh.png')
    zhan = os.path.expanduser('~/图片/sswd/2-zhan.png')
    tt = Task()
    img = tt.capture_screen()
    print(' >> Getting X1, Y1 ...')
    x, y, w, h = tt.locate_xy(img, refresh, partial=4)
    X1, Y1 = x+w//2, y+h//2
    print(' >> Getting X2, Y2 ...')
    X2, Y2, w, H2 = tt.locate_xy(img, zhan, partial=1)
    W2 = w*5
    print('>>>> Start ...')
    for i in range(1, max_try+1):
        text = tt.find_text(img, X2, Y2, W2, H2).split()
        n = text[-1] if text and len(text) > 1 else (' '*8)
        if n.isdigit() and int(n) < limit:
            print(f' >> [{i}] Get number: {n}. STOP!')
            ask = input('Enter to continue. "y" to break. ')
            if ask in ('y', 'Y'):
                break
        else:
            print(f' >> [{i}] Get number: {n}. Auto-refresh after {sleep}s.')
        tt.touch_screen('tap', X1, Y1)
        time.sleep(sleep)
        img = tt.capture_screen()
        if n == (' '*8):
            # reset X2,Y2
            print(' >> Getting new X2, Y2 ...')
            X2, Y2, _, _ = tt.locate_xy(img, zhan, partial=1)


if __name__ == '__main__':
    task1()
