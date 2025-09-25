#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2025 shmilee

from functools import lru_cache
from hashlib import sha256
from typing import Mapping, Union

import os
import re
import time
import json
import requests
from urllib.parse import urlparse
from contextlib import closing
from multiprocessing import Pool
from collections import Counter, OrderedDict


class Base58(object):
    '''
    Bitcoin-compatible Base58 and Base58Check implementation
    Ref: https://github.com/keis/base58
    '''
    # 58 character alphabet used
    BITChars = b'123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
    XRPChars = b'rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz'

    def __init__(self, alphabet: bytes = BITChars) -> None:
        if type(alphabet) != bytes or len(alphabet) != 58:
            raise ValueError('Invalid alphabet for base58!')
        self.alphabet = alphabet
        self.base = 58  # len(alphabet)

    def encode(self, v: Union[str, bytes], str_encoding: str = 'utf-8',
               default_one: bool = False) -> bytes:
        """default_one: empty -> 1 ?"""
        v = v.encode(str_encoding) if isinstance(v, str) else v
        origlen = len(v)
        v = v.lstrip(b'\0')
        newlen = len(v)
        # first byte is most significant
        acc = int.from_bytes(v, byteorder='big')
        if not acc and default_one:
            result = self.alphabet[0:1]
        else:
            # acc: int -> result: str
            result = b""
            while acc:
                acc, idx = divmod(acc, self.base)
                result = self.alphabet[idx:idx+1] + result
        return self.alphabet[0:1] * (origlen - newlen) + result

    def encode_check(self, v: Union[str, bytes], str_encoding: str = 'utf-8',
                     default_one: bool = False) -> bytes:
        """Encode with a 4 character checksum"""
        v = v.encode(str_encoding) if isinstance(v, str) else v
        digest = sha256(sha256(v).digest()).digest()
        return self.encode(v + digest[:4], default_one=default_one)

    def encode_file(self, path: str, default_one: bool = False,
                    checksum: bool = False) -> bytes:
        func = self.encode_check if checksum else self.encode
        with open(path, 'rb') as f:  # rb: bytes, untranslate \r\n etc.
            return func(f.read(), default_one=default_one)

    @lru_cache()
    def _get_decode_map(self, autofix: bool) -> Mapping[int, int]:
        invmap = {char: index for index, char in enumerate(self.alphabet)}
        if autofix:
            groups = [b'0Oo', b'Il1']
            for group in groups:
                pivots = [c for c in group if c in invmap]
                if len(pivots) == 1:
                    for alternative in group:
                        invmap[alternative] = invmap[pivots[0]]
        return invmap

    def decode(self, v: Union[str, bytes], str_encoding: str = 'utf-8',
               autofix: bool = False) -> bytes:
        v = v.rstrip()
        v = v.encode(str_encoding) if isinstance(v, str) else v
        origlen = len(v)
        v = v.lstrip(self.alphabet[0:1])
        newlen = len(v)
        invmap = self._get_decode_map(autofix)
        # v: bytes -> acc: int
        acc = 0
        try:
            for char in v:
                acc = acc * self.base + invmap[char]
        except KeyError as e:
            raise ValueError("Invalid character {!r}".format(chr(e.args[0])))
        result = []
        while acc > 0:
            acc, mod = divmod(acc, 256)
            result.append(mod)
        return b'\0' * (origlen - newlen) + bytes(reversed(result))

    def decode_check(self, v: Union[str, bytes], str_encoding: str = 'utf-8',
                     autofix: bool = False) -> bytes:
        '''Decode and verify the checksum'''
        result = self.decode(v, str_encoding=str_encoding, autofix=autofix)
        result, check = result[:-4], result[-4:]
        digest = sha256(sha256(result).digest()).digest()
        if check != digest[:4]:
            raise ValueError("Invalid base58 checksum!")
        return result

    def decode_file(self, path: str, autofix: bool = False,
                    checksum: bool = False) -> bytes:
        func = self.decode_check if checksum else self.decode
        with open(path, 'rb') as f:  # bytes
            return func(f.read(), autofix=autofix)


