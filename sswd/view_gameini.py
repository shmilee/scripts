#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2022 shmilee

import os
import zipfile
import json
import re


class Gameini(object):
    '''
    Game ini. name: n; key: k_{n}; attr: ini.k_{n}
    '''

    def __init__(self, path):
        if zipfile.is_zipfile(path):
            self.path = path
        else:
            raise ValueError(f'Invalid zipfile {path}!')
        data = self.ParseData()
        self.data = data
        self.attr_keys = [f'k_{k}' for k in data.keys()]
        for k in data:
            setattr(self, f'k_{k}', data[k])

    def pretty_dump(self, path):
        with open(path, "w") as f:
            json.dump(self.data, f, sort_keys=True, ensure_ascii=False,
                      indent=2)

    def ParseData(self):
        with zipfile.ZipFile(self.path, mode='r') as z:
            with z.open('gameini.json') as f:
                data = json.load(f)
        for k in data:
            data[k] = self.ParseSingleData(k, data[k])
        return data

    def ParseSingleData(self, n, s):
        ''' keys: 'data', 'key', 'type', 'num' '''
        # event_dialogue: more parseKey, parseType
        f = s.pop('data').split("$")
        u = s.pop('key').split(",")
        d = list(map(int, s.pop('type').split(",")))
        l = s.pop('num')
        g = len(u)
        p = len(f) // g
        m = 0

        def number(x):
            return int(x) if x.isdigit() else float(x)

        # start
        if len(f) > 1:
            if len(f) % g != 0:
                print(f' >> Error: {n} 数据长度不对等!')
            for I in range(p):
                y, v = {}, ''
                for b in range(g):
                    i, a = u[b], f[m]
                    if d[b] == 1:
                        y[i] = number(a) if a else 0
                    elif d[b] == 2:
                        y[i] = number(f[m]) if a else 0
                    elif d[b] == 3:
                        y[i] = a
                    else:
                        print(f' >> Error: {n} =未知类型:d[b]')
                    if b < l:
                        v += a or '0'
                        if b < l - 1:
                            v += "&"
                    m += 1
                s[v] = y
            return s
        else:
            print(f' >> Error: {n} 空数据!')

    def get(self, n):
        d = getattr(self, n if n.startswith('k_') else f'k_{n}', {})
        if not d:
            print(f' >> Error: {n} 空数据!')
        return d

    def _check_all_in(self, words, string, invert=False):
        words = words or []
        words = words if isinstance(words, (list, tuple)) else [words]
        for w in words:
            if invert:
                if w in string:
                    return False
            else:
                if w not in string:
                    return False
        return True

    def show_item_base(self, search=None, exclude=None):
        ib = self.get('item_base')
        skeys = filter(lambda i: self._check_all_in(
            search, f"#{ib[i]['ItemTypeName']}#{ib[i]['ItemName']}#"
            + f"{ib[i]['ItemDesc']}"), ib.keys())
        skeys = filter(lambda i: self._check_all_in(
            exclude, f"#{ib[i]['ItemTypeName']}#{ib[i]['ItemName']}#"
            + f"{ib[i]['ItemDesc']}", invert=True), skeys)
        for i in skeys:
            tn, n = ib[i]['ItemTypeName'], ib[i]['ItemName']
            bind, desc = ib[i]['IsBind'], ib[i]['ItemDesc']
            price, icon = ib[i]['ItemPrice'], ib[i]['ItemIcon']
            print(f'{tn} {n} (绑定{bind}, 价格{price}): {desc}')

    def _match_name(self, n, sn, name=None):
        if name is None:
            return True
        if name in (n, sn) or re.search(name, n) or re.search(name, sn):
            return True
        return False

    def show_role_info(self, name=None):
        base, desc = self.get('role_base'), self.get('RoleDesc')
        fett = self.get('role_fetter')
        biog = self.get('k_RoleBiography')
        for i in base:
            n, sn = base[i]['RoleName'], base[i]['SubName']
            rid, did = str(base[i]['RoleID']), str(base[i]['RoleDesc'])
            if self._match_name(n, sn, name) and did != '0':
                print(f"\n> ID={rid} {n} {sn}")
                print(f" >> Desc: {desc[did]['Desc']}")
                moredesc = biog.get(rid, None)
                if moredesc:
                    for j in map(str, range(1, 6)):
                        if f'Des{j}' not in moredesc:
                            continue
                        print(f"    {moredesc['Des'+j]}")
                fid = str(base[i]['FetterID'])
                for j in map(str, range(1, 7)):
                    if f'{fid}&{j}' not in fett:
                        continue
                    print(f" >> Fetter{j} {fett[fid+'&'+j]['FetterName']}:",
                          f"{fett[fid+'&'+j]['FetterDesc']}")

    def show_develop_info(self):
        ''' other: faction_upgrade, '''
        pass


if __name__ == '__main__':
    ini = Gameini('./sswd-static/res/config/gameini6d74e2e0.zip')
    #ini.show_item_base(search='称号', exclude=('收集', '活动'))
    ini.show_role_info('蓝')
    # ini.pretty_dump('./Parsed-gameini.json')
