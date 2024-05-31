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


def main(q):
    config = {
        'version': 1,
        'handlers': {
            'sink': {
                'class': 'logging.handlers.QueueHandler',
                'queue': q,
            },
        },
        'root': {
            'handlers': ['sink'],
        },
    }
    logging.config.dictConfig(config)


if __name__ == '__main__':
    main(mp.Manager().Queue())
    main(asyncio.Queue())
