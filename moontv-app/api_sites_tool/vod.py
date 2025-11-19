# -*- coding: utf-8 -*-

# Copyright (c) 2025 shmilee

import re
import json
import random
import html
from .speedtest import SpeedTest


class VodAPI(object):

    M3U8_PATTERN = '(https?:\/\/[^\"\'\s]+?\.m3u8)'

    def __init__(self, api, name, detail=None, timeout=10, UA=None):
        self.api = api
        self.name = name
        self.detail = detail
        self.tester = SpeedTest(timeout=timeout, UA=UA, default_headers={
            'Accept': 'application/json,text/html',
            'Accept-Encoding': 'gzip, deflate, zstd',
        })
        data, info = self.tester.fetch(api, name)
        if data:
            data = json.loads(data)
            if data.get('list', None) and len(data['list']) > 0:
                self.api_json = data
            else:
                raise ValueError(f'Invalid {name} response: {data}')
        else:
            raise ValueError(f'Invalid {name} api: {api}')

    def random_vod_id(self):
        vods = self.api_json.get('list', [])
        if vods:
            idx = random.randint(0, len(vods)-1)
            if 'vod_id' in vods[idx]:
                return vods[idx]['vod_id']

    def getDetail(self, vod_id):
        '''
        Get detail info for vod_id.
        Try to use api first, then html page if needed.
        '''
        result = self.getDetailFromApi(vod_id)
        if not result and self.detail:
            result = self.getDetailFromPage(vod_id)
        return result

    def getDetailFromApi(self, vod_id):
        url = f'{self.api}?ac=videolist&ids={vod_id}'
        data, _ = self.tester.fetch(url, self.name)
        if data:
            data = json.loads(data)
            if data.get('list', None) and len(data['list']) > 0:
                video_detail = data['list'][0]
                return self.__parse_video_detail(vod_id, video_detail)
        print(f'Invalid {self.name} detail response: {data}')
        return

    def __parse_video_detail(self, vod_id, video_detail):
        episodes = []
        episodes_titles = []
        # 处理播放源拆分
        if video_detail.get('vod_play_url'):
            # 先用 $$$ 分割
            vod_play_url_array = video_detail['vod_play_url'].split('$$$')
            # 分集之间#分割，标题和播放链接 $ 分割
            for play_urls in vod_play_url_array:
                match_titles = []
                match_episodes = []
                title_url_array = play_urls.split('#')
                for title_url in title_url_array:
                    episode_title_url = title_url.split('$')
                    if (len(episode_title_url) == 2 and
                            episode_title_url[1].endswith('.m3u8')):
                        match_titles.append(episode_title_url[0])
                        match_episodes.append(episode_title_url[1])
                # 选择最长的播放列表
                if len(match_episodes) > len(episodes):
                    episodes = match_episodes
                    episodes_titles = match_titles
        # 如果播放源为空，则尝试从内容中解析 m3u8
        if not episodes and video_detail.get('vod_content'):
            m3u8pat = r'(https?://[^"\'\s]+?\.m3u8)'
            matches = re.findall(m3u8pat, video_detail['vod_content']) or []
            episodes = [link.lstrip('$') for link in matches]
        if not episodes:
            return
        # 标题
        title = re.sub(r'\s+', ' ', video_detail.get('vod_name', '').strip())
        # 年份
        if video_detail.get('vod_year', None):
            match = re.search(r'\d{4}', video_detail['vod_year'])
            year_text = match.group(0) if match else ''
        else:
            year_text = ''
        return dict(
            vod_id=vod_id,
            episodes=episodes,
            episodes_titles=episodes_titles,
            title=title,
            year=year_text,
            poster=video_detail.get('vod_pic', ''),
            desc=self.clean_html_tags(video_detail.get('vod_content', '')),
            douban_id=video_detail.get('vod_douban_id', 0),
        )

    def getDetailFromPage(self, vod_id):
        if not self.detail:
            print('Need detail URL!')
            return
        url = f'{self.detail}/index.php/vod/detail/id/{vod_id}.html'
        data, _ = self.tester.fetch(url, self.name)
        if not data:
            return
        html = data.decode()
        ffzy_pat = r'\$(https?://[^"\'\s]+?/\d{8}/\d+_[a-f0-9]+/index\.m3u8)'
        matches = re.findall(ffzy_pat, html) or []
        if not matches:
            pattern = r'\$(https?://[^"\'\s]+?\.m3u8)'
            matches = re.findall(pattern, html) or []
        # 去重并清理链接前缀
        cleaned_matches = []
        for link in list(set(matches)):
            # 去掉开头的 $
            link = link[1:] if link.startswith('$') else link
            # 处理括号内容
            paren_index = link.find('(')
            if paren_index > 0:
                link = link[:paren_index]
            cleaned_matches.append(link)
        matches = cleaned_matches
        if not matches:
            return
        # 根据 matches 数量生成剧集标题
        episodes_titles = [str(i + 1) for i in range(len(matches))]
        # 提取标题
        title_match = re.search(r'<h1[^>]*>([^<]+)</h1>', html)
        title_text = title_match.group(1).strip() if title_match else ''
        if not title_text:
            title_match = re.search(r'<h2[^>]*>([^<]+)</h2>', html)
            title_text = title_match.group(1).strip() if title_match else ''
        # 提取年份
        year_match = re.search(r'>(\d{4})<', html)
        year_text = year_match.group(1) if year_match else ''
        # 提取封面
        cover_match = re.search(r'(https?://[^"\'\s]+?\.jpg)', html)
        cover_url = cover_match.group(1).strip() if cover_match else ''
        # 提取描述
        desc_match = re.search(r'''
            <div[^>]*class=["\'](?:sketch|vodplayinfo)["\'][^>]*>
            ([\s\S]*?)</div>
            ''', html, re.VERBOSE)
        if desc_match:
            desc_text = self.clean_html_tags(desc_match.group(1))
        else:
            desc_text = ''
        return dict(
            vod_id=vod_id,
            episodes=matches,
            episodes_titles=episodes_titles,
            title=title_text,
            year=year_text,
            poster=cover_url,
            desc=desc_text,
            douban_id=0,
        )

    @staticmethod
    def clean_html_tags(text):
        if not text:
            return ''
        # 将 HTML 标签替换为换行
        cleaned_text = re.sub(r'<[^>]+>', '\n', text)
        # 将多个连续换行合并为一个
        cleaned_text = re.sub(r'\n+', '\n', cleaned_text)
        # 将多个连续空格和制表符合并为一个空格，但保留换行符
        cleaned_text = re.sub(r'[ \t]+', ' ', cleaned_text)
        # 去掉首尾换行
        cleaned_text = re.sub(r'^\n+|\n+$', '', cleaned_text)
        # 去掉首尾空格
        cleaned_text = cleaned_text.strip()
        # 使用 html 模块解码 HTML 实体
        return html.unescape(cleaned_text)

    def search(self, query):
        # NOT-TODO {self.api}?ac=videolist&wd={query}
        return
