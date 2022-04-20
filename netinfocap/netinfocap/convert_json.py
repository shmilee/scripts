# -*- coding: utf-8 -*-

# Copyright (c) 2022 shmilee

import os
import sys
import re
import json
import tempfile

from .server import HTML_template, _result2div


def add_UniqID(file):
    '''
    Add lost control key: 'UniqID', fix: KeyError: 'UniqID'
    Write new data in *file*.new
    '''
    if not os.path.exists(file):
        print("[Error] Cannot find %s!" % file)
        return
    # read
    with open(file, 'r', encoding='utf8') as fp:
        out = json.load(fp)
        results = out['results']
        L = len(results)
        print("[Info] Read %d results from '%s' ..." % (L, file))
        control_keys = out['control_keys']
    # add
    for res in results:
        if 'UniqID' not in res:
            res['UniqID'] = tempfile.mktemp(prefix='', dir='')
    if 'UniqID' not in control_keys:
        control_keys.append('UniqID')
    # write
    output = file + '.new'
    with open(output, 'w', encoding='utf8') as out:
        print("[Info] Save %d results to %s ..." % (L, output))
        json.dump(dict(
            version=1,
            control_keys=control_keys,
            results=results,
        ), out, ensure_ascii=False)


def json2html(file, select_filter=('HLS_Url',)):
    '''
    Convert useful info results from *file*.json, *file*.desc to *file*.html
    and create thumbnails if can access url.

    file: str
        file path, like './aaa.json', the desc file './aaa.desc'
    select_filter: tuple
        tuple of results Family, default ('HLS_Url',)
    desc file format:
        Index-1 desc-1
        Index-2 desc-2
        ...
    '''
    if not os.path.exists(file):
        print("[Error] Cannot find json '%s'!" % file)
        return
    with open(file, 'r', encoding='utf8') as fp:
        out = json.load(fp)
        results = out['results']
        print("[Info] Read %d results from '%s' ..." % (len(results), file))
        control_keys = out['control_keys']
    if select_filter:
        results = [r for r in results if r['Family'] in select_filter]
        print("[Info] Get %d results after filter ..." % len(results))
    # remove ext '.json'
    file = os.path.splitext(file)[0]
    desc_file = '%s.desc' % file
    if os.path.exists(desc_file):
        print("[Info] Add desc from '%s' for results ..." % desc_file)
        with open(desc_file, 'r', encoding='utf8') as fp:
            desc_data = fp.readlines()
        for line in desc_data:
            m = re.match('^(\d+)\s+(.*)$', line)
            if m:
                index, desc = m.groups()
                if index.isdigit():
                    index = int(index)
                    for r in results:
                        if r['Index'] == index:
                            r['Desc'] = desc
                            break
    else:
        print("[Error] Cannot find desc '%s'!" % desc_file)
        return
    results = [r for r in results if 'Desc' in r]

    # start convert
    Num = len(results)
    print("[Info] Select %d results to convert ..." % Num)
    outdir = '%s.files' % file
    outhtml = '%s.html' % file
    if not os.path.exists(outdir):
        os.mkdir(outdir)
    div_res = [_result2div(
        res, Num-i, control_keys=control_keys,
        copy_dest=outdir,
        thumbnails_dest=outdir,
        thumbnails_kwargs=dict(width='800', grid='3x4'))
        for i, res in enumerate(results[::-1])
    ]
    # outdir relative to html
    div_res = ' '.join(div_res).replace(outdir, os.path.basename(outdir))
    with open(outhtml, 'w', encoding='utf8') as out:
        out.write(HTML_template % (Num, Num, div_res))
    print("[Info] DONE.")


def main():
    if len(sys.argv) == 2:
        json2html(sys.argv[1])
    elif len(sys.argv) > 2:
        json2html(sys.argv[1], select_filter=sys.argv[2:])
    else:
        print("Usage: %s json-file [select_filter ...]" % sys.argv[0])


if __name__ == '__main__':
    main()
