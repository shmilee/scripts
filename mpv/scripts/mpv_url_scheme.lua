---------------------------------------------------------------------------
--
-- on_load hook script for mpv:// URI Scheme,
-- read and write the stream-open-filename property etc.
--
-- Ref:
-- 1. https://mpv.io/manual/master/#lua-scripting
-- 2. https://mpv.io/manual/master/#hooks
-- 3. https://mpv.io/manual/master/#lua-scripting-mp-add-hook(type,-priority,-fn)
-- 4. https://github.com/mpv-player/mpv/blob/master/player/lua/ytdl_hook.lua
--
--  Copyright (c) 2024 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local msg = require("mp.msg")
local options = require("mp.options")
local utils = require("mp.utils")

local o = {
    enable = true,
    hook_type = 'on_load',  -- see mp.add_hook(type,priority,fn)
    hook_priority = 8,      -- before ytdl_hook/on_load, priority=10
    -- labels of protocols
    protocols = 'play-base64|url-opts|play-msix|open-iina|open-m3u8',
    cookies_path = '~/.config/mpv/cookies/;~/.config/mpv-handler/cookies/',
    ytdl_prefix = true,  -- prefixing http(s) URLs with 'ytdl://' or not
}
options.read_options(o)
-- ytdl_prefix, boolean to string
if o.ytdl_prefix then
    o.ytdl_prefix = 'ytdl://'
else
    o.ytdl_prefix = ''
end

