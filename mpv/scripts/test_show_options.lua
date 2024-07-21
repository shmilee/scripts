---------------------------------------------------------------------------
--
--  test mpv script options
--
--  Copyright (c) 2024 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
-- Ref:
-- 1. https://github.com/CogentRedTester/mpv-scripts/blob/master/show-errors.lua
-- 2. https://github.com/CogentRedTester/mpv-scripts/blob/master/youtube-search.lua
---------------------------------------------------------------------------

local msg = require "mp.msg"
local opts = require "mp.options"

local o = {
    --the default url to send API calls to
    API_path = "https://www.googleapis.com/youtube/v3/",

    --attempt this API if the default fails
    fallback_API_path = "https://fall.api.com/",

    API_key = "wrong key",
    --add a blacklist for error messages to not print to the OSD
    blacklist = "",  -- no table support

    --also show warning messages on the OSD
    warnings = false,

    --number of seconds to show the OSD messages
    timeout = 4
}

opts.read_options(o, 'test_show_options')

msg.warn('-> API_path is [[' .. o.API_path .. ']]')
msg.warn('-> fallback_API_path is [[' .. o.fallback_API_path .. ']]')
msg.warn('-> API_key is [[' .. o.API_key .. ']]')

--splits the string into a table on the semicolons
local blacklist = {}
for str in string.gmatch(o.blacklist, "([^|]+)") do
    msg.warn('-> adding [[' .. str .. ']] to blacklist')
    blacklist[str] = true
end

msg.warn('-> warnings = [[' .. tostring(o.warnings) .. ']]')
msg.warn('-> timeout == [[' .. tostring(o.timeout) .. ']]')
