
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

-- lain.widgets.contrib.zhweather
-- current weather and forecast
--
-- http://openweather.weather.com.cn/Home/Help/icon.html
local icon_table={
    ["晴"]               = '00',
    ["多云"]             = '01',
    ["阴"]               = '02',
    ["阵雨"]             = '03',
    ["雷阵雨"]           = '04',
    ["雷阵雨伴有冰雹"]   = '05',
    ["雨夹雪"]           = '06',
    ["小雨"]             = '07',
    ["中雨"]             = '08',
    ["大雨"]             = '09',
    ["暴雨"]             = '10',
    ["大暴雨"]           = '11',
    ["特大暴雨"]         = '12',
    ["阵雪"]             = '13',
    ["小雪"]             = '14',
    ["中雪"]             = '15',
    ["大雪"]             = '16',
    ["暴雪"]             = '17',
    ["雾"]               = '18',
    ["冻雨"]             = '19',
    ["沙尘暴"]           = '20',
    ["小到中雨"]         = '21',
    ["中到大雨"]         = '22',
    ["大到暴雨"]         = '23',
    ["暴雨到大暴雨"]     = '24',
    ["大暴雨到特大暴雨"] = '25',
    ["小到中雪"]         = '26',
    ["中到大雪"]         = '27',
    ["大到暴雪"]         = '28',
    ["浮尘"]             = '29',
    ["扬沙"]             = '30',
    ["强沙尘暴"]         = '31',
    ["霾"]               = '53',
    ["无"]               = 'undefined' }

-- http://www.pm25.com/news/91.html
-- AQI PM2.5 --> Air Pollution Level
local function aqi2apl(aqi)
    local aql={'优', '良',   '轻度污染', '中度污染', '重度污染','重度污染', '严重污染','严重污染','严重污染','严重污染'}
    ----  aqi  0-50, 51-100, 101 - 150,  151 - 200,  201 - - 250 - - - 300, 301 - - 350 - - - - 400 - - - - 450 - - 500
    local i=math.floor(aqi/50.16)+1
    return "空气质量指数: " .. tostring(aqi) .. ', ' .. aql[i]
end

-- wthrcdn.etouch.cn --
--{{{
local function etouch_forecast(city)
    local cmd = string.format("curl -s 'http://wthrcdn.etouch.cn/weather_mini?city=%s'|gzip -d", city)
    local notification_text = ''
    local weather_now, pos, err
    weather_now, pos, err = json.decode(read_pipe(cmd), 1, nil)

    if not err and weather_now ~= nil and weather_now["desc"] == 'OK' then
        for i = 1, #weather_now.data.forecast do
            local day  = weather_now.data.forecast[i].date
            local tmin = string.gsub(weather_now.data.forecast[i].low, '低温', '')
            local tmax = string.gsub(weather_now.data.forecast[i].high, '高温', '')
            local desc = weather_now.data.forecast[i].type
            local wind =  weather_now.data.forecast[i].fengli
            notification_text = notification_text ..
                string.format("<b>%s</b>:  %s,  %s - %s,  %s ", day, desc, tmin, tmax, wind)
            if i < #weather_now.data.forecast then
                notification_text = notification_text .. "\n"
            end
        end
    end
    return notification_text
end

local function etouch_now(city)
    local cmd = string.format("curl -s 'http://wthrcdn.etouch.cn/weather_mini?city=%s'|gzip -d", city)
    local weather_now_icon = ''
    local aql = ''
    local weather_now, pos, err
    weather_now, pos, err = json.decode(read_pipe(cmd), 1, nil)

    if not err and weather_now ~= nil and weather_now["desc"] == 'OK' then
        weather_now_icon = icon_table[weather_now.data.forecast[1].type] .. ".png"
        aql = aqi2apl(weather_now.data.aqi)
    end
    return weather_now_icon, aql
end
--}}}

