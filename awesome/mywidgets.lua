local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local lain = require("lain")
local cnweather = require("cnweather")
local helpers = require("lain.helpers")
beautiful.init(os.getenv("HOME") .. "/.config/awesome/theme.lua")

-- get device table in path/prefix*
local function get_device(path,prefix)
    local cmd = 'ls -d ' .. path ..'/' .. prefix .. '* 2>/dev/null | sed "s|' .. path .. '/||"'
    local _array = helpers.read_pipe(cmd)
    local _table = {}
    local w
    for w in string.gmatch(_array, "[%w_]+") do
        table.insert(_table,w)
    end
    return _table
end

markup = lain.util.markup
separators = lain.util.separators

-- Separators
spr  = wibox.widget.textbox(' ')
arrl = wibox.widget.imagebox()
arrl:set_image(beautiful.arrl)
arrr = wibox.widget.imagebox()
arrr:set_image(beautiful.arrr)

-- Create a textclock widget
lunar = helpers.read_pipe(os.getenv("HOME") .. '/.config/awesome/lunar')
mytextclock = awful.widget.textclock("%H:%M:%S " .. lunar,1)

-- Calendar
lain.widgets.calendar:attach(mytextclock, {font = 'Ubuntu Mono', followmouse = true})

-- Net
netdownicon = wibox.widget.imagebox(beautiful.netdown)
netdowninfo = wibox.widget.textbox()
netupicon = wibox.widget.imagebox(beautiful.netup)
netupinfo = lain.widgets.net({
    settings = function()
        net_sent = tonumber(net_now.sent) / 1024
        net_rece = tonumber(net_now.received) / 1024
        if net_sent > 1 then
            widget:set_markup(markup("#e54c62", net_sent - net_sent%0.01 .. "M "))
        else
            widget:set_markup(markup("#e54c62", net_now.sent .. "K "))
        end
        if net_rece > 1 then
            netdowninfo:set_markup(markup("#87af5f", net_rece - net_rece%0.01 .. "M "))
        else
            netdowninfo:set_markup(markup("#87af5f", net_now.received .. "K "))
        end
    end
})

-- MEM
memicon   = wibox.widget.imagebox(beautiful.mem)
memwidget = lain.widgets.mem({
    settings = function()
        mem_used = tonumber(mem_now.used) / 1024
        if mem_used > 1 then
            widget:set_markup(markup("#e0da37", mem_used - mem_used%0.01 .. "G "))
        else
            widget:set_markup(mem_now.used .. "M ")
        end
    end
})

-- CPU
cpuicon = wibox.widget.imagebox()
cpuicon:set_image(beautiful.cpu)
cpuwidget = lain.widgets.cpu({
    settings = function()
        cpu_usage = tonumber(cpu_now.usage)
        if cpu_usage > 50 then
            widget:set_markup(markup("#e33a6e", cpu_now.usage .. "% "))
        else
            widget:set_markup(cpu_now.usage .. "% ")
        end
    end
})
-- Coretemp
local temp_device = get_device('/sys/class/thermal','thermal_zone')
temp_device = temp_device[#temp_device]
tempicon    = wibox.widget.imagebox(beautiful.temp)
tempwidget  = lain.widgets.temp({
    tempfile = "/sys/class/thermal/" .. temp_device .. "/temp",
    settings = function()
        core_temp = tonumber(coretemp_now)
        if core_temp >70 then
            widget:set_markup(markup("#D91E1E", coretemp_now .. "°C "))
        elseif core_temp >50 then
            widget:set_markup(markup("#f1af5f", coretemp_now .. "°C "))
        else
            widget:set_markup(" " .. coretemp_now .. "°C ")
        end
    end
})

-- Battery
baticon     = {}
batwidget   = {}
BAT_Widgets = {}
BAT_table   = get_device('/sys/class/power_supply','BAT')
if #BAT_table == 0 then BAT_table = {'BAT0'} end
for i,BAT in ipairs(BAT_table) do
    baticon[i] = wibox.widget.imagebox(beautiful.bat)
    batwidget[i] = lain.widgets.bat({
        battery  = BAT,
        settings = function()
        if bat_now.perc == "N/A" or bat_now.perc == "100" then
            widget:set_markup(" AC ")
            baticon[i]:set_image(beautiful.ac)
            return
        else
            bat_perc = tonumber(bat_now.perc)
            if bat_perc > 50 then
                widget:set_markup(" " .. bat_now.perc .. "% ")
                baticon[i]:set_image(beautiful.bat)
            elseif bat_perc > 15 then
                widget:set_markup(markup("#EB8F8F", bat_now.perc .. "% "))
                baticon[i]:set_image(beautiful.bat_low)
            else
                widget:set_markup(markup("#D91E1E", bat_now.perc .. "% "))
                baticon[i]:set_image(beautiful.bat_no)
            end
        end
    end
    })
    BAT_Widgets[2*i-1] = baticon[i]
    BAT_Widgets[2*i]   = batwidget[i]
end

-- ALSA volume bar
volicon = wibox.widget.imagebox(beautiful.vol)
volume  = lain.widgets.alsabar({
    width = 30, ticks = true, ticks_size = 4,
    followmouse = true,
    settings = function()
        if volume_now.status == "off" then
            volicon:set_image(beautiful.vol_mute)
        elseif volume_now.level == 0 then
            volicon:set_image(beautiful.vol_no)
        elseif volume_now.level <= 50 then
            volicon:set_image(beautiful.vol_low)
        else
            volicon:set_image(beautiful.vol)
        end
    end,
    colors =
    {
        background = beautiful.bg_focus,
        mute       = "#EB8F8F",
        unmute     = beautiful.fg_normal
    }
})
volmargin = wibox.layout.margin(volume.bar, 2, 7)
volmargin:set_top(6)
volmargin:set_bottom(6)
volumewidget = wibox.widget.background(volmargin)
volumewidget:set_bgimage(beautiful.widget_bg)
function volume.mynotify()
    volume.notify()
    if volume._muted then
        os.execute(string.format("volnoti-show -m"))
    else
        os.execute(string.format("volnoti-show %s", volume_now.level))
    end
end

-- Weather
yawn = cnweather({
    --timeout = 600,            -- 10 min
    --timeout_forecast = 18000, -- 5 hrs
    api         = 'etouch',     -- etouch, lib360, xiaomi
    city        = '杭州',       -- for etouch, lib360
    cityid      = 101210101,    -- for xiaomi
    city_desc   = '杭州市',     -- desc for the city
    icons_path  = theme.dir .. '/icons/cnweather/',
    followmouse = true
})
yawn.attach(yawn.icon)
