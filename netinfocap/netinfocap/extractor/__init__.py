# -*- coding: utf-8 -*-

# Copyright (c) 2021 shmilee

all_extractors = ['bilive', 'hls', 'rtmpt']


def _get_valid_kws(kwargs, keys):
    kws = {k: kwargs[k] for k in keys if k in kwargs}
    return kws


def get_extractor(name, **kwargs):
    if name == 'bilive':
        from .bilive import Bilive_Url_Extractor
        kws = _get_valid_kws(kwargs, ('player', 'ffmpeg'))
        return Bilive_Url_Extractor(**kws)
    elif name == 'hls':
        from .hls import HLS_Url_Extractor
        kws = _get_valid_kws(kwargs, ('player', 'ffmpeg'))
        return HLS_Url_Extractor(**kws)
    elif name == 'rtmpt':
        from .rtmpt import RTMPT_Url_Extractor
        kws = _get_valid_kws(kwargs, ('player', 'ffmpeg'))
        return RTMPT_Url_Extractor(**kws)
    else:
        print('[Error] invalid extractor name!')
