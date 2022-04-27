#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2022 shmilee

import os
import time
import datetime
import requests
import contextlib
import json

URL = 'https://interface.meiriyiwen.com/article/day?dev=1&date='


def get_day_data(date):
    '''
    Get data by date: 20110308 -> 20200909
    '''
    url = URL+str(date)
    try:
        with contextlib.closing(requests.get(url)) as rp:
            if rp.status_code == 404:
                print('\033[31m[Download %s 404 Not Found]\033[0m' % url)
                return 40404
            elif rp.status_code == 200:
                return json.loads(rp.text)['data']
    except Exception as err:
        print('\033[31m[Download %s Error]\033[0m' % url, err)


def dates(start, stop):
    '''date str generator, from start=(2011,3,18) to stop=(2020,9,9)'''
    start = datetime.date(*start)
    stop = datetime.date(*stop)
    delta = datetime.timedelta(days=1)
    while start <= stop:
        yield start.strftime(r'%Y%m%d')
        start = start + delta


def main(output, start=(2011, 3, 8), stop=(2020, 9, 9), dt=3):
    '''
    Get all data, save them to output.
    '''
    old_results = {}
    if os.path.exists(output):
        try:
            with open(output, 'r', encoding='utf8') as out:
                old_results = json.load(out)
        except Exception:
            pass
        old_L = len(old_results)
        print("[Info] Read %d results from '%s'." % (old_L, output))
    results = {}
    for day in dates(start, stop):
        try:
            if day not in old_results:
                data = get_day_data(day)
                if data:
                    print("[Info] Get data of day: %s" % day)
                    results[day] = data
                    time.sleep(dt)
            elif type(old_results[day]) != dict:
                print(day, ':', old_results[day])
        except KeyboardInterrupt:
            ask = input("\n[Interrupt] Stop downloading?")
            if ask in ('y', 'Y'):
                break
    if results:
        results.update(old_results)
        with open(output, 'w', encoding='utf8') as out:
            print()
            print("[Info] Save %d results to %s ..." % (len(results), output))
            json.dump(results, out, ensure_ascii=False)


if __name__ == '__main__':
    main('./meiriyiwen-all.json', dt=2)
