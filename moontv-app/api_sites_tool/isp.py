# -*- coding: utf-8 -*-

# Copyright (c) 2025 shmilee

import requests


class IspDetector(object):

    APIS_ISP = [
        # (url, isp_field),
        ('https://ipapi.co/json/', 'org'),
        ('https://ipinfo.io/json/', 'org'),
        ('http://ip-api.com/json/', 'isp'),
    ]

    default_requests_kwargs = dict(timeout=10, headers={
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64) Firefox/142.0',
    })

    def __init__(self, qqKey=None, baiduAK=None, requests_kwargs={}):
        if qqKey or baiduAK:
            self.qqKey = qqKey
            self.baiduAK = baiduAK
        else:
            raise ValueError('Need QQ API Key or Baidu API AK!')
        self.requests_kwargs = self.default_requests_kwargs.copy()
        self.requests_kwargs.update(requests_kwargs)
        # 位置，国内API比较准确
        info = self._api_baidumap()
        addr = info['addr'] or self._api_qqmap() or '未知'
        addr = addr.replace(' ', '_').replace('省', '').replace('市', '')
        # ISP
        isp = '未知'
        for url, field in self.APIS_ISP:
            response = self._fetch_api_data(url, url)
            if response and response.get(field, None):
                isp = self._standardize_isp(response[field])
                break
        self.addr = addr
        self.isp = isp
        print(f"本机网络运营商(ISP)为: {self.addrisp}")

    @property
    def addrisp(self):
        return f'{self.addr}+{self.isp}'

    def _fetch_api_data(self, name, url):
        print(f"尝试API {name}...")
        try:
            response = requests.get(url, **self.requests_kwargs)
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
        response = self._fetch_api_data(name, url)
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
        response = self._fetch_api_data(name, url)
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