-- api.lib360.net --
--{{{
local function lib360_forecast(city)
    local cmd = string.format("curl -s 'http://api.lib360.net/open/weather.json?city=%s'", city)
    local notification_text = ''
    local weather_now, pos, err
    weather_now, pos, err = json.decode(read_pipe(cmd), 1, nil)

    if not err and weather_now ~= nil and weather_now.data ~= nil then
        for i = 1, #weather_now.data do
            local day  = weather_now.data[i].Month .. '月 ' .. weather_now.data[i].Day .. '日'
            local tmin = weather_now.data[i].TempMin
            local tmax = weather_now.data[i].TempMax
            local desc = weather_now.data[i].Weather
            local wind = weather_now.data[i].Wind
            notification_text = notification_text ..
                string.format("<b>%s</b>:  %s,  %d - %d ℃,  %s ", day, desc, tmin, tmax, wind)
            if i < #weather_now.data then
                notification_text = notification_text .. "\n"
            end
        end
    end
    return notification_text
end

local function lib360_now(city)
    local cmd = string.format("curl -s 'http://api.lib360.net/open/weather.json?city=%s'", city)
    local weather_now_icon=''
    local aql = ''
    local weather_now, pos, err
    weather_now, pos, err = json.decode(read_pipe(cmd), 1, nil)

    if not err and weather_now ~= nil and weather_now.datanow ~= nil then
        weather_now_icon = icon_table[weather_now.datanow.Weather] .. ".png"
        --weather_now_icon = string.sub(weather_now.datanow.WeatherICON,2,3) .. ".png"
        aql = aqi2apl(weather_now.pm25)
    end
    return weather_now_icon, aql
end
--}}}

local function worker(args)
    local cnweather              = {}
    local args                 = args or {}
    local timeout              = args.timeout or 1800   -- 30 min
    local timeout_forecast     = args.timeout or 86400  -- 24 hrs
    local api                  = args.api or 'etouch'   -- etouch or lib360
    local city                 = args.city or '杭州'    -- placeholder
    local icons_path           = args.icons_path or lain_icons .. "cnweather/"
    local notification_preset  = args.notification_preset or {}
    local followmouse          = args.followmouse or false
    local settings             = args.settings or function() end

    cnweather.widget = wibox.widget.textbox('')
    cnweather.icon   = wibox.widget.imagebox()

    function cnweather.show(t_out)
        cnweather.hide()

        if followmouse then
            notification_preset.screen = mouse.screen
        end

        cnweather.notification = naughty.notify({
            text    = cnweather.aql .. '\n' .. cnweather.notification_text,
            icon    = cnweather.icon_path,
            timeout = t_out,
            preset  = notification_preset
        })
    end

    function cnweather.hide()
        if cnweather.notification ~= nil then
            naughty.destroy(cnweather.notification)
            cnweather.notification = nil
        end
    end

    function cnweather.attach(obj)
        obj:connect_signal("mouse::enter", function()
            cnweather.show(0)
        end)
        obj:connect_signal("mouse::leave", function()
            cnweather.hide()
        end)
    end

    -- encodeURI
    url_city = string.gsub(city, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)

    function cnweather.forecast_update()
        if api == 'etouch' then
            cnweather.notification_text = etouch_forecast(url_city)
        elseif api == 'lib360' then
            cnweather.notification_text = lib360_forecast(url_city)
        else
            cnweather.notification_text = ''
        end

        if cnweather.notification_text == '' then
            cnweather.icon_path = icons_path .. "day/undefined.png"
            cnweather.notification_text = "API/connection error or bad/not set city ID"
        end
    end

    function cnweather.update()
        local dorn, icon, aql
        if tonumber(os.date('%H')) <= 18 and tonumber(os.date('%H')) >= 6 then
            dorn = 'day/'
        else
            dorn = 'night/'
        end
        if api == 'etouch' then
            icon, aql = etouch_now(url_city)
        elseif api == 'lib360' then
            icon, aql = lib360_now(url_city)
        else
            icon, aql = '', ''
        end

        if icon == '' then
            cnweather.icon_path = icons_path .. "day/undefined.png"
            cnweather.icon:set_image(cnweather.icon_path)
            cnweather.widget._layout.text = " N/A " -- tries to avoid textbox bugs
            cnweather.aql = "AQI: N/A "
        else
            cnweather.icon_path = icons_path .. dorn .. icon
            cnweather.icon:set_image(cnweather.icon_path)
            cnweather.aql = aql
            widget = cnweather.widget
            settings()
        end
    end

    cnweather.attach(cnweather.widget)
    newtimer("cnweather-" .. city, timeout, cnweather.update)
    newtimer("cnweather_forecast-" .. city, timeout, cnweather.forecast_update)
    return setmetatable(cnweather, { __index = cnweather.widget })
end

return setmetatable({}, { __call = function(_, ...) return worker(...) end })