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


class NetIspDetector(object):

    APIS_ISP = [
        # (url, isp_field),
        ('https://ipapi.co/json/', 'org'),
        ('https://ipinfo.io/json/', 'org'),
        ('http://ip-api.com/json/', 'isp'),
    ]
    default_requests_kwargs = dict(timeout=10, headers={
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64) Firefox/142.0',
    })

    def __init__(self, qqKey=None, baiduAK=None):
        if qqKey or baiduAK:
            self.qqKey = qqKey
            self.baiduAK = baiduAK
        else:
            raise ValueError('Need QQ API Key or Baidu API AK!')
        # 位置，国内API比较准确
        info = self._api_baidumap()
        addr = info['addr'] or self._api_qqmap() or '未知'
        addr = addr.replace(' ', '_').replace('省', '').replace('市', '')
        # ISP
        isp = '未知'
        for url, field in self.APIS_ISP:
            response = self._fetch_api_data(url, url, timeout=5)
            if response and response.get(field, None):
                isp = self._standardize_isp(response[field])
                break
        self.addr = addr
        self.isp = isp
        print(f"本机网络运营商(ISP)为: {self.netisp}")

    @property
    def netisp(self):
        return f'{self.addr}+{self.isp}'

    def _fetch_api_data(self, name, url, **kwargs):
        requests_kwargs = self.default_requests_kwargs.copy()
        requests_kwargs.update(kwargs)
        print(f"尝试API {name}...")
        try:
            response = requests.get(url, **requests_kwargs)
            if response.status_code == 200:
                return response.json()
            else:
                print(f"请求失败: {response}")
        except Exception as e:
            print(f"请求失败: {e}")
        return None

    def _api_baidumap(self):
        '''Return {addr:'xx', isp:'xx'}'''
        if not self.baiduAK:
            return dict(addr=None, isp=None)
        name = '百度IP定位'
        url = 'https://api.map.baidu.com/location/ip?ak=%s' % self.baiduAK
        response = self._fetch_api_data(name, url, timeout=5)
        try:
            if response and response['status'] == 0:
                if 'content' in response:
                    content = response['content']
                    return dict(addr=content['address'], isp=None)
                elif 'result' in response:  # old?
                    result = response['result']
                    return dict(addr=result['location'], isp=result['isp'])
            print(f"{name} 响应错误: {response.get('message', '')}")
        except Exception as e:
            print(f"{name} 响应解析错误: {e}")
        return dict(addr=None, isp=None)

    def _api_qqmap(self):
        '''Return addr only'''
        if not self.qqKey:
            return
        name = '腾讯IP定位'
        url = 'https://apis.map.qq.com/ws/location/v1/ip?key=%s' % self.qqKey
        response = self._fetch_api_data(name, url, timeout=5)
        try:
            if response and response['status'] == 0:
                info = iresponse['result']['ad_info']
                return info['province'] + info['city'] + info['district']
            print(f"{name} 响应错误: {response.get('message', '')}")
        except Exception as e:
            print(f"{name} 响应解析错误: {e}")
        return

    def _standardize_isp(self, isp_raw):
        """标准化运营商名称"""
        isp_lower = isp_raw.lower()
        if any(keyword in isp_lower for keyword in [
                '电信', 'chinatelecom', 'china telecom', 'chinanet']):
            return '电信'
        elif any(keyword in isp_lower for keyword in [
                '移动', 'chinamobile', 'china mobile', 'cmcc']):
            return '移动'
        elif any(keyword in isp_lower for keyword in [
                '联通', 'chinaunicom', 'china unicom']):
            return '联通'
        elif any(keyword in isp_lower for keyword in ['教育网', 'cernet']):
            return '教育网'
        else:
            return isp_raw.replace(' ', '.')