class SpeedTest(object):

    def __init__(self, timeout=10, UA=None):
        self.timeout = timeout
        self.UA = UA or 'Mozilla/5.0 (Windows NT 10.0; Win64) Firefox/142.0'

    def fetch(self, url, desc):
        '''return status, {speed KB/s, Epoch-seconds, data-size}, data'''
        print("(%s) fetching %s ..." % (desc, url))
        status, data = 1000, b''
        try:
            parsed_url = urlparse(url)
            host = parsed_url.netloc  # .hostname
            kwargs = dict(
                timeout=self.timeout,
                headers={'User-Agent': self.UA, 'Host': host}
            )
            start = time.monotonic()
            with closing(requests.get(url, **kwargs)) as rp:
                status = rp.status_code
                if status == 200:
                    data = rp.content
                else:
                    print('===%d===' % rp.status_code, url)
                    print(rp.headers)
            now = time.monotonic()
            data_size = len(data)
            speed = round(data_size/(now-start)/1024, 3)
        except Exception as error:
            errno = getattr(error, 'errno', None)
            err = error
            while isinstance(err, Exception):
                if len(err.args) > 0:
                    err = err.args[-1]
                    eno = getattr(err, 'errno', None)
                    if eno:
                        errno = eno
                        break
                    else:
                        m = re.match(r'.*\[Errno (\d+)\]', str(err))
                        if m:
                            errno = int(m.groups()[0])
                            break
                else:
                    break
            if errno:
                status = 1000 + errno
            print('(%s) \033[31m[Error %d]\033[0m, %s'
                  % (desc, status, url), error)
            info = dict(speed=0, time=int(time.time()), size=0)
        else:
            if status == 200:
                print('(%s) \033[32m[pass, %.3f KB/s]\033[0m, %s'
                      % (desc, speed, url))
            else:
                print('(%s) \033[31m[Error %d]\033[0m, %s'
                      % (desc, status, url))
            info = dict(speed=speed, time=int(time.time()), size=data_size)
        return (status, info, data)


