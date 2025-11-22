# -*- coding: utf-8 -*-

# Copyright (c) 2025 shmilee

import os
import re
import time
import json
import random
from urllib.parse import urlparse
from multiprocessing import Pool

from .apiconfig import APIConfig
from .isp import IspDetector
from .vod import VodAPI
from .speedtest import SpeedTest


class APISpeed(APIConfig):
    '''
    Each api site has a speed summary log:
    .. code::

        f"__summary__{api}": {
            "ok": int,
            "fail": int,
            "rate": float,
            "speed": float-KB/s,
        }

    and speed detailed logs:
    .. code::

        "api": [
            # one test result
            {
                "addrisp": addr+isp,
                "vod_api": {
                    "proxy": proxy-url or None,
                    "time": Epoch-seconds,
                    "status": int,  # 200, 403, ..., or 1000+Errno
                    "size": data-size,
                    "speed": int-KB/s,
                },
                "m3u8": {
                    "url": m3u8-url,
                    "time": Epoch-seconds,
                    "status": int,
                    "size": data-size,
                    "speed": int-KB/s,
                },
                "m3u8_ts": {
                    "count": int,
                    "uri": [ts-uri,...],
                    "time": Epoch-seconds,
                    "status": [int,...],
                    "size": [data-size,...],
                    "speed": [int-KB/s,,...],
                },
                "status": "ok" or "fail-1" or "fail-2" or "fail-3",
            },
            # more test results
            ...,
        ]
    '''
    __moon_sign__ = APIConfig.__moon_sign__

    def __init__(self, backup: str, logfile: str, ispdetector: IspDetector):
        super().__init__(backup)
        self.addrisp = ispdetector.addrisp
        self.logs = {}
        self.logfile = logfile
        if logfile and os.path.isfile(logfile):
            self.load_json_logs(logfile)
        self.proxy_apis = self._get_proxy_apis()

    def load_json_logs(self, file=None):
        '''
        {
            version: 1, __moon_sign__: :attr:`__moon_sign__`,
            count: int, date: "xx 20xx",
            speedlogs: { f"__summary__{api}": {...}, api: [...], ..., },
        }
        '''
        file = file or self.logfile
        with open(file, 'r') as fp:
            print("Info: loading json logs in %s ..." % file)
            logs = json.load(fp)
        if (not isinstance(logs, dict) or 'version' not in logs
                or logs.get('__moon_sign__', None) != self.__moon_sign__
                or 'speedlogs' not in logs):
            print("Error: invalid json logs!")
            return
        self.logs.update(logs['speedlogs'])

    def _get_proxy_apis(self):
        '''Return apis which need proxy when fetching vod_api.'''
        result = []
        for api in self.sites:
            speed_logs = self.logs.get(api, [])
            if not speed_logs:
                continue
            vod_api_logs = sorted([
                sl.get('vod_api', {}) for sl in speed_logs
            ], key=lambda vl: vl.get('time', 0))
            vod_api_logs_with_proxy = [
                vl for vl in vod_api_logs if vl.get('proxy', None)
            ]
            if len(vod_api_logs) > 0:
                # last test uses proxy
                if vod_api_logs[-1].get('proxy', None):
                    result.append(api)
                # most tests use proxy
                elif len(vod_api_logs_with_proxy)/len(vod_api_logs) > 0.7:
                    result.append(api)
        return result

    def save_json_logs(self, file=None, indent_limit=10, **json_kwargs):
        file = file or self.logfile
        obj = dict(
            __moon_sign__=self.__moon_sign__, version=1,
            count=self.count, date=time.asctime(),
            speedlogs=self.logs,
        )
        print("saving json logs to %s ..." % file)
        self._format_json_dump(obj, file, indent_limit, **json_kwargs)

    def _test_worker(self, api, desc, detail, fallback_proxy,
                     api_timeout, m3u8_timeout,
                     ts_time_limit, ts_count_limit, ts_size_limit):
        '''Return vod_api_log, m3u8_log, m3u8_ts_log'''
        # 1. get vod_api_log & m3u8_url
        vod_api_log = dict(proxy=None)
        vod = VodAPI(api, desc, detail, timeout=api_timeout)
        vod_api_log.update(vod.api_speed)
        if not vod.api_json:
            proxy = self.Prefer_Proxies.get(fallback_proxy)
            vod = VodAPI(proxy+api, desc, detail, timeout=api_timeout)
            vod_api_log['proxy'] = proxy
            vod_api_log.update(vod.api_speed)
        m3u8_url, title, eptitle = None, '', ''
        if vod.api_json:
            vod_id = vod.random_vod_id()
            vod_detail = vod.getDetail(vod_id)
            if vod_detail:
                episodes = vod_detail.get('episodes', [])
                title = vod_detail.get('title', '')
                eptitles = vod_detail.get('episodes_titles', [])
                if episodes:
                    idx = random.randint(0, len(episodes)-1)
                    m3u8_url = episodes[idx]
                    if len(eptitles) > idx:
                        eptitle = eptitles[idx]
        if m3u8_url:
            print("(%s) choosing %s-%s %s ..."
                  % (desc, title, eptitle, m3u8_url))
        else:
            print("(%s) No m3u8 url found for speed test!" % desc)
            return vod_api_log, {}, {}
        # 2. m3u8_url
        tester = SpeedTest(timeout=m3u8_timeout)
        url_playlist, speed_info = tester.fetch_m3u8_playlist(m3u8_url, desc)
        if url_playlist:
            m3u8_url, playlist = url_playlist
        else:
            playlist = None
        m3u8_log = dict(url=m3u8_url, **speed_info)
        if not playlist:
            return vod_api_log, m3u8_log, {}
        # 3. m3u8_ts
        uri_segments, ts_speed_info = tester.fetch_m3u8_segments(
            playlist, desc,
            time_limit=ts_time_limit,
            count_limit=ts_count_limit,
            size_limit=ts_size_limit
        )
        if uri_segments:
            count = len(uri_segments)
            uri = [us[0] for us in uri_segments]
            m3u8_ts_log = dict(count=count, uri=uri, **ts_speed_info)
            return vod_api_log, m3u8_log, m3u8_ts_log
        else:
            return vod_api_log, m3u8_log, {}

    def test_speed(self, fallback_proxy='default',
                   m3u8_timeout=(8, 29),  # connect, read timeout
                   pool_size=8):
        if fallback_proxy not in self.Prefer_Proxies:
            fallback_proxy = 'default'
        api_timeout = 9
        ts_time_limit = 60
        ts_count_limit = 12
        ts_size_limit = 20 * 1024 * 1024
        testpool = Pool(pool_size)
        result = []
        apis = self.sites.keys()
        for i, api in enumerate(apis, 1):
            info = self.sites[api]
            name, detail = info["common_name"], info['common_detail']
            desc = '%2d/%2d %s' % (i, self.count, name)
            result.append((
                api, testpool.apply_async(self._test_worker, args=(
                    api, desc, detail, fallback_proxy,
                    api_timeout, m3u8_timeout,
                    ts_time_limit, ts_count_limit, ts_size_limit
                ))
            ))
        testpool.close()
        testpool.join()
        for api, res in result:
            vod_api_log, m3u8_log, m3u8_ts_log = res.get()
            api_status = vod_api_log.get('status', None)
            m3u8_status = m3u8_log.get('status', None)
            ts_status = m3u8_ts_log.get('status', [])
            ts_not20x = [s for s in ts_status if s not in [200, 206]]
            if ts_status:
                if not ts_not20x:
                    final_status = "ok"
                elif (len(ts_not20x) <= 3  # 占比较少的非 20X
                      and len(ts_not20x)/len(ts_status) < 0.25):
                    final_status = "ok"
                else:
                    final_status = "fail-3"
            else:
                if m3u8_status and m3u8_status == 200:
                    final_status = "fail-3"
                elif api_status and api_status == 200:
                    final_status = "fail-2"
                else:
                    final_status = "fail-1"
            speed_log = dict(
                addrisp=self.addrisp,
                vod_api=vod_api_log,
                m3u8=m3u8_log,
                m3u8_ts=m3u8_ts_log,
                status=final_status,
            )
            if api in self.logs:
                self.logs[api].append(speed_log)
            else:
                self.logs[api] = [speed_log]
            # update summary: 可用率 rate, 平均 speed etc.
            key = f"__summary__{api}"
            summary = self._speed_summary(api, self.logs[api], addrisp='ALL')
            self.logs[key] = summary
        # update proxy_apis
        self.proxy_apis = self._get_proxy_apis()
        print('==> 共测试 \033[32m%d\033[0m 个 API!' % len(result))

    def _speed_summary(self, api, speed_logs, addrisp=None):
        filter_addrisp = addrisp or self.addrisp
        N = len(speed_logs)
        if filter_addrisp != 'ALL':
            speed_logs = [
                sl for sl in speed_logs
                if sl['addrisp'] == filter_addrisp
            ]
            N = len(speed_logs)
            if N == 0:
                print('==> Warn: %s \033[33m无测速数据\033[0m!' % api)
                return dict(ok=0, fail=0, rate=0, speed=0)
        success = [sl for sl in speed_logs if sl['status'] == "ok"]
        ok = len(success)
        fail = N - ok
        rate = round(ok/N, 3)
        if ok > 0:
            # 仅计算测速成功的 speed
            ok_speeds = [self._calculate_ok_speed(sl) for sl in success]
            speed = round(sum(ok_speeds)/ok, 3)
        else:
            speed = 0
        return dict(ok=ok, fail=fail, rate=rate, speed=speed)

    def get_speed_summary(self, api, addrisp=None):
        '''Default addrisp is :attr:`addrisp`.'''
        if addrisp == 'ALL' and f"__summary__{api}" in self.logs:
            return self.logs[f"__summary__{api}"]
        else:
            speed_logs = self.logs[api]
            return self._speed_summary(api, speed_logs, addrisp=addrisp)

    def _calculate_ok_speed(self, speed_log):
        speed1 = speed_log.get('vod_api', {}).get('speed', 0)
        speed2 = speed_log.get('m3u8', {}).get('speed', 0)
        speed3s = speed_log.get('m3u8_ts', {}).get('speed', [0])
        speed3 = sum(speed3s)/len(speed3s)
        weights = [0.01, 0.09, 0.9]
        return speed1 * weights[0] + speed2 * weights[1] + speed3 * weights[2]

    def reorder_logs(self, key=None, reverse=False):
        '''
        Reorder the :attr:`logs` to be an OrderedDict.
        The default order of the APIs is based on the key:
            (common_name, common_alias, api_path, '' or '__summary__').
        '''
        sortapis = self.sorted(self.sites.keys(), key=key, reverse=reverse)
        ordered_logs = OrderedDict()
        for api in sortapis:
            ordered_logs[api] = self.logs[api]
            ordered_logs[f"__summary__{api}"] = self.logs[f"__summary__{api}"]
        self.logs = ordered_logs

    def sorted_by_rate_speed(self, apis, addrisp=None, reverse=True):
        '''
        Return a new list containing all input `apis` in new order.
        The order of the APIs is based on the key:
            (rate, speed, common_name, common_alias, api_path).
        Default addrisp is :attr:`addrisp`.
        '''
        def key(api):
            summary = self.get_speed_summary(api, addrisp=addrisp)
            info = self.sites[api]
            urlpath = urlparse(api).path
            return (
                summary['rate'], summary['speed'],
                info['common_name'], info['common_alias'], urlpath,
            )
        return sorted(apis, key=key, reverse=reverse)

    def _get_last_updated_time(self):
        last_times = list(filter(None, [  # 过滤有效时间
            self.logs[api][-1].get('vod_api', {}).get('time', 0)
            for api in self.sites
            if len(self.logs.get(api, [])) > 0
        ]))
        # 平均各 API 最近更新时间
        last_seconds = sum(last_times)/len(last_times)
        return time.ctime(last_seconds)

    def summary_speedlogs(self, shownum=10, output=None, addrisp=None):
        '''
        Summarize and print speedlogs info of api sites sorted by rate, speed.
        Call after :meth:`test_speed`.

        Parameters
        ----------
        shownum: if <=0, show all.
        output: file path to save info
        addrisp: str
            filter speed_log by addrisp when sorting api sites
            default is :attr:`addrisp`, 'ALL' for sorting by all speed_logs
        '''
        outext = []
        success = [api for api in self.sites
                   if self.logs[api][-1]['status'] == "ok"]
        fail = [api for api in self.sites if api not in success]
        Nok = len(success)
        Nfail = len(fail)
        last_testime = self._get_last_updated_time()
        outext.append("==> API 总数：\033[34m%2d\033[0m, 最近更新：%s"
                      % (self.count, last_testime))
        outext.append(" -> 最近成功数：\033[32m%2d\033[0m" % Nok)
        outext.append(" -> 最近失败数：\033[31m%2d\033[0m" % Nfail)
        ordered = self.sorted_by_rate_speed(
            self.sites.keys(), addrisp=addrisp, reverse=True)
        # show first `shownum`
        shownum = shownum if shownum > 0 else self.count
        headprefix = "(可用率 rate, 平均速度 speed) "
        outext.append("==> 网络 ISP: %s" % (addrisp or self.addrisp))
        outext.append("==> %s排序靠前的 API：" % headprefix)
        for idx, api in enumerate(ordered[:shownum], 1):
            summary = self.get_speed_summary(api, addrisp=addrisp)
            useproxy = '🧱' if api in self.proxy_apis else '🌐'
            outext.append(" -> [%2d] %s %5.1f%%, %4.1f KB/s, %4s, %s"
                          % (idx, useproxy,
                             summary['rate']*100, summary['speed'],
                             self.sites[api]['common_name'], api))
        outext = '\n'.join(outext)
        print(outext)
        if output:
            outext = re.sub(r'\033\[[0-9;]+m', '', outext)
            with open(output, 'w') as out:
                out.write(outext)
                print("saving summary speed info in '%s'" % output)

    def select_apis(self, rate_limit=0.8, addrisp=None,
                    nameprefix=None, filterout=None, unique=True):
        '''
        Select apis, then return apis sorted by rate, speed.

        rate_limit: float
            summary speed rate > limit
        addrisp: str
            filter speed_log by addrisp when calculating speed summary
            Default is :attr:`addrisp`, 'ALL' for sorting by all speed_logs
        nameprefix: str, like 'TV-'
            info['common_name'] starts with **nameprefix**
            and also used for **unique**
        filterout: function condition(api, info)
            remove api that satisfies condition.
        unique: bool, default True
            unique API with name 'XXXXX', common_name="nameprefix(XXXXX)%d*"
        '''
        print("\nSelecting API, rate_limit=%s, addrisp=%s, nameprefix=%s, unique=%s ..."
              % (rate_limit, addrisp or self.addrisp, nameprefix, unique))
        SA = self.sites
        select = [
            api for api in SA.keys()
            if self.get_speed_summary(
                api, addrisp=addrisp).get('rate', 0) > rate_limit]
        if nameprefix:
            select = [api for api in select
                      if SA[api]['common_name'].startswith(nameprefix)]
        if callable(filterout):
            select = [api for api in select if not filterout(api, SA[api])]
        select = self.sorted_by_rate_speed(
            select, addrisp=addrisp, reverse=True)
        count = 0
        if unique:
            result, uniq_names = [], []
            for api in select:
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
            for api in select:
                count += 1
                common_name = SA[api]['common_name']
                print("[S%2d] %s %s\033[0m, %s"
                      % (count, 'Add', common_name, api))
            result = select
        print("==> \033[32m%d\033[0m APIs selected." % len(result))
        return result
