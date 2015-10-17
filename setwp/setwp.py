#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright (c) 2015 shmilee

'''
Set random root desktop wallpaper by program habak and imagemagick.
'''

import os
import argparse
import configparser
import random
import shutil

##http://www.imagemagick.org/Usage/mapping/
effects=[('mess','\( +clone -threshold -1 -virtual-pixel black -spread 30 -blur 0x3 -threshold 40% -spread 2 -blur 10x.7 \) -compose Copy_Opacity -composite'),
    ('frame','-bordercolor "#C2C2C2" -border 5 -bordercolor "#323232" -border 1'),
    ('raise','+raise 5x5 -swirl 60'),
    ('edge','-colorspace Gray  -edge 1 -negate -scale 120'),
    ('distort',"-matte -virtual-pixel transparent -distort Perspective '0,0,0,0  0,90,0,90  90,0,90,25  90,90,90,65'")]

def get_random_files(flist,num):
    _list = []
    if type(flist) != list:
        flist = [flist]
    for _p in flist:
        _p = os.path.expanduser(_p)
        if os.path.isfile(_p):
            _list += [_p]
        elif os.path.isdir(_p):
            tt=os.walk(_p)
            for _f in tt:
                for _ff in _f[2]:
                    _list += [_f[0]+"/" + _ff]
    if num == 'all':
        return _list
    else:
        return random.sample(_list,num)

def make_cache(pic_path,convert_set):
    cache_path = os.path.expanduser(convert_set[0])
    size_min   = convert_set[1][0]
    size_max   = convert_set[1][1]
    rot_min    = convert_set[2][0]
    rot_max    = convert_set[2][1]
    try:
        if os.path.isdir(cache_path):
            rmcache = input("Remove cache directory %s [y/n]" % cache_path)
            if rmcache == 'y' or rmcache == 'Y':
                shutil.rmtree(cache_path)
                os.mkdir(cache_path)
        else:
            os.mkdir(cache_path)
    except Exception as e:
        print(e)
        return 0

    pictures = get_random_files(pic_path,'all')
    for pic in sorted(pictures):
        print("==> %s" % pic)
        for mess,optstr in effects:
            size = random.randint(size_min,size_max)
            rot  = random.randint(rot_min,rot_max)
            out  = cache_path + '/%s-%s' % (mess,os.path.basename(pic).replace('.jpg','.png'))
            cmd  = 'convert %s -scale %s %s -background none -rotate %s %s' % (pic,size,optstr,rot,out)
            print("%s\t-> %s" % (mess,out))
            os.system(cmd)

def setwallpaper(wp_path,pic_set,pic_num):
    wallpaper = get_random_files(wp_path,1)[0]
    if not os.path.isfile(os.path.expanduser(wallpaper)):
        print("Wallpaper %s doesn't exist." % wallpaper)
        return 0
    print('==> Wallpaper is: %s' % wallpaper)
    pictures  = get_random_files(pic_set[0],pic_num)

    cmd = "habak -ms " + wallpaper
    for pic in pictures:
        x    = random.randint(0,pic_set[3][0])
        y    = random.randint(0,pic_set[3][1])
        ef   = pic_set[2][random.randint(0,len(pic_set[2])-1)]
        out  = pic_set[1] + '/%s-%s' % (ef,os.path.basename(pic).replace('.jpg','.png'))
        if not os.path.isfile(os.path.expanduser(out)):
            print("Warnning: %s doesn't exist.\nPlease regenerate converted pictures." % out)
        else:
            cmd += " -mp %s,%s %s" % (str(x),str(y),out)
            print("%s\t-> %s" % (ef,out))

    print('==> Command is: %s' % cmd)
    os.system(cmd)

def main(args):
    try:
        config = configparser.ConfigParser()
        config.read(os.path.expanduser(args.config[0]))

        path_single   = config['path']['single_wp']
        path_random   = config['path']['random_wp'].split('|')
        path_picture  = config['path']['picture'].split('|')
        path_cache    = config['path']['cache']

        pic_size_min  = int(config['picture']['size_min'])
        pic_size_max  = int(config['picture']['size_max'])
        pic_rot_min   = int(config['picture']['rotation_min'])
        pic_rot_max   = int(config['picture']['rotation_max'])
        pic_effects   = config['picture']['effects'].split('|')
        pic_xmax      = int(config['picture']['x_max'])
        pic_ymax      = int(config['picture']['y_max'])
        convert_set   = (path_cache,(pic_size_min,pic_size_max),(pic_rot_min,pic_rot_max))
        stack_set     = (path_picture,path_cache,pic_effects,(pic_xmax,pic_ymax))
        if args.number == -1:
            single_number = int(config['picture']['single_num'])
            random_number = int(config['picture']['random_num'])
        else:
            single_number = random_number = args.number[0]
    except (Exception,KeyError) as e:
        print("Does %s exist?\nYou can get an example from /etc/setwp.conf.example." % args.config[0])
        print("And please check what you set in:")
        print(e)
        return 0

    if args.cmd == 's':
        setwallpaper(path_single,stack_set,single_number)
    elif args.cmd == 'r':
        setwallpaper(path_random,stack_set,random_number)
    elif args.cmd == 'c':
        make_cache(path_picture,convert_set)
        return 1
    else:
        print("Unknow CMD.")
    return 1

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description = "Set wallpaper v0.1 by shmilee@zju.edu.cn",formatter_class = argparse.RawTextHelpFormatter)
    parser.add_argument('-n',  dest='number', nargs=1,   default=-1, type=int,     help='No. of random pictures stacked on wallpaper')
    parser.add_argument('-f',  dest='config', nargs=1,   default=['~/.setwp.conf'], help='set configuration file (default: ~/.setwp.conf)')
    parser.add_argument('cmd', metavar='CMD', nargs='?', default='s', choices=['s', 'r', 'c'],
      help='Actions (choices: %(choices)s)\ns set certain wallpaper (default)\nr select a random wallpaper\nc generate converted pictures in cache directory')
    args = parser.parse_args()
    main(args)    