-- decode safe-base64-encoded-URL
local base64 = {  --{{{
    url='https://github.com/iskolbin/lbase64',
    author={'Ilya Kolbin', 'shmilee'},
    COMPATIBILITY='Lua 5.1+, LuaJIT',
    LICENSE=[[
ALTERNATIVE A - MIT License
Copyright (c) 2024 shmilee
Copyright (c) 2018 Ilya Kolbin
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]],
}

base64.extract = _G.bit32 and _G.bit32.extract -- Lua 5.2/Lua 5.3 in compatibility mode
if not base64.extract then
    if _G.bit then -- LuaJIT
        local shl, shr, band = _G.bit.lshift, _G.bit.rshift, _G.bit.band
        base64.extract = function( v, from, width )
            return band( shr( v, from ), shl( 1, width ) - 1 )
        end
    elseif _G._VERSION == "Lua 5.1" then
        base64.extract = function( v, from, width )
            local w = 0
            local flag = 2^from
            for i = 0, width-1 do
                local flag2 = flag + flag
                if v % flag2 >= flag then
                    w = w + 2^i
                end
                flag = flag2
            end
            return w
        end
    else -- Lua 5.3+
        base64.extract = load[[return function( v, from, width )
            return ( v >> from ) & ((1 << width) - 1)
        end]]()
    end
end

function base64.makedecoder(s62, s63, spad)
    local decoder = {}
    for b64code, char in pairs{[0]='A','B','C','D','E','F','G','H','I','J',
        'K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y',
        'Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n',
        'o','p','q','r','s','t','u','v','w','x','y','z','0','1','2',
        '3','4','5','6','7','8','9',s62 or '+',s63 or'/',spad or'='} do
        decoder[char:byte()] = b64code
    end
    return decoder
end
-- replace / to _, + to -
base64.SAFE_DECODER = base64.makedecoder('-', '_', '=')

function base64.safe_decode(b64, decoder)
    decoder = decoder or base64.SAFE_DECODER
    local s62, s63, spad = string.byte('+'), string.byte('/'), string.byte('=')
    for charcode, b64code in pairs(decoder) do
        if b64code == 62 then s62 = charcode
        elseif b64code == 63 then s63 = charcode
        elseif b64code == 64 then spad = charcode
        end
    end
    local char = string.char
    pattern = ('[^%%w%%%s%%%s%%%s]'):format(char(s62), char(s63), char(spad))
    b64 = b64:gsub(pattern, '')
    local t, k = {}, 1
    local _left = #b64 % 4
    if _left == 2 or _left == 3 then
        -- add padding == or =, ref: https://stackoverflow.com/questions/4080988
        b64 = b64 .. string.rep(char(spad), 4-_left)
    elseif _left == 1 then
        msg.warn(string.format('Decoding an invalid base64 encoded string! len=%d', #b64))
    end
    local n = #b64
    local padding = b64:sub(-2) == char(spad):rep(2) and 2 or b64:sub(-1) == char(spad) and 1 or 0
    for i = 1, padding > 0 and n-4 or n, 4 do
        local a, b, c, d = b64:byte(i, i+3)
        local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40 + decoder[d]
        local s = char(base64.extract(v,16,8), base64.extract(v,8,8), base64.extract(v,0,8))
        t[k] = s
        k = k + 1
    end
    if padding == 1 then
        local a, b, c = b64:byte(n-3, n-1)
        local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40
        t[k] = char(base64.extract(v,16,8), base64.extract(v,8,8))
    elseif padding == 2 then
        local a, b = b64:byte(n-3, n-2)
        local v = decoder[a]*0x40000 + decoder[b]*0x1000
        t[k] = char(base64.extract(v,16,8))
    end
    return table.concat(t)
end
-- base64 end  --}}}

local myutils = {
    unescape_url = function(url)
        -- decode a URL, ref: https://stackoverflow.com/questions/20282054
        return url:gsub("%%(%x%x)", function(x)
            return string.char(tonumber(x, 16))
        end)
    end,
    file_readable = function(filepath)
        local f = io.open(filepath, "rb")
        if f then f:close() end
        return f ~= nil
    end,
    table_haskey = function(t, key)
        for k, v in pairs(t) do
            if k == key then
                return true
            end
        end
        return false
    end,
    table_hasval = function(t, item)
        for k, v in pairs(t) do
            if v == item then
                return true
            end
        end
        return false
    end,
    table_empty = function(t)
        for k, v in pairs(t) do
            return false
        end
        return true
    end,
    ytdl_enabled = function()
        local ytdl = mp.get_property('ytdl', '')
        return ytdl == 'yes'
    end,
    get_profile_names = function()
        local names = {}
        local pl = mp.get_property_native('profile-list', {})
        for _, v in ipairs(pl) do
            if v.name then
                table.insert(names, v.name)
            end
        end
        return names
    end,
}

-- searching filename in directories `dpaths`
-- The dpaths can be splited by ';', for example o.cookies_path.
function myutils.search_file(dpaths, filename)
    for d in string.gmatch(dpaths, "([^;]+)") do
        if d:match('^~/') then
            d = string.gsub(d, '^~', os.getenv('HOME'))
        end
        local file = utils.join_path(d, filename)
        msg.verbose('searching file: '.. file)
        if myutils.file_readable(file) then
            return file
        end
    end
end

function myutils.setting_properties(properties, t)
    for _, prop in pairs(properties) do
        if t[prop] then
            if type(t[prop]) == "table" then
                -- only for table properties
                -- see manual #lua-scripting-mp-set-property-native
                msg.info(string.format(
                    'setting table %s=%s', prop, utils.to_string(t[prop])))
                ret, err = mp.set_property_native(prop, t[prop])
            else
                msg.info(string.format(
                    'setting %s=%s', prop, utils.to_string(t[prop])))
                ret, err = mp.set_property(prop, t[prop])
            end
            if not ret then
                msg.warn(string.format('setting %s ERROR: %s', prop, err))
            end
        end
    end
end

-- Protocol 1:
--    mpv://play/safe-base64-encoded-URL/?param1=value1&param2=value2
--    mpv-debug://play/safe-base64-encoded-URL/?param1=value1&param2=value2
local Protocol_1 = {  -- {{{
    ref = 'https://github.com/akiirui/mpv-handler',
    pattern_url = '^mpv://play/([%w-_]+)[/]?[%?]?',
    pattern_param = '^mpv://play/[%w-_]+/%?(.*)',
    match = function(self, s)
        s = string.gsub(s, '^mpv%-debug://', 'mpv://')
        if s:match(self.pattern_url) then
            return true
        else
            return false
        end
    end,
}

Protocol_1.param_handlers = {
    ['cookies'] = function(k, v, t)
        if not myutils.ytdl_enabled() then
            msg.warn('ytdl hook-script not enabled, cookies have no effect!')
            return
        end
        if myutils.file_readable(v) then
            t['ytdl-raw-options'][k] = v
            return
        end
        local d, filename = utils.split_path(v)
        --split the o.cookies_path, searching cookies file
        local file = myutils.search_file(o.cookies_path, filename)
        if file then
            t['ytdl-raw-options'][k] = file
        else
            msg.warn(string.format('cookies file %s not found/readable!', v))
        end
    end,
    ['profile'] = function(k, v, t)
        local profiles = myutils.get_profile_names()
        if myutils.table_hasval(profiles, v) then
            t[k] = v
        else
            msg.warn(string.format('unknown profile %s, ignore it!', v))
        end
    end,
    ['quality'] = function(k, v, t)
        if not myutils.ytdl_enabled() then
            msg.warn('ytdl hook-script not enabled, quality has no effect!')
            return
        end
        v = v:match('^(%d+)p')
        if v then
            table.insert(t['_ytdl_format_sort'], string.format('res:%s', v))
        end
    end,
    ['v_codec'] = function(k, v, t)
        if not myutils.ytdl_enabled() then
            msg.warn('ytdl hook-script not enabled, v_codec has no effect!')
            return
        end
        table.insert(t['_ytdl_format_sort'], string.format('+vcodec:%s', v))
    end,
    ['subfile'] = function(k, v, t)
        v = base64.safe_decode(v)
        table.insert(t['sub-files'], v)
    end,
}

function Protocol_1.parse(self, s)
    s = string.gsub(s, '^mpv%-debug://', 'mpv://')
    local t = {}
    local b64url = string.match(s, self.pattern_url)
    t['stream-open-filename'] = o.ytdl_prefix .. base64.safe_decode(b64url)
    local query = string.match(s, self.pattern_param)
    if query then
        t['ytdl-raw-options'] = mp.get_property_native('ytdl-raw-options', {})
        t['_ytdl_format_sort'] = {}
        t['sub-files'] = mp.get_property_native('sub-files', {})
        for kv in string.gmatch(query, "([^&]+)") do
            local k, v = string.match(kv, "([%w_]+)=(.*)")
            local h = self.param_handlers[k]
            if type(h) == 'function' then
                h(k, v, t)
            end
        end
        if #t['_ytdl_format_sort'] > 0 then
            local newfs = table.concat(t['_ytdl_format_sort'], ',')
            local oldfs = t['ytdl-raw-options']['format-sort']
            if oldfs then
                newfs = oldfs .. ',' .. newfs -- may have duplicate
            end
            t['ytdl-raw-options']['format-sort'] = newfs
        end
        if myutils.table_empty(t['ytdl-raw-options']) then
            t['ytdl-raw-options'] = nil
        end
        if myutils.table_empty(t['sub-files']) then
            t['sub-files'] = nil
        end
    end
    return t
end

function Protocol_1.setting(self, t)
    if t['profile'] then
        -- ref: https://github.com/mpv-player/mpv/blob/master/player/lua/auto_profiles.lua
        msg.info("Applying profile: " .. t['profile'])
        mp.commandv("apply-profile", t['profile'])
    end
    myutils.setting_properties({
        'stream-open-filename', 'ytdl-raw-options', 'sub-files',
    }, t)
end
-- Protocol_1  -- }}}

-- Protocol 2:
--    mpv://<URL-encoded-string-of-mpv-options-below>
--    mpv://"${videoUrl}" --audio-file="${audioUrl}" --sub-file="${subtitleUrl}" \
--      --force-media-title="${title}" --start=${startTime} \
--      --http-header-fields="referer: ${referer}" \
--      --http-header-fields="origin: ${origin}" \
--      --http-proxy=${proxy} --ytdl-raw-options=proxy=[${proxy}] ${other}
--    mpv-debug://"${videoUrl}" --other-above-options-...
local Protocol_2 = {  -- {{{
    ref = {'https://github.com/LuckyPuppy514/Play-With-MPV',
           'https://github.com/LuckyPuppy514/Play-With-MPV/issues/124',
           'https://github.com/LuckyPuppy514/Play-With-MPV/blob/04a6387b0a0875c36249d5f336a0f4db3a09cf8f/play-with-mpv.user.js#L220-L233'},
    pattern_url = '^mpv://%%22(http[s]?.-)%%22%%20[%-]*',
    pattern_options = '^mpv://%%22http[s]?.-%%22%%20%-%-(%a+.*)',
    match = function(self, s)
        s = string.gsub(s, '^mpv%-debug://', 'mpv://')
        if s:match(self.pattern_url) then
            return true
        else
            return false
        end
    end,
    array_opt_handler = function(k, v, t, add_ks)
        if add_ks then
            k = k .. 's'
        end
        t[k] = t[k] or mp.get_property_native(k, {})
        if not myutils.table_hasval(t[k], v) then
            table.insert(t[k], v)
        end
    end,
}

function Protocol_2.parse(self, s)
    s = string.gsub(s, '^mpv%-debug://', 'mpv://')
    local t = {}
    local videourl = string.match(s, self.pattern_url)
    t['stream-open-filename'] = myutils.unescape_url(videourl)
    local opts = string.match(s, self.pattern_options)
    if opts then
        opts = string.gsub(opts, '%%20%-%-', '@')  -- separator ' --' -> '@'
        for kv in string.gmatch(opts, "([^@]+)") do
            local k, v = string.match(kv, "([%a%-]-)=(.*)")
            v = myutils.unescape_url(v)
            -- delete ^$ space and "
            v = string.gsub(string.gsub(v, '^%s+', ''), '%s+$', '')
            v = string.gsub(string.gsub(v, '^"', ''), '"$', '')
            if k == 'audio-file' or k == 'sub-file' then
                self.array_opt_handler(k, v, t, true)
            elseif k == 'http-header-fields' then
                for vv in string.gmatch(v, "([^,]+)") do  -- separated by ','
                    self.array_opt_handler(k, vv, t, false)
                end
            elseif k == 'ytdl-raw-options' then
                t[k] = t[k] or mp.get_property_native(k, {})
                local vk, vv = string.match(v, "([%a%-]-)=(.*)")
                t[k][vk] = vv
            else  -- 'force-media-title', 'start', 'http-proxy', other-options
                t[k] = v
            end
        end
        -- check referer
        local referer
        if t['http-header-fields'] then
            for _, field in pairs(t['http-header-fields']) do
                local k, v = string.match(field, "([%a%-]-):(.*)")
                if k == 'referer' then
                    referer = string.gsub(v, '^%s+', '')
                    break
                end
            end
        else
            t['http-header-fields'] = {}
        end
        if referer == nil then
            if string.find(videourl, '%.bilivideo%.c[nom]+') then
                referer = "https://www.bilibili.com"
            else
                referer = string.match(videourl, '(http[s]?://[%w%-%._]-)/')
            end
            if referer then
                table.insert(t['http-header-fields'], 'referer:' .. referer)
            end
        end
        --t['referrer'] = t['referrer'] or referer
        -- try to add cookies by referer domain name
        if referer then
            local domain = string.match(referer, 'http[s]?://([%w%-%._]+)')
            if domain and domain:len() >= 3 then
                local cookie = myutils.search_file(o.cookies_path, domain)
                if not cookie then
                    cookie = myutils.search_file(o.cookies_path, domain..'.txt')
                end
                --msg.info(string.format('COOKIE: %s, %s', domain, cookie))
                if cookie then
                    if t['ytdl-raw-options'] and myutils.ytdl_enabled() then
                        t['ytdl-raw-options']['cookies'] = cookie
                    end
                    t['cookies'] = 'yes'
                    t['cookies-file'] = cookie
                end
            end
        end
    end
    return t
end

function Protocol_2.setting(self, t)
    myutils.setting_properties({
        'stream-open-filename', 'audio-files', 'sub-files',
        'force-media-title', 'start', 'http-header-fields', 'http-proxy',
        'ytdl-raw-options', 'referrer', 'cookies', 'cookies-file',
    }, t)
end
-- Protocol_2  -- }}}

-- Protocol 3:
--    mpv://play?file=https%3A%2F%2Fyoutu.be%2FXCs7FacjHQY&file=<next-url>
--    mpv-debug://play?file=https%3A%2F%2Fyoutu.be%2FXCs7FacjHQY
local Protocol_3 = {  -- {{{
    ref = 'https://github.com/SilverEzhik/mpv-msix',
    pattern_url = '^mpv://play%?(file=[.*]-[&]?.*)',
    match = function(self, s)
        s = string.gsub(s, '^mpv%-debug://', 'mpv://')
        return s:match(self.pattern_url)
    end,
}

function Protocol_3.parse(self, s)
    s = string.gsub(s, '^mpv%-debug://', 'mpv://')
    local t = {}
    local query = string.match(s, self.pattern_url)
    if query then
        -- read-only https://mpv.io/manual/master/#command-interface-playlist
        t['playlist'] = {}
        for kv in string.gmatch(query, "([^&]+)") do
            local k, v = string.match(kv, "([%w_]+)=(.*)")
            if k == 'file' then
                v = o.ytdl_prefix .. myutils.unescape_url(v)
                table.insert(t['playlist'], v)
            else
                msg.warn('Ignore option of mpv-launcher: ' .. kv)
            end
        end
        if #t['playlist'] > 0 then
            t['stream-open-filename'] = t['playlist'][1]
        end
    end
    return t
end

function Protocol_3.setting(self, t)
    myutils.setting_properties({'stream-open-filename'}, t)
    if #t['playlist'] > 0 then
        -- list file data in memory
        local list = "memory://" .. table.concat(t['playlist'], "\n")
        mp.commandv('loadlist', list)  -- loadlist <url> [<flags> [<index>]]
    end
end
-- Protocol_3  -- }}}

-- Protocol 4:
--    mpv:///open?url=https%3A%2F%2Fgithub.com%2F&pip=1&flags=--profile%3Dxxx'
local Protocol_4 = {  -- {{{
    ref = 'https://github.com/Baldomo/open-in-mpv',
    pattern_url = '^mpv:///open%?(url=[.*]-[&]?.*)',
    match = function(self, s)
        return s:match(self.pattern_url)
    end,
}

function Protocol_4.parse(self, s)
    local t = {}
    local query = string.match(s, self.pattern_url)
    local propertylist = mp.get_property_native('property-list', {})
    if query then
        for kv in string.gmatch(query, "([^&]+)") do
            local k, v = string.match(kv, "([%w_]+)=(.*)")
            if k == 'url' then
                v = o.ytdl_prefix .. myutils.unescape_url(v)
                t['stream-open-filename'] = v
            elseif k == 'full_screen' and v == '1' then
                t['fullscreen'] = 'yes'
            elseif k == 'pip' and v == '1' then
                -- "--ontop --no-border --autofit=384x216 --geometry=98%:98%"
                t['ontop'] = 'yes'
                t['border'] = 'no'
                t['autofit'] = '384x216'
                t['geometry'] = '+98%+98%'
            elseif k == 'flags' then
                v = string.gsub(v, '%%20[%-]+', '@')  -- ' --' -> '@'
                msg.verbose('flags@=[['.. v ..']]')
                for fvv in string.gmatch(v, "([^@]+)") do
                    fvv = myutils.unescape_url(fvv)
                    local f, vv = string.match(fvv, "[%-]+([%a%-]-)=(.*)")
                    msg.verbose(string.format('%s => %s=[[%s]]', fvv, f, vv))
                    if myutils.table_hasval(propertylist, f) then
                        local oldvv = mp.get_property_native(f, nil)
                        if type(oldvv) == 'table' then
                            table.insert(oldvv, vv)
                            vv = oldvv
                        end
                        t[f] = vv
                        msg.verbose(string.format('Get %s=[[%s]]', f, utils.to_string(vv)))
                    else
                        msg.warn(string.format('unknown option %s, ignore it!', f, vv))
                    end
                end
            else
                if k ~= 'player' then
                    msg.warn('Ignore params: ' .. kv)
                end
            end
        end
    end
    if t['stream-open-filename'] == nil then
        msg.warn("No url get!")
        return {}
    end
    return t
end

function Protocol_4.setting(self, t)
    local properties = {}
    for p, v in pairs(t) do
        if p == 'profile' then
            local profiles = myutils.get_profile_names()
            if myutils.table_hasval(profiles, v) then
                msg.info("Applying profile: " .. v)
                mp.commandv("apply-profile", v)
            else
                msg.warn(string.format('unknown profile %s, ignore it!', v))
            end
        else
            table.insert(properties, p)
        end
    end
    myutils.setting_properties(properties, t)
end
-- Protocol_4  -- }}}

-- Protocol 5:
--    mpv://https://url.com/path/to/video.m3u8
local Protocol_5 = {  -- {{{
    pattern_url = '^mpv://(http[s]?://.*%.m3u8)$',
    match = function(self, s)
        return s:match(self.pattern_url)
    end,
    parse = function(self, s)
        local t = {}
        local url = myutils.unescape_url(s:match(self.pattern_url))
        t['stream-open-filename'] = url
        local referer = string.match(url, '(http[s]?://[%w%-%._]-)/')
        if referer then
            local k = 'http-header-fields'
            t[k] = mp.get_property_native(k, {})
            table.insert(t[k], 'referer:' .. referer)
        end
        return t
    end,
    setting = function(self, t)
        myutils.setting_properties({
            'stream-open-filename', 'http-header-fields'
        }, t)
    end,
}
-- Protocol_5  -- }}}

local available_protocols = {
    -- ['label'] = { match=function, parse=function, setting=function, ... }
    ['play-base64'] = Protocol_1,
    ['url-opts'] = Protocol_2,
    ['play-msix'] = Protocol_3,
    ['open-iina'] = Protocol_4,
    ['open-m3u8'] = Protocol_5,
}

-- start
if o.enable then
    local registered_protocols = {}  -- labels
    --split the o.protocols labels
    for label in string.gmatch(o.protocols, "([^|]+)") do
        local proto = available_protocols[label]
        if proto ~= nil then
            msg.verbose('-> adding mpv_url_scheme: [[' .. label .. ']] ...')
            table.insert(registered_protocols, label)
        else
            msg.warn('Invalid mpv_url_scheme label: ' .. label)
        end
    end
    mp.add_hook(o.hook_type, o.hook_priority, function()
        local url = mp.get_property("stream-open-filename", nil) or mp.get_property("path", "")
        for _, label in pairs(registered_protocols) do
            local proto = available_protocols[label]
            if type(proto.match) == 'function' and proto:match(url) then
                msg.info(string.format('Using %s to handle %s', label, url))
                local t = proto:parse(url)
                proto:setting(t)
                break
            end
        end
    end)
end
