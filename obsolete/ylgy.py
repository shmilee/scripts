#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2022 shmilee

'''
250 lines to test https://cat-match.easygame2021.com/sheep/

ref:
1. https://github.com/lyzcren/sheep_win/blob/main/index.js
2. https://github.com/Lcry/a-sheep-assistant
'''

import random
import time
import requests
import pprint
import argparse
import sys

GAME_HOST = "cat-match.easygame2021.com"
GAME_URL_v1 = f"https://{GAME_HOST}/sheep/v1"
HEADERS = {
    'Accept-Encoding': 'gzip,compress,deflate',
    'Connection': 'keep-alive',
    'content-type': 'application/json',
    'Referer':
        'https://servicewechat.com/wx141bfb9b73c970a9/16/page-frame.html',
    'User-Agent': ('Mozilla/5.0 (Linux; Android 12; wv)'
                   'AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0'
                   'Mobile MicroMessenger/8.0.27.2220 Language/zh_CN'),
}
SRC_TOKEN = ('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2OTQ'
             '1MDI0NDUsIm5iZiI6MTY2MzQwMDI0NSwiaWF0IjoxNjYzMzk4NDQ'
             '1LCJqdGkiOiJDTTpjYXRfbWF0Y2g6bHQxMjM0NTYiLCJvcGVuX2l'
             'kIjoiIiwidWlkIjo0NTk0MjYwMiwiZGVidWciOiIiLCJsYW5nIjo'
             'iIn0.1lXIcb1WL_SdsXG5N_i1drjjACRhRZUS2uadHlT6zIY')


def _wait(a=0, b=3, info=None, end='\n'):
    '''info: f'{T}', T for time'''
    T = random.randint(a, b)
    if info:
        print(info.format(T=T), end=end)
    time.sleep(T)


def _get_json_data(meth, url, **req_kwargs):
    '''json response, {err_code: 0, err_msg: '', data: {}}'''
    try:
        res = requests.request(meth, url, **req_kwargs)
        if res.status_code == 200:
            resj = res.json()
            # pprint.pprint(resj)
            if resj['err_code'] == 0:
                return resj['data']
            else:
                print(f"> Error {resj['err_code']} {resj['err_msg']}:",
                      f"{resj['data']}")
        else:
            print(f"> Bad request {res.status_code}:", res.reason)
    except Exception as e:
        print(f"> ERROR:", e)
    return None


def get_openid_by_uid(uid, src_token=None, verbose=False,
                      req_timeout=6, req_verify=True, req_tries=3):
    '''
    Use *uid* to get openid, avatar.

    Parameters
    ----------
    uid: int
    src_token: str, source token to get wx_open_id
    verbose: bool, be verbose, default False
    req_timeout: float or int
        request timeout for meth:`requests.request`, default 10
    req_verify: bool or str
        request verify for meth:`requests.request`, default True
    req_tries: int, number of max request retries, default 3
    '''
    headers = dict(t=src_token if src_token else SRC_TOKEN, **HEADERS)
    for i in range(1, req_tries+1):
        _wait(info=r">>> After {T}s, "
              + f"try to get uid({uid})'s openid. (Round {i}) <<<")
        api = f"{GAME_URL_v1}/game/user_info?uid={uid}&t={src_token}"
        data = _get_json_data('GET', api, headers=headers,
                              timeout=req_timeout, verify=req_verify)
        if data:
            if verbose:
                pprint.pprint(data)
            openid = data["wx_open_id"]
            avatar = data["avatar"] or '1'
            print(f">>> Get openid: '{openid}'. <<<")
            return openid, avatar
    print(">>> Failed to get openid, please check your uid if valid, "
          "or check your network!")
    return None, None


def get_token_by_uid(uid, src_token=None, verbose=False,
                     req_timeout=6, req_verify=True, req_tries=3):
    '''
    Use *uid* to get token.

    Parameters
    ----------
    See :meth:`get_openid_by_uid`
    '''
    openid, avatar = get_openid_by_uid(
        uid, src_token=src_token, verbose=verbose,
        req_timeout=req_timeout, req_verify=req_verify, req_tries=req_tries)
    if not openid:
        return None
    login_body = {
        "uid": openid,
        "avatar": avatar,
        "nick_name": "f**ylgy",
        "sex": 1,
    }
    for i in range(1, req_tries+1):
        _wait(info=r">>> After {T}s, try to get token. " + f"(Round {i}) <<<")
        api = f"{GAME_URL_v1}/user/login_oppo"
        data = _get_json_data('POST', api, headers=HEADERS, json=login_body,
                              timeout=req_timeout, verify=req_verify)
        if data:
            pprint.pprint(data)
            token = data["token"]
            print(f">>> Get token: '{token}'.")
            if verbose:
                _wait(b=1, info=r">>> After {T}s, try to get more user info")
                api = f"{GAME_URL_v1}/game/personal_info?uid={uid}&t={token}"
                data = _get_json_data('GET', api, headers=HEADERS,
                                      timeout=req_timeout, verify=req_verify)
                if data:
                    print(">>> Get more user info:")
                    pprint.pprint(data)
            return token
    print(f">>> Failed to get uid({uid})'s token!")
    return None