class APISites(object):
    '''
    each site in json config:
    .. code::

        "alias": {
            "api": "http://xxxx/vod",
            "name": "电影XXX",
            "detail": "http://cccc.com"
        }

    each site in this class, api as unique key:
    .. code::

        "api": {
            "alias": [],
            "name": [],
            "detail": [],
            'common_alias': 'str',
            'common_name': 'str',
            'common_detail': 'str' | None,
            "status": [200, 403, ..., or 1000+Errno, ...],
            "speed_info": [{speed, Epoch, size}, ...],
            "summary": {
                ok=int, fail=int, rate=float, speed=float,
            },
            "other-info-keys": [other_info],
        }
    '''

    def __init__(self, backup: Union[str, None] = None):
        self.sites = {}
        self.count = 0
        self.sources = []
        if backup:
            if os.path.isfile(backup):
                self.load_json_backup(backup)
            else:
                print("Error: json backup %s not found!" % backup)

    def load_json_backup(self, file):
        ''' {count: int, date: xx, sites: {api: {}}}, sources: [] '''
        with open(file, 'r') as fp:
            print("loading json backup %s ..." % file)
            back = json.load(fp)
        if ('count' not in back or 'date' not in back
                or 'sites' not in back or 'sources' not in back):
            print("Error: invalid config backup!")
            return
        self.sites.update(back['sites'])
        self.count = len(self.sites)
        newsource = [fsha256sum for fsha256sum in back['sources']
                     if fsha256sum not in self.sources]
        self.sources.extend(newsource)

    def save_json_backup(self, file, **json_kwargs):
        ''' {count: int, date: xx, sites: {api: {}}}, sources: [] '''
        kwargs = dict(indent=2, ensure_ascii=False)
        kwargs.update(json_kwargs)
        with open(file, 'w') as fp:
            print("saving json backup %s ..." % file)
            json.dump(dict(
                count=self.count,
                date=time.asctime(),
                sites=self.sites,
                sources=self.sources
            ), fp, **kwargs)

    def add_json_config(self, file):
        '''
        add (new) api, only with its (new) alias, name, detail,
        and othe-info
        '''
        if not os.path.isfile(file):
            print("Error: json config %s not found!" % file)
            return
        with open(file, 'rb') as fp:
            fsha256sum = sha256(fp.read()).digest().hex()
        if fsha256sum in self.sources:
            print("json config %s has been added!" % file)
            return
        else:
            print("adding json config %s ..." % file)
        try:
            with open(file, 'r') as fp:
                config = json.load(fp)
        except json.decoder.JSONDecodeError:
            try:
                raw = Base58().decode_file(file)
                print("base58 encoded json config found!")
                config = json.loads(raw)
            except Exception as err:
                print('Error: invalid moontv config!', err)
                return
        if 'api_site' not in config or 'cache_time' not in config:
            print("Error: invalid moontv config!")
            return
        count = 0
        for alias, info in config['api_site'].items():
            api = info.get('api', None)
            if api[-1] == '/' and api[:-1] in self.sites:
                api = api[:-1]
            name = info.get('name', None)
            detail = info.get('detail', None)
            count += 1
            if api and name:
                if api in self.sites:
                    print(" > %d) Update api: %s, %s" % (count, name, api))
                    self.sites[api]['alias'].append(alias)
                    self.sites[api]['name'].append(name)
                    if detail:
                        self.sites[api]['detail'].append(detail)
                else:
                    print(" > %d) New api: %s, %s" % (count, name, api))
                    self.sites[api] = dict(
                        alias=[alias],
                        name=[name],
                        detail=[detail] if detail else [],
                        common_alias=None,  # update in the end
                        common_name=None,
                        common_detail=None,
                        status=[],
                        speed_info=[],
                        summary={},
                    )
            else:
                print(" > %d) Skip invalid api: %s, %s" % (count, name, api))
                continue
            # other-info
            site = self.sites[api]
            for key in info:
                if key not in ('api', 'name', 'detail',
                               'status', 'speed_info', 'summary'):
                    if key in site:
                        if info[key] not in site[key]:
                            site[key].append(info[key])
                    else:
                        site[key] = [info[key]]
        self.count = len(self.sites)
        self.sources.append(fsha256sum)
        self.update_common()

    def update_common(self):
        '''update most common name, alias, detail'''
        for api, info in self.sites.items():
            info['common_name'] = self.get_common_name(api, info)
            info['common_alias'] = self.get_common_alias(api, info)
            info['common_detail'] = self.get_common_detail(api, info)

    def get_common_name(self, api, info):
        N = len(info['name'])  # >=1
        if N == 1:
            return info['name'][0]
        count = [(n.count('TV'), n.count('-')) for n in info['name']]
        index = sorted(range(N), key=count.__getitem__)[-1]
        return info['name'][index]

    def get_common_alias(self, api, info):
        # ignore info['alias']
        # use 一级域名 + 顶级[:2] OR 一级域名 + 二级[:1] + 顶级[:1]
        host = urlparse(api).netloc
        domain_parts = host.split('.')
        domain_parts.reverse()  # len: 2 or 3
        suffix = (domain_parts[0][:2] if len(domain_parts) == 2
                  else domain_parts[2][:1] + domain_parts[0][:1])
        return domain_parts[1] + suffix

    def get_common_detail(self, api, info):
        N = len(info['detail'])  # >=0
        if N == 0:
            return None
        elif N == 1:
            return info['detail'][0]
        most_details = Counter(info['detail']).most_common(2)
        return most_details[0][0]

    def test_connection(self, timeout=30, pool_size=8):
        tester = SpeedTest(timeout=timeout)
        testpool = Pool(pool_size)
        result = []
        apis = self.sites.keys()
        for i, api in enumerate(apis, 1):
            desc = '%2d/%2d' % (i, self.count)
            result.append((
                api, testpool.apply_async(tester.fetch, args=(api, desc))
            ))
        testpool.close()
        testpool.join()
        for api, res in result:
            status, speed_info, data = res.get()
            if 'status' in self.sites[api]:
                self.sites[api]['status'].append(status)
            else:
                self.sites[api]['status'] = [status]
            if 'speed_info' in self.sites[api]:
                self.sites[api]['speed_info'].append(speed_info)
            else:
                self.sites[api]['speed_info'] = [speed_info]
        # update summary: 可用率 rate, 平均 speed etc.
        for api, info in self.sites.items():
            N = len(info['status'])
            ok = len([i for i in info['status'] if i == 200])
            fail = N - ok
            rate = round(ok/N, 4)
            # let fail speed = 0
            all_speed = [si.get('speed', 0) for si in info['speed_info']]
            speed = sum(all_speed)/len(info['speed_info'])
            info['summary'].update(ok=ok, fail=fail, rate=rate, speed=speed)

    def sort(self, apis, key='rate+speed', reverse=True, **kwargs):
        ''' sort by 'rate+speed' or 'api' or callable `key(api)` '''
        if callable(key):
            pass
        else:
            key = 'rate+speed' if key not in ('rate+speed', 'api') else key
            if key == 'rate+speed':
                def key(api):
                    return (self.sites[api]['summary']['rate'],
                            self.sites[api]['summary']['speed'])
            elif key == 'api':
                def key(api):
                    return self.sites[api]['common_alias'], urlparse(api).path
        return sorted(apis, key=key, reverse=reverse, **kwargs)

    def reorder_apis(self):
        '''
        Reorder the :attr:`sites` to be an OrderedDict.
        The order of the APIs is based on this key:
            (last_status, -rate, common_name, common_alias, api_path, -speed).
        '''
        def key(api):
            return (
                self.sites[api]['status'][-1],
                -self.sites[api]['summary']['rate'],
                self.sites[api]['common_name'],
                self.sites[api]['common_alias'],
                urlparse(api).path,
                -self.sites[api]['summary']['speed'])
        ordered_apis = sorted(self.sites.keys(), key=key, reverse=False)
        ordered_sites = OrderedDict()
        for api in ordered_apis:
            ordered_sites[api] = self.sites[api]
        self.sites = ordered_sites

    def get_last_testime(self):
        last_times = [max(si['time'] for si in self.sites[api]['speed_info'])
                      for api in self.sites]
        # 平均 各 API 最近更新时间
        last_seconds = sum(last_times)/len(last_times)
        return time.ctime(last_seconds)

    def summary(self, shownum=10, output=None,
                key='rate+speed', reverse=True, **kwargs):
        '''
        Summarize and print info of sorted api_sites, then save to output.
        Call after :meth:`test_connection`.

        Parameters
        ----------
        shownum: if <=0, show all.
        output: file path to save info
        key, reverse, kwargs: passed for :meth:`sort_apis`.
        '''
        log = []
        success = [api for api in self.sites
                   if self.sites[api]['status'][-1] == 200]
        fail = [api for api in self.sites if api not in success]
        Nok = len(success)
        Nfail = len(fail)
        last_testime = self.get_last_testime()
        log.append("==> API 总数：\033[34m%2d\033[0m, 最近更新：%s"
                   % (self.count, last_testime))
        log.append(" -> 最近成功数：\033[32m%2d\033[0m" % Nok)
        log.append(" -> 最近失败数：\033[31m%2d\033[0m" % Nfail)
        ordered = self.sort(
            self.sites.keys(), key=key, reverse=reverse, **kwargs)
        # show first `shownum`
        shownum = shownum if shownum > 0 else self.count
        if key == 'rate+speed' and reverse == True:
            log.append("==> (可用率 rate, 平均速度 speed) 排序靠前的 API：")
        else:
            log.append("==> 排序靠前的 API：")
        for idx, api in enumerate(ordered[:shownum], 1):
            summary = self.sites[api]['summary']
            log.append(" -> [%2d] %5.1f%%, %4.1f KB/s, %4s, %s"
                       % (idx, summary['rate']*100, summary['speed'],
                          self.sites[api]['common_name'], api))
        log = '\n'.join(log)
        print(log)
        if output:
            log = re.sub(r'\033\[[0-9;]+m', '', log)
            with open(output, 'w') as out:
                out.write(log)
                print("saving summary info in '%s'" % output)

    def select_apis(self, rate_limit=0.8, nameprefix=None, unique=True,
                    filter_out=None):
        '''
        rate_limit: float
            info['summary']['rate'] > limit
        nameprefix: str, like 'TV-'
            info['common_name'] starts with **nameprefix**
            and also used for **unique**
        unique: bool, default True
            unique API with name 'XXXXX', common_name="nameprefix(XXXXX)%d*"
        filter_out: function condition(api, info)
            remove api that satisfies condition.
        '''
        print("\nSelecting API, rate_limit=%s, nameprefix=%s, unique=%s ..."
              % (rate_limit, nameprefix, unique))
        SA = self.sites
        select = [api for api in SA.keys()
                  if SA[api]['summary']['rate'] > rate_limit]
        if nameprefix:
            select = [api for api in select
                      if SA[api]['common_name'].startswith(nameprefix)]
        if callable(filter_out):
            select = [api for api in select if not filter_out(api, SA[api])]
        ordered = self.sort(select, key='rate+speed', reverse=True)
        count = 0
        if unique:
            result, uniq_names = [], []
            for api in ordered:
                common_name = SA[api]['common_name']
                if nameprefix:
                    pat = r'%s(.*[^0-9])\d*' % nameprefix
                else:
                    pat = r'(.*[^0-9])\d*'
                m = re.match(pat, common_name)
                if m:
                    name = m.groups()[0]
                else:
                    name = common_name.replace(nameprefix, '', count=1)
                if name not in uniq_names:
                    result.append(api)
                    uniq_names.append(name)
                    action = '+Add'
                    count += 1
                else:
                    action = '\033[33mSkip'
                print("[S%2d] %s %s\033[0m (%s), %s"
                      % (count, action, common_name, name, api))
        else:
            for api in ordered:
                count +=1
                common_name = SA[api]['common_name']
                print("[S%2d] %s %s\033[0m, %s"
                      % (count, 'Add', common_name, api))
            result = ordered
        print("==> \033[32m%d\033[0m APIs selected." % len(result))
        return result

    def dump_json_config(self, apis, output, **json_kwargs):
        config = dict(cache_time=7200, last_updated=self.get_last_testime(),
                      api_count=0, api_site=OrderedDict())
        print("\n==> config 选用 API 数：%d" % len(apis))
        for api in apis:
            alias = self.sites[api]['common_alias']
            if alias in config['api_site']:
                print('\033[33m[Error] %s\033[0m has been dumped! Ignore %s!'
                      % (alias, api))
            else:
                name = self.sites[api]['common_name']
                detail = self.sites[api].get('common_detail')
                config['api_site'][alias] = dict(api=api, name=name)
                if detail:
                    config['api_site'][alias]['detail'] = detail
        # dump
        config['api_count'] = len(config['api_site'])
        print("==> config 保存 API 数：%d" % config['api_count'])
        kwargs = dict(indent=2, ensure_ascii=False)
        kwargs.update(json_kwargs)
        with open(output, 'w') as fp:
            json.dump(config, fp, **kwargs)
        # base58
        b58 = Base58().encode_file(output)
        b58file = os.path.splitext(output)[0] + '.txt'
        with open(b58file, 'w') as fp:
            fp.write(b58.decode())
        print("==> 已保存至 %s 和 %s." % (output, b58file))


if __name__ == '__main__':
    api_bakcup = './api-configs/api-sites-backup.json'
    sites = APISites(api_bakcup)

    # update
    collection_confs = [
        './api-configs/moontv-hafrey1-config.txt',
        './api-configs/moontv-senshinya-gistfile.txt',
    ]
    for conf in collection_confs:
        sites.add_json_config(conf)
    sites.test_connection()

    # backup
    sites.reorder_apis()
    sites.summary(shownum=0, output='./api-configs/api-sites-summary.txt')
    sites.save_json_backup(api_bakcup)

    # select TV-
    def filter_out(api, info):
        for nam in ['TV-CK']:
            if nam in info['common_name']:
                return True
    apis = sites.select_apis(
        rate_limit=0.9, nameprefix='TV-', filter_out=filter_out)
    sites.dump_json_config(
        apis,
        './api-configs/api-sites-moontv-example-config.json',
    )
