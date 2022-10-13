#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2022 shmilee

'''
screencap
input tap
'''

import io
import os
import re
import sys
import time
import json
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

    def crop(self, img, xywh):
        '''*img*: Image instance'''
        x, y, w, h = xywh
        return img.crop((x, y, x+w, y+h))

    def find_text(self, im, xywh=None, greyscale=False):
        '''Return text get from Box(x,y,w,h) in image *im*'''
        try:
            img = im if isinstance(im, Image.Image) else Image.open(im)
            region = self.crop(img, xywh) if xywh else img
            if greyscale:
                region = region.convert('L')
            text = pytesseract.image_to_string(region, lang='chi_sim').strip()
            print(f' >> Find text: {text}')
        except Exception as e:
            print(' !! Error when find text!', e)
            text = ''
        return text

    def save_img(self, im, path, xywh=None):
        '''Save Box(x,y,w,h) in image *im* to *path*. If no xywh, save all.'''
        try:
            img = im if isinstance(im, Image.Image) else Image.open(im)
            region = self.crop(img, xywh) if xywh else img
            region.save(path, 'PNG')
            print(f' >> Save image to {path}. Done.')
        except Exception as e:
            print(f' !! Error when save image to {path}!', e)

    def highlight(self, im, color=(0, 0, 0), delta=(9, 9, 9),
                  xywh=None, binarize=False):
        '''
        Highlight selected RGB color and edit background in image *im*.
        Return Box(x,y,w,h) part or whole image.

        Note:
        -----
        1. Get *color* by GIMP pick color info.
        2. Test mean color, std delta
           and (maxColor+minColor)//2, (maxColor-minColor)//2
        '''
        try:
            # ref: https://stackoverflow.com/questions/1616767
            img = im if isinstance(im, Image.Image) else Image.open(im)
            region = self.crop(img, xywh) if xywh else img
            data = np.array(region.convert('RGB'))
            ysize, xsize, _ = data.shape
            (rc, gc, bc), (rd, gd, bd) = color, delta
            dis = rd**2 + gd**2 + bd**2
            a2 = rc**2 + gc**2 + bc**2
            for y in range(ysize):
                for x in range(xsize):
                    r, g, b = data[y, x, :]
                    # if abs(r-rc)<=rd and abs(g-gc)<=gd and abs(b-bc)<=bd:
                    if (r-rc)**2 + (g-gc)**2 + (b-bc)**2 <= dis:
                        if binarize:
                            data[y, x, :] = 0
                    else:
                        if binarize:
                            data[y, x, :] = 255
                        else:
                            data[y, x, :] = 0 if a2 > 48768 else 255
            return Image.fromarray(data, mode='RGB')
        except Exception as e:
            print(f' !! Error when highlight image!', e)
            return None

    def locate_xy(self, im, pat, samples=9, partial=0):
        '''
        Find position of *pat* image over *im* image, return x,y,w,h
        partial: search area. default 0 for all
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
        if partial in (1, 2, 3, 4):
            x, y = img.size
            xrange = range(x//2) if partial in (1, 3) else range(x//2, x)
            yrange = range(y//2) if partial in (1, 2) else range(y//2, y)
        else:
            xrange, yrange = range(x), range(y)
        best = []
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


def task1(key, limit=1/2, sleep=0.5, max_try=200, save=None):
    print(f'=== TEST TASK 1: key={key}, limit={limit:.2f} ===')
    refresh = os.path.expanduser('~/图片/sswd/1-refresh.png')
    zhan = os.path.expanduser('~/图片/sswd/2-zhan.png')
    tt = Task()
    img = tt.capture_screen()
    print(' >> Getting X1, Y1 ...')
    x, y, w, h = tt.locate_xy(img, refresh, partial=4)
    X1, Y1 = x+w//2, y+h//2
    print(' >> Getting X2, Y2 ...')  # top-left, 30
    X2, Y2, w, H2 = tt.locate_xy(img, zhan, partial=1)
    W2 = w*4
    print('>>>> Start ...')
    limit = key*limit
    check_pat = r'^战\s*.\s+\d+$'
    refresh_str = f'Auto-refresh after {sleep}s'
    if save:
        coll_N = []
    for i in range(1, max_try+1):
        text = tt.find_text(tt.highlight(
            img, color=(215, 160, 16), delta=(40, 60, 16),
            xywh=(X2, Y2, W2, H2), binarize=True))
        if re.match(check_pat, text):
            n = int(text.split()[-1])
            if save:
                coll_N.append(n)
            if n < limit:
                print(f' >> [{i}] Get number: {n}. STOP!')
                ask = input('Enter to continue. "y" to break. ')
                if ask in ('y', 'Y'):
                    break
            else:
                print(f' >> [{i}] Get number: {n}. {refresh_str}.')
        else:
            print(f' >> [{i}] Get wrong text: {text}. {refresh_str}.')
            tt.save_img(img, f'/tmp/captap-{i}-tocheck.png',
                        xywh=(X2-W2, Y2-H2, W2*2, H2*7//2))
        tt.touch_screen('tap', X1, Y1)
        time.sleep(sleep)
        try:
            img = tt.capture_screen()
        except Exception as e:
            print(' !! Error when capture screen!', e)
            break
        if i < 2 and not re.match(check_pat, text):
            print(' >> Getting new X2, Y2 for the second time ...')
            X2, Y2, w, H2 = tt.locate_xy(img, zhan, partial=1)
            W2 = w*4
    if save:
        realsave = os.path.expanduser(save)
        if os.path.isfile(realsave):
            print("[Info] Reload results from %s ..." % save)
            with open(realsave, 'r', encoding='utf8') as out:
                results = json.load(out)
        else:
            results = {}
        key = str(key)  # str keys for json github python/cpython/issues/79153
        if key in results:
            results[key].extend(coll_N)
            # results[key].sort()
        else:
            results[key] = coll_N  # sorted(coll_N)
        with open(realsave, 'w', encoding='utf8') as out:
            print("[Info] Add %d new results to %s." % (len(coll_N), save))
            json.dump(results, out, ensure_ascii=False)


def task1_hist1(save, split=[0.5, 1.0, 1.5, 2.0]):
    with open(os.path.expanduser(save), 'r', encoding='utf8') as out:
        results = json.load(out)
    # pre interval
    interval = []
    for i in range(len(split)):
        if i == 0:
            interval.append((f' <{split[i]:.1f}', -np.inf, split[i]))
        if i == len(split) - 1:
            interval.append((f'>={split[i]:.1f}', split[i], np.inf))
        else:
            interval.append(
                (f'{split[i]:.1f}~{split[i+1]:.1f}', split[i], split[i+1]))
    count = {}
    N = {}
    for key, value in results.items():
        k = int(key)
        count[key] = {i[0]: 0 for i in interval}
        N[key] = len(value)
        for v in value:
            r = v/k
            ADD = False
            for itv in interval:
                if r >= itv[1] and r < itv[2]:
                    count[key][itv[0]] += 1
                    ADD = True
                    break
            if not ADD:
                print(f"!!! Incomplete interval for r={r:.2f}!")
    all_count = {itv[0]: sum([count[key][itv[0]] for key in results])
                 for itv in interval}
    all_N = sum(N.values())
    # show
    all_K = list(results.keys())
    print('\t'.join(['KEY:'] + [f'{int(k)//10000}w' for k in all_K] + ['ALL']))
    for it, _, _ in interval:
        print(f'{it}\t'
              + '\t'.join([f' {count[k][it]}' for k in all_K])
              + f'\t{all_count[it]}\t{all_count[it]/all_N:.2%}')


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1].isdigit():
        key = int(sys.argv[1])
        task1(key, save='~/.cache/nAeNSpViOp.json')
        task1_hist1('~/.cache/nAeNSpViOp.json',
                    split=[0.1*i for i in range(1, 16)])
    else:
        print(f"usage: {sys.argv[0]} int-key")
