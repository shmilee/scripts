1 None tvid
===========

error:
```shell
File "/usr/lib/python3.10/site-packages/you_get/extractors/iqiyi.py", line 139, in prepare
    info_u = 'http://pcw-api.iqiyi.com/video/video/playervideoinfo?tvid=' + tvid
TypeError: can only concatenate str (not "NoneType") to str
```

debug:
```python
from you_get.common import r1, get_html, matchall

html = get_html('https://www.iqiyi.com/v_19rrnojxs8.html')
# "tvid":355406500    "vid":"f7b856423aa11ffb68590d516d028074"
matchall(html,[r'(.{10}355406500.{10})'])
matchall(html,[r'(.{10}f7b856423aa11ffb68590d516d028074.{10})'])
```

fix:
```python
tvid = r1(r'#curid=(.+)_', self.url) or \
       r1(r'tvid=([^&]+)', self.url) or \
       r1(r'data-player-tvid="([^"]+)"', html) or r1(r'tv(?:i|I)d=(.+?)\&', html) or r1(r'param\[\'tvid\'\]\s*=\s*"(.+?)"', html) or \
       r1(r'"tvid"\s*:\s*(\d+?),', html)
videoid = r1(r'#curid=.+_(.*)$', self.url) or \
          r1(r'vid=([^&]+)', self.url) or \
          r1(r'data-player-videoid="([^"]+)"', html) or r1(r'vid=(.+?)\&', html) or r1(r'param\[\'vid\'\]\s*=\s*"(.+?)"', html) or \
          r1(r'"vid"\s*:\s*"(.+?)",', html) or r1(r'vid="(.+?)";', html)
```


2 cookie headers, HTTP Error 400: Bad Request
=============================================

error:
```
you-get -c ~/.mozilla/firefox/xxx/cookies.sqlite https://www.iqiyi.com/v_t93ogo9gbc.html --debug

[DEBUG] get_content: http://pcw-api.iqiyi.com/video/video/playervideoinfo?tvid=3091246365554100
[DEBUG] HTTP Error with code400
...........
File "/usr/lib/python3.10/site-packages/you_get/extractors/iqiyi.py", line 142, in prepare
    json_res = get_content(info_u)
  File "/usr/lib/python3.10/site-packages/you_get/common.py", line 474, in get_content
    response = urlopen_with_retry(req)
..........
  File "/usr/lib/python3.10/urllib/request.py", line 643, in http_error_default
    raise HTTPError(req.full_url, code, msg, hdrs, fp)
urllib.error.HTTPError: HTTP Error 400: Bad Request
```

debug:
```
        for cookie in list(cookies):
            cookie_strings.append(cookie.name + '=' + cookie.value)
        cookie_headers = {'Cookie': '; '.join(cookie_strings)}
        req.headers.update(cookie_headers)
```

fix:
```
TODO
```