def sheep_win(rank_time, token, rank_role=1, verbose=False,
              req_timeout=6, req_verify=True):
    query = ("rank_score=1&rank_state=1&skin=1&"
             f"rank_time={rank_time}&rank_role={rank_role}&t={token}")
    if rank_role == 1:
        api = f"{GAME_URL_v1}/game/game_over?{query}"
    elif rank_role == 2:
        api = f"{GAME_URL_v1}/game/topic_game_over?{query}"
    else:
        print(f">>> Invalid rank_role: {rank_role}!")
        return
    _wait(info=r">>> After {T}s, "
               f"try to win the rank_role={rank_role} game "
               f"with rank_time={rank_time}s. <<<")
    data = _get_json_data('GET', api, headers=dict(t=token, **HEADERS),
                          timeout=req_timeout, verify=req_verify)
    if data is not None:
        print(f">>> Success!")
        return True


def main():
    parser = argparse.ArgumentParser(
        description="YLGY helper v0.1.0 by shmilee",
        add_help=False,
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-t', dest='token', metavar='<token>',
                        nargs='*', type=str,
                        help='User token. Use token first.')
    parser.add_argument('-u', dest='uid', metavar='<uid>',
                        nargs='*', type=int,
                        help='User uid. Use uid if no token.')
    parser.add_argument('-r', dest='role', metavar='<role>',
                        nargs='*', default=[1, 2], type=int, choices=[1, 2],
                        help='Game role. 1 for default, 2 for topic, '
                             'default: %(default)s')
    parser.add_argument('-c', dest='count', metavar='<count>',
                        nargs=1, default=1, type=int,
                        help='How many times try to win, default: %(default)d')
    parser.add_argument('-s', dest='scan', metavar=('<a>', '<b>', '<step>'),
                        nargs=3, type=int,
                        help='Scan valid uids in range(a, b, step) and exit')
    parser.add_argument('-v', '--verbose', action='store_true',
                        help='Be verbose')
    parser.add_argument('-h', '--help', action='store_true',
                        help='Show this help message and exit')
    args = parser.parse_args()
    # print(args)
    if args.help:
        parser.print_help()
        sys.exit()
    if args.scan:
        uid_todo = range(*args.scan)
        if uid_todo:
            valid = []
            for uid in uid_todo:
                openid, avatar = get_openid_by_uid(
                    uid, verbose=args.verbose, req_tries=1)
                if openid:
                    valid.append(uid)
            if valid:
                # short valid
                vstr, pre, step = [], None, args.scan[2]
                for v in valid:
                    if pre and pre + step == v:
                        vstr[-1] = '%s-%s' % (vstr[-1].split('-')[0], v)
                    else:
                        vstr.append(str(v))
                    pre = v
                print("\n>>>>> Found valid uids:", ', '.join(vstr))
            else:
                print("\n>>>>> Found no valid uids!")
        else:
            print(">>>>> range(a, b, step) is empty!")
        sys.exit()
    couples = []  # (short-token or uid, token), ...
    if args.token:
        for token in args.token:
            couples.append((
                token[:5] + '.....' + token[-5:], token))
    elif args.uid:
        for uid in args.uid:
            token = get_token_by_uid(uid, verbose=args.verbose)
            print()
            if token:
                couples.append((uid, token))
    else:
        print(">>>>> Please set token or uid!")
        sys.exit(1)
    count = args.count[0] if type(args.count) == list else args.count
    if couples:
        print("Starting ...")
        for uid, token in couples:
            for role in args.role:
                success = 0
                for i in range(count):
                    rank_time = random.randint(300, 1800)
                    win = sheep_win(rank_time, token, rank_role=role,
                                    verbose=args.verbose)
                    if win:
                        success += 1
                print(f"\n>>>>> {uid} wins rank_role={role} game "
                      f"{success} times, (try {count} times)!\n")


if __name__ == '__main__':
    main()