class SpeedTest(object):

    def __init__(self, timeout=10, UA=None):
        self.timeout = timeout
        self.UA = UA or 'Mozilla/5.0 (Windows NT 10.0; Win64) Firefox/142.0'

    def _get_kwargs(self, url):
        parsed_url = urlparse(url)
        host = parsed_url.netloc  # .hostname
        return dict(
            timeout=self.timeout, allow_redirects=True,
            headers={'User-Agent': self.UA, 'Host': host}
        )

    def _get_errno(self, error):
        errno = getattr(error, 'errno', None)
        if errno == None:
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
        return errno

    def connect(self, url, desc):
        '''return True/False'''
        print("(%s) connecting %s ..." % (desc, url))
        try:
            with closing(requests.get(url, **self._get_kwargs(url))) as rp:
                if 200 <= rp.status_code < 400:
                    print('(%s) \033[32m[connected]\033[0m, %s' % (desc, url))
                    return True
                else:
                    print('(%s) \033[32m[status %d]\033[0m, %s'
                          % (desc, rp.status_code, url))
        except Exception as error:
            errno = self._get_errno(error)
            print('(%s) \033[32m[error %s]\033[0m, %s' % (desc, errno, url))
        return False

    def fetch(self, url, desc):
        '''return status, {speed KB/s, Epoch-seconds, data-size}, data'''
        print("(%s) fetching %s ..." % (desc, url))
        status, data = 1000, b''
        try:
            start = time.monotonic()
            with closing(requests.get(url, **self._get_kwargs(url))) as rp:
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
            errno = self._get_errno(error)
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
            "proxy": [],  # fmt: 'https://api-proxy-domain/?url='
            "common_alias": 'str',
            "common_name": 'str',
            "common_detail": None or 'str',
            "speed_log": [
                {
                    netisp, # addr+isp
                    status, # 200, 403, ..., or 1000+Errno
                    speed, Epoch, size,
                },
                ...,
            ],
            "summary": {
                ok=int, fail=int, rate=float, speed=float,
            },
            "other-info-keys": [other_info],
        }
    '''
    Proxy_Pattern = re.compile(r'''
        ^(?P<proxy>https?://[\w\.]+/\?url=)  # prefix proxy url
        (?P<api>https?://[\w\./]+)$  # real api url
    ''', re.VERBOSE)
    API_Proxies = {
        'hafrey': 'https://pz.v88.qzz.io/?url=',
        '168188': 'https://pz.168188.dpdns.org/?url=',
    }

    def __init__(self, netisp: str = '未知+未知',
                 backup: Union[str, None] = None):
        self.sites = {}
        self.count = 0
        self.config_sources = []
        if backup:
            if os.path.isfile(backup):
                self.load_json_backup(backup)
            else:
                print("Error: json backup %s not found!" % backup)
        self.netisp = netisp

    def load_json_backup(self, file):
        ''' {count: int, date: xx, sites: {api: {}}}, config_sources: [] '''
        with open(file, 'r') as fp:
            print("loading json backup %s ..." % file)
            back = json.load(fp)
        if ('count' not in back or 'date' not in back
                or 'sites' not in back or 'config_sources' not in back):
            print("Error: invalid config backup!")
            return
        self.sites.update(back['sites'])
        self.count = len(self.sites)
        newsource = [fsha256sum for fsha256sum in back['config_sources']
                     if fsha256sum not in self.config_sources]
        self.config_sources.extend(newsource)

    def save_json_backup(self, file, **json_kwargs):
        ''' {count: int, date: xx, sites: {api: {}}, config_sources: []} '''
        kwargs = dict(indent=2, ensure_ascii=False)
        kwargs.update(json_kwargs)
        with open(file, 'w') as fp:
            print("saving json backup %s ..." % file)
            json.dump(dict(
                count=self.count,
                date=time.asctime(),
                sites=self.sites,
                config_sources=self.config_sources
            ), fp, **kwargs)

    def update_json_backup(self, file, **json_kwargs):
        '''
        update back json file by version.

        version and fmt:
            0: {
                count: int, date: xx, sites: { api: {
                    ..., status: [], speed_info: [{speed, Epoch, size}],
                }}, sources: [],
            }
            1: {
                version: 1, count: int, date: xx, sites: { api: {
                    ..., proxy: [], speed_log: [{
                        netisp: str, status: int,
                        speed, Epoch, size,
                    }],
                }}, config_sources: [],
            }
        '''
        kwargs = dict(indent=2, ensure_ascii=False)
        kwargs.update(json_kwargs)
        with open(file, 'r') as fp:
            print("loading json backup %s ..." % file)
            back = json.load(fp)
        if ('count' not in back or 'date' not in back or 'sites' not in back):
            print("Error: invalid config backup!")
            return
        sites = back['sites']

        if 'version' not in back:  # 0
            newsites, count = {}, 0
            # copy 基本信息
            for api, info in sites.items():
                # test match 'https://api-proxy-domain/?url=api'
                m, info['proxy'] = self.Proxy_Pattern.match(api), []
                if m:
                    api = m.groupdict()['api']
                    info['proxy'] = [m.groupdict()['proxy']]
                count, name = count + 1, info['common_name']
                logproxy = f' with {info['proxy'][0]}' if info['proxy'] else ''
                if api in newsites:
                    print(f"{count}) Update api: {name}, {api}{logproxy}")
                    for key, value in info.items():
                        if key in newsites[api]:
                            if isinstance(newsites[api][key], list):
                                print(f"  > list: extend {key}")
                                newsites[api][key].extend(value)
                            elif isinstance(newsites[api][key], dict):
                                print(f"  > dict: update {key}")
                                newsites[api][key].update(value)
                            else:
                                clas = type(newsites[api][key])
                                print(f"  > {clas.__name__}: overwrite {key}")
                                newsites[api][key] = value
                        else:
                            print(f"  > {type(value).__name__}: copy {key}")
                            newsites[api][key] = value
                else:
                    print(f"{count}) Copy api: {name}, {api}{logproxy}")
                    newsites[api] = info
            sites = newsites
            # 更新 common_xx 和测速
            for api, info in sites.items():
                # common_
                info['common_name'] = self.get_common_name(api, info)
                info['common_alias'] = self.get_common_alias(api, info)
                info['common_detail'] = self.get_common_detail(api, info)
                # status, speed test info, summary
                status = info.pop('status')
                speed_info = info.pop('speed_info')
                speed_log = []
                for stat, speed in zip(status, speed_info):
                    speed['status'] = stat
                    speed['netisp'] = '未知+未知'
                    speed_log.append(speed)
                info['speed_log'] = speed_log
                summary = self.get_speed_summary(api, info, netisp='ALL')
                info['summary'] = summary

        if 'version' not in back:  # 0
            config_sources = back.get('sources', [])
        else:  # 1
            config_sources = back.get('config_sources', [])

        with open(file, 'w') as fp:
            print("saving json backup %s ..." % file)
            json.dump(dict(
                version=1,
                count=len(sites),
                date=time.asctime(),
                sites=sites,
                config_sources=config_sources
            ), fp, **kwargs)

    def add_json_config(self, file):
        '''
        add (new) api, only with its (new) alias, name, detail,
        and othe-info
        Return number of added/updated api_sites
        '''
        if not os.path.isfile(file):
            print("Error: json config %s not found!" % file)
            return 0
        with open(file, 'rb') as fp:
            fsha256sum = sha256(fp.read()).digest().hex()
        if fsha256sum in self.config_sources:
            print("json config %s has been added!" % file)
            return 0
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
                return 0
        if 'api_site' not in config or 'cache_time' not in config:
            print("Error: invalid moontv config!")
            return 0
        count = 0
        for alias, info in config['api_site'].items():
            api = info.get('api', None)
            # rm last /
            if api[-1] == '/' and api[:-1] in self.sites:
                api = api[:-1]
            # test match 'https://api-proxy-domain/?url=api'
            m, proxy = self.Proxy_Pattern.match(api), None
            if m:
                api = m.groupdict()['api']
                proxy = m.groupdict()['proxy']
            name = info.get('name', None)
            detail = info.get('detail', None)
            if api and name:
                count += 1
                logproxy = f' with {proxy}' if proxy else ''
                if api in self.sites:
                    print(f" > {count}) Update api: {name}, {api}{logproxy}")
                    self.sites[api]['alias'].append(alias)
                    self.sites[api]['name'].append(name)
                    if detail:
                        self.sites[api]['detail'].append(detail)
                    if proxy:
                        self.sites[api]['proxy'].append(proxy)
                else:
                    print(f" > {count}) New api: {name}, {api}{logproxy}")
                    self.sites[api] = dict(
                        alias=[alias],
                        name=[name],
                        detail=[detail] if detail else [],
                        proxy=[proxy] if proxy else [],
                        common_alias=None,  # update in the end
                        common_name=None,
                        common_detail=None,
                        speed_log=[],
                        summary={},
                    )
            else:
                print(f" > X) Skip invalid api: {name}, {api}{logproxy}")
                continue
            # other-info
            site = self.sites[api]
            for key in info:
                if key not in ('api', 'name', 'detail', 'proxy',
                               'speed_log', 'summary'):
                    if key in site:
                        if info[key] not in site[key]:
                            site[key].append(info[key])
                    else:
                        site[key] = [info[key]]
        print('==> %d api_sites added or updated!' % count)
        self.count = len(self.sites)
        self.config_sources.append(fsha256sum)
        self.update_common()
        return count

    def update_common(self):
        '''update most common name, alias, detail'''
        for api, info in self.sites.items():
            info['common_name'] = self.get_common_name(api, info)
            info['common_alias'] = self.get_common_alias(api, info)
            info['common_detail'] = self.get_common_detail(api, info)

    def get_common_name(self, api, info):
        # 去除结尾的-数字
        names = [re.sub(r'[-0-9\s]+$', '', n) for n in info['name']]
        # 去除开头的特殊字符（保留中文、英文、数字）
        names = [re.sub(r'^[^\u4e00-\u9fa5a-zA-Z0-9]+', '', n) for n in names]
        # 去除原有 TV- Av-
        names = [re.sub(r'^(?:TV-|AV-)', '', n) for n in names]
        # assert len(names) >= 1
        # get name
        if len(names) == 1:
            name = names[0]
        else:
            name = Counter(names).most_common(1)[0][0]
        # count TV- AV- >= 0
        TVnames = [n for n in info['name'] if re.match(r'^(?:TV-|🎬)', n)]
        AVnames = [n for n in info['name'] if re.match(r'^(?:AV-|🔞)', n)]
        # get nameprefix
        if len(TVnames) > len(AVnames):
            nameprefix = 'TV-'
        elif len(TVnames) < len(AVnames):
            nameprefix = 'AV-'
        else:
            nameprefix = ''
        return nameprefix + name

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

    def check_http_to_https(self, timeout=30, pool_size=12):
        tester, testpool = SpeedTest(timeout=timeout), Pool(pool_size)
        result = []
        for i, api in enumerate(self.sites.keys(), 1):
            urls_todo = []
            # 1. api
            if api.startswith('http://'):
                urls_todo.append(('api-url', api))
            # 2. detail
            added_detail = []
            for index, detail in enumerate(self.sites[api]['detail']):
                if (detail.startswith('http://')
                        and detail not in added_detail):
                    added_detail.append(detail)
                    urls_todo.append(('detail-%d' % index, detail))
            # 3. common_detail
            common_detail = self.sites[api]['common_detail']
            if common_detail and common_detail.startswith('http://'):
                urls_todo.append(('common_detail', common_detail))
            for what, url in urls_todo:
                desc = '%2d/%2d %s' % (i, self.count, what)
                newurl = url.replace('http', 'https', 1)
                result.append((
                    api, what, url, newurl,
                    testpool.apply_async(tester.connect, args=(newurl, desc))
                ))
        testpool.close()
        testpool.join()
        result = [
            (api, what, url, newurl)
            for api, what, url, newurl, res in result
            if res.get()  # http -> https connected
        ]
        count = 0
        # 1. replace detail & common_detail first
        for api, what, url, newurl in result:
            if what.startswith('detail-'):
                index = int(what[7:])
                if (index < len(self.sites[api]['detail'])  # recheck
                        and self.sites[api]['detail'][index] == url):
                    print('[D] Replacing %s => %s' % (url, newurl))
                    count += 1
                    self.sites[api]['detail'][index] = newurl
            elif what == 'common_detail':
                if self.sites[api]['common_detail'] == url:  # recheck
                    print('[C] Replacing %s => %s' % (url, newurl))
                    count += 1
                    self.sites[api]['common_detail'] = newurl
        # 2. then replace api (the key)
        for api, what, url, newurl in result:
            if what == 'api-url':
                if api == url and url[5:] == newurl[6:]:  # recheck
                    print('[K] Replacing %s => %s' % (url, newurl))
                    count += 1
                    info = self.sites.pop(api)
                    self.sites[newurl] = info
        print('==> 共替换 \033[32m%d\033[0m 个 http 网址为 https!' % count)

    def test_speed(self, timeout=30, pool_size=12):
        tester, testpool = SpeedTest(timeout=timeout), Pool(pool_size)
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
            speed_log = dict(netisp=self.netisp, status=status, **speed_info)
            if 'speed_log' in self.sites[api]:
                self.sites[api]['speed_log'].append(speed_log)
            else:
                self.sites[api]['speed_log'] = [speed_log]
        # update summary: 可用率 rate, 平均 speed etc.
        for api, info in self.sites.items():
            info['summary'] = self.get_speed_summary(api, info, netisp='ALL')

    def get_speed_summary(self, api, info, netisp=None):
        # ok, fail, 可用率 rate, 平均 speed etc.
        filter_netisp = netisp or self.netisp
        if filter_netisp == 'ALL':
            speed_log = info['speed_log']
        else:
            speed_log = [
                sl for sl in info['speed_log']
                if sl['netisp'] == filter_netisp
            ]
        N = len(speed_log)
        if N == 0:
            print('==> Warn: %s \033[33m无测速数据\033[0m!' % api)
            return dict(ok=0, fail=0, rate=0, speed=0)
        ok = len([sl for sl in speed_log if sl['status'] == 200])
        fail = N - ok
        rate = round(ok/N, 4)
        all_speed = [sl.get('speed', 0) for sl in speed_log]
        speed = sum(all_speed)/N
        return dict(ok=ok, fail=fail, rate=rate, speed=speed)

    def sort(self, apis, key='rate+speed', netisp=None, reverse=True, **kwargs):
        ''' sort by 'rate+speed' or 'api' or callable `key(api)` '''
        if callable(key):
            pass
        else:
            key = 'rate+speed' if key not in ('rate+speed', 'api') else key
            if key == 'rate+speed':
                def key(api):
                    info = self.sites[api]
                    summary = self.get_speed_summary(api, info, netisp=netisp)
                    return (summary['rate'], summary['speed'])
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
                self.sites[api]['speed_log'][-1]['status'],
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
        last_times = [max(sl['time'] for sl in self.sites[api]['speed_log'])
                      for api in self.sites]
        # 平均 各 API 最近更新时间
        last_seconds = sum(last_times)/len(last_times)
        return time.ctime(last_seconds)

    def summary(self, shownum=10, output=None, netisp=None,
                key='rate+speed', reverse=True, **kwargs):
        '''
        Summarize and print info of sorted api_sites, then save to output.
        Call after :meth:`test_speed`.

        Parameters
        ----------
        shownum: if <=0, show all.
        output: file path to save info
        netisp: str
            filter speed_log by netisp when sorting api_sites
            default is :attr:`netisp`, 'ALL' for sorting by all speed_logs
        key, reverse, kwargs:
            passed for :meth:`sort_apis`.
        '''
        log = []
        success = [api for api in self.sites
                   if self.sites[api]['speed_log'][-1]['status'] == 200]
        fail = [api for api in self.sites if api not in success]
        Nok = len(success)
        Nfail = len(fail)
        last_testime = self.get_last_testime()
        log.append("==> API 总数：\033[34m%2d\033[0m, 最近更新：%s"
                   % (self.count, last_testime))
        log.append(" -> 最近成功数：\033[32m%2d\033[0m" % Nok)
        log.append(" -> 最近失败数：\033[31m%2d\033[0m" % Nfail)
        ordered = self.sort(
            self.sites.keys(),
            key=key, netisp=netisp,
            reverse=reverse, **kwargs)
        # show first `shownum`
        shownum = shownum if shownum > 0 else self.count
        if key == 'rate+speed' and reverse == True:
            headprefix = "(可用率 rate, 平均速度 speed) "
        else:
            headprefix = ''
        log.append("==> 网络 ISP: %s" % (netisp or self.netisp))
        log.append("==> %s排序靠前的 API：" % headprefix)
        for idx, api in enumerate(ordered[:shownum], 1):
            if netisp == 'ALL':
                summary = self.sites[api]['summary']
            else:
                info = self.sites[api]
                summary = self.get_speed_summary(api, info, netisp=netisp)
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

    def select_apis(self, rate_limit=0.8, netisp=None,
                    nameprefix=None, unique=True,
                    filter_out=None):
        '''
        rate_limit: float
            info['summary']['rate'] > limit
        netisp: str
            filter speed_log by netisp when calculating info['summary']
            default is :attr:`netisp`, 'ALL' for sorting by all speed_logs
        nameprefix: str, like 'TV-'
            info['common_name'] starts with **nameprefix**
            and also used for **unique**
        unique: bool, default True
            unique API with name 'XXXXX', common_name="nameprefix(XXXXX)%d*"
        filter_out: function condition(api, info)
            remove api that satisfies condition.
        '''
        print("\nSelecting API, rate_limit=%s, netisp=%s, nameprefix=%s, unique=%s ..."
              % (rate_limit, netisp, nameprefix, unique))
        SA = self.sites
        select = []
        for api in SA.keys():
            if netisp == 'ALL':
                summary = SA[api]['summary']
            else:
                summary = self.get_speed_summary(api, SA[api], netisp=netisp)
            if summary['rate'] > rate_limit:
                select.append(api)
        if nameprefix:
            select = [api for api in select
                      if SA[api]['common_name'].startswith(nameprefix)]
        if callable(filter_out):
            select = [api for api in select if not filter_out(api, SA[api])]
        ordered = self.sort(
            select, key='rate+speed', netisp=netisp, reverse=True)
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
                count += 1
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
    # ISP
    netisp = NetIspDetector(
        qqKey='your-Key',
        baiduAK='your-AK'
    ).netisp

    api_bakcup = './api-configs/api-sites-backup.json'
    sites = APISites(netisp=netisp, backup=api_bakcup)

    # update
    collection_confs = [
        './api-configs/moontv-hafrey1-config.txt',
        './api-configs/moontv-senshinya-gistfile.txt',
    ]
    count = 0
    for conf in collection_confs:
        count += sites.add_json_config(conf)
    if count > 0:
        sites.update_common()
        sites.check_http_to_https()

    # test speed
    sites.test_speed()

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
