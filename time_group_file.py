#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2019 shmilee

import os
import re
import time
import shutil
import traceback


class FileInfo(object):
    '''
    path: original file absolute path
    name: original file name
    st_mtime: (Y, M, D) time of last modification get by os.stat
    fl_ntime: None or (Y, M, D) time get by file name
    group: Y, M, D -> new dir
    newname: YYYY-MM-DD-original_name
    '''
    # IMG-YYYYMMDD-HHMMSS
    img_pattern = re.compile(r'''
        IMG
        [_-]{,1}
        (?P<Y>19\d{2}|20\d{2}) #Year, 19XX, 20XX
        (?P<M>0[1-9]|1[012]) # Month
        (?P<D>0[1-9]|[12]\d|3[01]) # Day
        [_-]{,1}
        (?P<h>[01]\d|2[0-4]) # hour
        (?P<m>[0-5]\d|60) # minute
        (?P<s>[0-5]\d|60) # second
        .*
        ''', re.VERBOSE)
    # YYYY-MM-DD or YYYYMMDD
    time_pattern = re.compile(r'''
        .*
        [_-]{,1} # ignore weixin str: 133020020818cd81c7e7206.mp4
        (?P<Y>19\d{2}|20\d{2}) #Year, 19XX, 20XX
        -{,1}
        (?P<M>0[1-9]|1[012]) # Month
        -{,1}
        (?P<D>0[1-9]|[12]\d|3[01]) # Day
        [_-]{,1}
        .*
        ''', re.VERBOSE)
    # mmexport{Epoch seconds*1000} or wx_camera_
    wx_pattern = re.compile(r'''
        (?:mmexport|wx_camera_)
        (?P<Epoch>\d{13})  # 2011 1295539200*1000 -> 22XX 9---
        (?:\.jpg|\.mp4)
        ''', re.VERBOSE)

    def __init__(self, path, group):
        self.path = os.path.abspath(path)
        self.name = os.path.basename(self.path)
        # use timezone infor
        t = time.localtime(os.stat(self.path).st_mtime)
        et = time.localtime(0)
        self.st_mtime = (
            str(t.tm_year),
            '%02d' % t.tm_mon,
            '%02d' % t.tm_mday)
        m = self.img_pattern.match(self.name)
        if not m:
            m = self.time_pattern.match(self.name)
        self.fl_ntime = m.groups()[:3] if m else None
        if not self.fl_ntime:
            m = self.wx_pattern.match(self.name)
            if m:
                epoch = int(m.groups()[0])//1000
                ep_t = time.localtime(epoch)
                self.fl_ntime = (
                    str(ep_t.tm_year),
                    '%02d' % ep_t.tm_mon,
                    '%02d' % ep_t.tm_mday)
        if self.fl_ntime:
            if self.st_mtime != self.fl_ntime and t != et:
                print("Warning: %s mtime to check!\n\t%s != %s" %
                      (self.path, self.st_mtime, self.fl_ntime))
                nt = time.localtime(time.mktime(t)-t.tm_gmtoff)  # t - 8h
                print("If needed: %s\n"
                      "\ttouch -c -m -t %s%02d%02d%02d%02d.%02d %s" % (
                          t, nt.tm_year, nt.tm_mon, nt.tm_mday,
                          nt.tm_hour, nt.tm_min, nt.tm_sec, self.path))
            self.group = self.__group(group, self.fl_ntime)
            prefix = '%s-%s-%s' % self.fl_ntime
            prefix_s = '%s%s%s' % self.fl_ntime
            newname = self.name.replace(prefix, '').replace(
                prefix_s, '').replace('--', '-').replace('__', '_')
            if newname.startswith('_'):
                newname = newname.strip('_')
            if newname.startswith('-'):
                newname = newname.strip('-')
        else:
            self.group = self.__group(group, self.st_mtime)
            prefix = '%s-%s-%s' % self.st_mtime
            newname = self.name
        self.newname = '%s-%s' % (prefix, newname)

    def __group(self, group, mtime):
        if group == 'Y':
            return str(mtime[0])
        elif group == 'M':
            return '%s-%s' % (mtime[0], mtime[1])
        elif group == 'D':
            return '%s-%s-%s' % (mtime[0], mtime[1], mtime[2])

    def outdir(self, output_dir):
        return os.path.join(output_dir, self.group)

    def outpath(self, output_dir):
        return os.path.join(output_dir, self.group, self.newname)


def main(input_dir, output_dir, group='Y', action='dry'):
    '''
    input_dir, output_dir: dir path str
    group: Y(ear), M(onth), D(ay)
    action: ln, cp, dry
    '''
    for root, dirs, files in os.walk(input_dir, True):
        for filename in files:
            finfo = FileInfo(os.path.join(root, filename), group)
            path, outpath = finfo.path, finfo.outpath(output_dir)
            if action in ('ln', 'cp'):
                print('%s: %s ---> %s' % (action, path, outpath))
                try:
                    os.makedirs(finfo.outdir(output_dir), exist_ok=True)
                    if action == 'ln':
                        os.link(path, outpath)
                    elif action == 'cp':
                        shutil.copy2(path, outpath)
                except Exception:
                    traceback.print_exc()
            else:
                print('dry: %s ---> %s' % (path, outpath))


Before_Merge_Collision = '''
for f in `find %s -type f`; do
    md5=$(md5sum $f|awk '{print $1}')
    if grep $md5 PATH-of-md5sums; then
        echo rm -iv $f
    else
        echo 'TODO--------'$f
    fi
done
'''
if __name__ == "__main__":
    input_dir = os.path.expanduser('~/XX照片视频-TODO')
    output_dir = os.path.expanduser('~/XX照片视频-Done')
    main(input_dir, output_dir, group='Y', action='ln')
    print(Before_Merge_Collision % input_dir)
