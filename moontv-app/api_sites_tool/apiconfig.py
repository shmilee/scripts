# -*- coding: utf-8 -*-

# Copyright (c) 2025 shmilee

import os
import re
import time
import json

from hashlib import sha256
from urllib.parse import urlparse
from multiprocessing import Pool
from collections import Counter, OrderedDict
from .base58 import Base58
from .vod import VodAPI
from .speedtest import SpeedTest


class APIConfig(object):
    '''
    Each API site in moon json config:
    .. code::

        "alias (as key)": {
            "api": "http://xxxx/vod",
            "name": "电影XXX",
            "detail": "http://cccc.com"
        }

    Each API site in this class, api as unique key:
    .. code::

        "api": {
            "alias": [],
            "name": [],
            "detail": [],
            "proxy": [],  # fmt: 'https://api-proxy-domain/?url='
            "common_alias": 'str',
            "common_name": 'str',
            "common_detail": None or 'str',
            "other-info-keys": [other_info],
        }
    '''
    Proxy_Pattern = re.compile(r'''
        ^(?P<proxy>https?://[\w\.]+/\?url=)  # prefix proxy url
        (?P<api>https?://[\w\./]+)$  # real api url
    ''', re.VERBOSE)
    Prefer_Proxies = OrderedDict({
        'default': 'https://pz.168188.dpdns.org/?url=',
        'v88qzz': 'https://pz.v88.qzz.io/?url=',
    })
    __moon_sign__ = '100.586ab2a'

    def __init__(self, backup: str):
        self.sites = {}
        self.count = 0
        self.config_sources = []
        self.backup = backup
        if backup and os.path.isfile(backup):
            self.load_json_backup(backup)
        self.proxy_apis = [
            api for api, info in self.sites.items()
            if info.get('proxy', [])
        ]

    def load_json_backup(self, file=None):
        '''
        {
            version: 1, __moon_sign__: :attr:`__moon_sign__`,
            count: int, date: "xx 20xx",
            apisites: {api: {...}, ...}, config_sources: [],
        }
        '''
        file = file or self.backup
        with open(file, 'r') as fp:
            print("Info: loading json backup in %s ..." % file)
            back = json.load(fp)
        if (not isinstance(back, dict) or 'version' not in back
                or back.get('__moon_sign__', None) != self.__moon_sign__
                or 'apisites' not in back or 'config_sources' not in back):
            print("Error: invalid config backup!")
            return
        self.sites.update(back['apisites'])
        self.count = len(self.sites)
        newsource = [fsha256sum for fsha256sum in back['config_sources']
                     if fsha256sum not in self.config_sources]
        self.config_sources.extend(newsource)

    def _format_json_dump(self, obj, file, indent_limit, **json_kwargs):
        kwargs = dict(indent=2, ensure_ascii=False)
        kwargs.update(json_kwargs)
        data = json.dumps(obj, **kwargs)
        # ref: https://stackoverflow.com/a/72611442
        if kwargs.get('indent', None) and indent_limit:
            # fr https://stackoverflow.com/questions/58302531
            pat = re.compile(fr'\n(\s){{{indent_limit}}}((\s)+|(?=(}}|])))')
            data = pat.sub('', data)
        with open(file, 'w') as fp:
            fp.write(data)

    def save_json_backup(self, file=None, indent_limit=6, **json_kwargs):
        file = file or self.backup
        obj = dict(
            __moon_sign__=self.__moon_sign__, version=1,
            count=self.count, date=time.asctime(),
            apisites=self.sites, config_sources=self.config_sources,
        )
        print("saving json backup to %s ..." % file)
        self._format_json_dump(obj, file, indent_limit, **json_kwargs)

    def add_moon_config(self, file):
        '''
        add (new) api, only with its (new) alias, name, detail,
        and othe-info
        Return number of added/updated api_sites
        '''
        if not os.path.isfile(file):
            print("Error: moon config %s not found!" % file)
            return 0
        with open(file, 'rb') as fp:
            fsha256sum = sha256(fp.read()).digest().hex()
        if fsha256sum in self.config_sources:
            print("moon config %s has been added!" % file)
            return 0
        else:
            print("adding moon config %s ..." % file)
        config = {}
        try:
            with open(file, 'r') as fp:
                config = json.load(fp)
        except json.decoder.JSONDecodeError:
            try:
                raw = Base58().decode_file(file)
                print("base58 encoded moon config found!")
                config = json.loads(raw)
            except Exception as err:
                pass
        if 'api_site' not in config or 'cache_time' not in config:
            print("Error: invalid moon config!")
            return 0
        count = 0
        for alias, info in config['api_site'].items():
            api = info.get('api', None)
            # rm last /
            if api[-1] == '/':
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
                    )
            else:
                print(f" > X) Skip invalid api: {name}, {api}{logproxy}")
                continue
            # other-info
            site = self.sites[api]
            for key in info:
                if key not in ('api', 'name', 'detail', 'proxy'):
                    if key in site:
                        if info[key] not in site[key]:
                            site[key].append(info[key])
                    else:
                        site[key] = [info[key]]
        print('==> %d api_sites added or updated!' % count)
        self.count = len(self.sites)
        self.config_sources.append(fsha256sum)
        self._update_common()
        return count

    def _update_common(self):
        '''update most common name, alias, detail'''
        for api, info in self.sites.items():
            info['common_name'] = self._get_common_name(api, info)
            info['common_alias'] = self._get_common_alias(api, info)
            info['common_detail'] = self._get_common_detail(api, info)

    def _get_common_name(self, api, info):
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

    def _get_common_alias(self, api, info):
        # ignore info['alias']
        # use 一级域名 + 顶级[:2] OR 一级域名 + 二级[:1] + 顶级[:1]
        host = urlparse(api).netloc
        domain_parts = host.split('.')
        domain_parts.reverse()  # len: 2 or 3
        suffix = (domain_parts[0][:2] if len(domain_parts) == 2
                  else domain_parts[2][:1] + domain_parts[0][:1])
        return domain_parts[1] + suffix

    def _get_common_detail(self, api, info):
        N = len(info['detail'])  # >=0
        if N == 0:
            return None
        elif N == 1:
            return info['detail'][0]
        most_details = Counter(info['detail']).most_common(2)
        return most_details[0][0]

    def _check_https_worker(self, what, url, desc, timeout, fallback_proxy):
        if what == 'api-url':
            vod = VodAPI(url, desc, timeout=timeout)
            if not vod.api_json:
                proxy = self.Prefer_Proxies.get(fallback_proxy)
                vod = VodAPI(proxy+url, desc, timeout=timeout)
            return True if vod.api_json else False
        else:
            tester = SpeedTest(timeout=timeout)
            return tester.test_connection(url, desc)

    def check_http_to_https(self, fallback_proxy='default',
                            timeout=30, pool_size=12):
        if fallback_proxy not in self.Prefer_Proxies:
            fallback_proxy = 'default'
        testpool, result = Pool(pool_size), []
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
                result.append(
                    (api, what, url, newurl,
                     testpool.apply_async(
                         self._check_https_worker,
                         args=(what, newurl, desc, timeout, fallback_proxy))
                     )
                )
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

    def reorder_sites(self, key=None, reverse=False):
        '''
        Reorder the :attr:`sites` to be an OrderedDict.
        The default order of the APIs is based on the key:
            (common_name, common_alias, api_path).
        '''
        sortapis = self.sorted(self.sites.keys(), key=key, reverse=reverse)
        ordered_sites = OrderedDict()
        for api in sortapis:
            ordered_sites[api] = self.sites[api]
        self.sites = ordered_sites

    def sorted(self, apis, key=None, reverse=False):
        '''
        Return a new list containing all input `apis` in new order.
        The default order of the APIs is based on the key:
            (common_name, common_alias, api_path).
        '''
        if not callable(key):
            def key(api):
                info = self.sites[api]
                urlpath = urlparse(api).path
                return (info['common_name'], info['common_alias'], urlpath)
        return sorted(apis, key=key, reverse=reverse)

    def _get_last_updated_time(self):
        return time.asctime()

    def dump_moon_config(self, apis, output, prefer_proxy='default'):
        '''
        apis: list of url str
        output: fiel path str
        prefer_proxy: str, which proxy to use for :attr`proxy_apis`
        '''
        config = dict(cache_time=7200,
                      last_updated=self._get_last_updated_time(),
                      api_count=0, api_site=OrderedDict())
        print("\n==> config 选用 API 数：%d" % len(apis))
        if prefer_proxy in self.Prefer_Proxies:
            proxy = prefer_proxy
        else:
            proxy = 'default'
        proxy = self.Prefer_Proxies[proxy]
        for api in apis:
            alias = self.sites[api]['common_alias']
            name = self.sites[api]['common_name']
            if alias in config['api_site']:
                print(' -> [W] \033[33mIgnore dumped %s %s!\033[0m %s'
                      % (alias, name, api))
            else:
                if api in self.proxy_apis:
                    real_api = proxy + api
                    print(" -> [I] proxy %s: %s" % (name, real_api))
                else:
                    real_api = api
                config['api_site'][alias] = dict(api=real_api, name=name)
                detail = self.sites[api].get('common_detail')
                if detail:
                    config['api_site'][alias]['detail'] = detail
        # dump
        config['api_count'] = len(config['api_site'])
        print("==> config 保存 API 数：%d" % config['api_count'])
        kwargs = dict(indent=2, ensure_ascii=False)
        with open(output, 'w') as fp:
            json.dump(config, fp, **kwargs)
        # base58
        b58 = Base58().encode_file(output)
        b58file = os.path.splitext(output)[0] + '.txt'
        with open(b58file, 'w') as fp:
            fp.write(b58.decode())
        print("==> 已保存至 %s 和 %s." % (output, b58file))
