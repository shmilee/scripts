
--[[
                                                  
     Licensed under GNU General Public License v2 
      * (c) 2015, shmilee                         
                                                  
--]]

local newtimer     = require("lain.helpers").newtimer
local read_pipe    = require("lain.helpers").read_pipe
local lain_icons   = require("lain.helpers").icons_dir
local json         = require("lain.util").dkjson

local naughty      = require("naughty")
local wibox        = require("wibox")

local mouse        = mouse
local string       = { format = string.format,
                       gsub   = string.gsub,
                       byte   = string.byte }
local math         = { floor  = math.floor }

local setmetatable = setmetatable

-- lain.widgets.contrib.yhweather
-- https://developer.yahoo.com/weather --
-- https://query.yahooapis.com/v1/public/yql?format=json&q=
-- select * from weather.forecast where woeid in (select woeid from geo.places(1) where text="中国, 杭州") and u="c"

local curl      = 'curl -f -s -m 2'
local unit_char = { ['c'] = '℃', ['f'] = '℉' }

local function get_cmd(country, city, item, unit)
    local YQL_Q = string.format('select %s from weather.forecast where woeid in (select woeid from geo.places(1) where text="%s, %s") and u="%s"', item, country, city, unit)
    -- encodeURI
    local yql_q = string.gsub(YQL_Q, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    local yql_q = string.gsub(yql_q, " ", "+")
    local cmd   = string.format("%s 'https://query.yahooapis.com/v1/public/yql?format=json&q=%s'", curl, yql_q)
    return cmd
end

local function yahoo_forecast(country, city, unit)
    local notification_text = ''
    local weather_now, pos, err
    weather_now, pos, err = json.decode(read_pipe(get_cmd(country, city, 'item.forecast', unit)), 1, nil)

    if not err and weather_now ~= nil and weather_now.query.results.channel ~= nil then
        for i = 1, #weather_now.query.results.channel do
            local day  = weather_now.query.results.channel[i].item.forecast.date .. ' ' ..
                         weather_now.query.results.channel[i].item.forecast.day
            local tmin = weather_now.query.results.channel[i].item.forecast.low
            local tmax = weather_now.query.results.channel[i].item.forecast.high
            local desc = weather_now.query.results.channel[i].item.forecast.text
            notification_text = notification_text ..
                string.format("<b>%s</b>:  %s,  %d - %d %s ", day, desc, tmin, tmax, unit_char[unit])
            if i < #weather_now.query.results.channel then
                notification_text = notification_text .. "\n"
            end
        end
    end
    return notification_text
end

local function yahoo_now(country, city, unit)
    local weather_now_icon=''
    local aql = ' N/A '
    local weather_now, pos, err
    weather_now, pos, err = json.decode(read_pipe(get_cmd(country, city, 'item.condition', unit)), 1, nil)

    if not err and weather_now.query.results.channel.item.condition ~= nil then
        weather_now_icon = weather_now.query.results.channel.item.condition.code .. ".png"
        aql = weather_now.query.results.channel.item.condition.text .. '\n' ..
            'Temprature: ' .. tostring(weather_now.query.results.channel.item.condition.temp) .. unit_char[unit]
    end
    return weather_now_icon, aql
end

local function worker(args)
    local yhweather            = {}
    local args                 = args or {}
    local timeout              = args.timeout or 600            -- 10 min
    local timeout_forecast     = args.timeout_forecast or 18000 -- 5 hrs
    local country              = args.country or 'China'
    local city                 = args.city or 'HangZhou'
    local unit                 = args.unit or 'c'               -- c or f
    local icons_path           = args.icons_path or lain_icons .. "plain_yhweather/"
    local theme                = args.theme or "yhlight"        -- yhcolorful yhlight
    local notification_preset  = args.notification_preset or {}
    local followmouse          = args.followmouse or false
    local settings             = args.settings or function() end

    yhweather.widget = wibox.widget.textbox('')
    yhweather.icon   = wibox.widget.imagebox()

    function yhweather.show(t_out)
        yhweather.hide()

        if followmouse then
            notification_preset.screen = mouse.screen
        end

        yhweather.notification = naughty.notify({
            text    = country .. ', ' .. city .. ': ' .. yhweather.aql .. '\n' .. yhweather.notification_text,
            icon    = yhweather.icon_path,
            timeout = t_out,
            preset  = notification_preset
        })
    end

    function yhweather.hide()
        if yhweather.notification ~= nil then
            naughty.destroy(yhweather.notification)
            yhweather.notification = nil
        end
    end

    function yhweather.attach(obj)
        obj:connect_signal("mouse::enter", function()
            yhweather.show(0)
        end)
        obj:connect_signal("mouse::leave", function()
            yhweather.hide()
        end)
    end

    function yhweather.forecast_update()
        yhweather.notification_text = yahoo_forecast(country, city, unit)
        if yhweather.notification_text == '' then
            yhweather.icon_path = icons_path .. theme .. "/na.png"
            yhweather.notification_text = "API/connection error or bad/not set city ID"
        end
    end

    function yhweather.update()
        icon, yhweather.aql = yahoo_now(country, city, unit)
        if icon == '' then
            yhweather.icon_path = icons_path .. theme .. "/na.png"
            yhweather.icon:set_image(yhweather.icon_path)
            yhweather.widget._layout.text = " N/A " -- tries to avoid textbox bugs
        else
            yhweather.icon_path = icons_path .. theme .. '/' .. icon
            yhweather.icon:set_image(yhweather.icon_path)
            widget = yhweather.widget
            settings()
        end
    end

    yhweather.attach(yhweather.widget)
    newtimer("yhweather-" .. city, timeout, yhweather.update)
    newtimer("yhweather_forecast-" .. city, timeout_forecast, yhweather.forecast_update)
    return setmetatable(yhweather, { __index = yhweather.widget })
end

return setmetatable({}, { __call = function(_, ...) return worker(...) end })
