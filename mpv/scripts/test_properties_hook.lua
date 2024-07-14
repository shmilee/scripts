---------------------------------------------------------------------------
--
--  test mpv script add_hook, get/set properties
--  need inspect module
--
--  Copyright (c) 2024 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
-- Ref:
-- 1. https://github.com/mpv-player/mpv/blob/master/player/lua/ytdl_hook.lua
-- 2. https://mpv.io/manual/master/#hooks
-- 3. https://mpv.io/manual/master/#lua-scripting-mp-add-hook(type,-priority,-fn)
---------------------------------------------------------------------------

local msg = require("mp.msg")
local utils = require("mp.utils")
local home = os.getenv('HOME')
package.path = package.path .. string.format(';%s/.config/mpv/scripts/?.lua', home)
local inspectloaded, inspect = pcall(require, 'inspect')
if not inspectloaded then
    msg.warn('inspect not found!')
    inspect = tostring
end
msg.warn('package.path: ' .. package.path)

local function get_url(label)
    local path = mp.get_property("path", "")
    msg.warn('-> ' .. label .. ', path=[[' .. path ..']]')
    local url = mp.get_property("stream-open-filename", "")
    msg.warn('-> ' .. label .. ', url=[[' .. url ..']]')
    return url
end

local url0 = get_url('0')

-- type: on_load

mp.add_hook("on_load", 3, function ()
    msg.warn('=> priority=3!')
    local url = get_url('3')
end)

-- ytdl_hook/on_load, priority=10

mp.add_hook("on_load", 14, function ()
    msg.warn('=> priority=14!')
    local url = get_url('14')

    local a,b = utils.split_path('/real/file.mp4')
    msg.warn('-> 14, utils.split_path: [2]=' .. b)
    msg.warn('-> 14, utils.join_path:' .. utils.join_path('c/', 'a/b'))
    --local path = 'https://real-by-no-effect.mp4'
    --msg.warn('-> 14, set-path=[[' .. path ..']]???X')
    --mp.set_property("path", path)  -- no effect

    --local url = 'mpv://test-all-broken.mp4'
    --msg.warn('-> 14, set-url=[[' .. url ..']]')
    --mp.set_property("stream-open-filename", url)
end)

-- ytdl_hook/on_load, priority=20

mp.add_hook("on_load", 37, function ()
    msg.warn('=> priority=37!')
    local url = get_url('37')
end)

local properties = {
    --'property-list',
    'filename',
    'path',
    'stream-open-filename',
    'audio-files',  -- https://mpv.io/manual/master/#list-options
    'http-header-fields',
    'force-media-title',
    'playlist',
    'platform',
    'ytdl',
    'ytdl-raw-options',
    'ytdl-raw-options-append',
    'options/ytdl',
    'cookies',
    'cookies-file',
    'profile',
    --'profile-list',
    'ytdl-format',
    'sub-files',
    'volume',
    'user-agent',
    'referrer',
    'msg-level',
}

local function show_priority(lv, i, pro)
    local p = mp.get_property(pro, "")
    msg.warn(string.format('-> %d, i=%d, %s=[[%s]]', lv, i, pro, p))
    local pn = mp.get_property_native(pro, nil)
    if type(pn) ~= 'string' then
        -- table: ARRAY or MAP; boolean; number
        msg.warn(string.format('-> %d, i=%d, type(%s)=%s, %s',
                               lv, i, pro, type(pn), inspect(pn)))
    end
end

mp.add_hook("on_load", 6, function ()
    msg.warn('=> priority=6! show options!')
    for i, pro in ipairs(properties) do
        show_priority(6, i, pro)
    end
end)
mp.add_hook("on_load", 99, function ()
    msg.warn('=> priority=99! show options!')
    for i, pro in ipairs(properties) do
        show_priority(99, i, pro)
    end
end)
