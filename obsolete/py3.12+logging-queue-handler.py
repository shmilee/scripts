#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2024 shmilee

# Related [bug](https://github.com/python/cpython/issues/111615)
# Related [pull](https://github.com/python/cpython/pull/111638)
# Related [codes](https://github.com/python/cpython/blob/3.12/Lib/logging/config.py#L789-L804)
# python 3.12+
# issue: https://github.com/python/cpython/issues/119819

import logging.config
import multiprocessing as mp
import asyncio

def main(i, qd):
    print('%d. qspec dict: ' % i, qd)
    config = {
        'version': 1,
        'handlers': {
            'sink': {
                'class': 'logging.handlers.QueueHandler',
                'queue': qd,
            },
        },
        'root': {
            'handlers': ['sink'],
        },
    }
    logging.config.dictConfig(config)
    l = logging.getLogger()
    s = l.handlers[0]
    print('USE: ', id(s.queue), s.queue, type(s.queue))
    print('------')

def get_mp_queue(manager=None, maxsize=None):
    q = manager.Queue(maxsize)
    print('GET: ', id(q), q)
    return q

def get_asy_queue(maxsize=None):
    q = asyncio.Queue(maxsize)
    print('GET: ', id(q), q)
    return q

if __name__ == '__main__':
    m = mp.Manager()
    main(1, {'()': get_mp_queue, 'manager': m, 'maxsize': 10})
    main(2, {'()': m.Queue, 'maxsize': 20})
    main(3, {'()': get_asy_queue, 'maxsize': 10})
