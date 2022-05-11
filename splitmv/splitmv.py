#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import time

FFMPEG = r'ffmpeg -loglevel warning'

# ref: https://trac.ffmpeg.org/wiki/Seeking
TemplateHead = FFMPEG + r' -ss %s -accurate_seek -y -i %s'

TemplateBody = (
    # If you cut with stream copy (-c copy)
    # you need to use the -avoid_negative_ts 1 option
    # if you want to use that segment with the concat demuxer.
    r' -c copy -avoid_negative_ts 1',  # 0
    r' -vcodec copy -acodec copy -avoid_negative_ts 1',  # 1
    # 速度慢, CPU 占用高
    r' -qscale 0',  # 2
)
# 音视频不同步, 加上 -copyts 后正常
# Note that if you specify -ss before -i only,
# the timestamps will be reset to zero,
# so -t and -to have not the same effect.
# If you want to keep the original timestamps, add the -copyts option.
TemplateTail = r' -to %s -copyts %s'

Templates = [TemplateHead + temp + TemplateTail for temp in TemplateBody]


class Splitmv(object):

    def __init__(self, infile, Tlist,
            tmpsuffix=None, outfile=None, template=None):
        if not os.path.exists(infile):
            raise IOError("%s not exist" % infile)
        self.infile = infile
        self.indir = os.path.dirname(self.infile)
        self.inname = os.path.basename(self.infile)
        self.name = os.path.splitext(self.inname)[0]
        self.suffix = os.path.splitext(self.inname)[1]

        if not isinstance(Tlist, (tuple, list)):
            raise NameError("%s is not a list." % str(Tlist))
        else:
            for t in Tlist:
                if not isinstance(t, (tuple, list)):
                    raise NameError("%s is not a list." % str(t))
        self.Tlist = Tlist
        # useful for too long duration
        # https://segmentfault.com/a/1190000040994402
        self.tmpsuffix = tmpsuffix or self.suffix
        if outfile:
            self.outfile = outfile
        else:
            self.outfile = '%s/%s-SplitOut%s' % (
                self.indir, self.name, self.suffix)
        if template:
            self.template = template
        else:
            self.template = Templates[0]

    def run(self, workdir):
        start = time.time()
        if not os.path.exists(workdir):
            os.makedirs(workdir)

        ptmplist = []
        for i, t in enumerate(self.Tlist):
            ptmp = '%s/split-p%s%s' % (workdir, str(i), self.tmpsuffix)
            cmd = self.template % (t[0], self.infile, t[1], ptmp)
            print(' -> %s' % cmd)
            if not os.system(cmd):
                ptmplist.append(ptmp)

        plist = '%s/%s.plist' % (workdir, self.name)
        with open(plist, "w") as pl:
            for ptmp in ptmplist:
                pl.write("file '%s'\n" % os.path.basename(ptmp))

        cmd = FFMPEG + ' -f concat -i %s -c copy %s' % (plist, self.outfile)
        print(' -> %s' % cmd)
        os.system(cmd)
        end = time.time()
        print('==> Task runs %0.2f seconds.' % (end - start))

if __name__ == "__main__":
    import setting as s
    video = Splitmv(s.File,
                    s.Tlist,
                    template=Templates[s.Template],
                    tmpsuffix=s.tmpsuffix,
                    outfile=s.outfile)
    video.run('./tmpdir')
