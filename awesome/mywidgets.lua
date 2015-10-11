local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local lain = require("lain")
local cnweather = require("cnweather")
local helpers = require("lain.helpers")
beautiful.init(os.getenv("HOME") .. "/.config/awesome/theme.lua")

markup = lain.util.markup
blue   = beautiful.fg_focus
-- Separators
spr = wibox.widget.textbox(' ')
small_spr = wibox.widget.textbox('<span font="FreeSans 4"> </span>')
bar_spr = wibox.widget.textbox('<span font="FreeSans 3"> </span>' .. markup("#333333", "|") .. '<span font="FreeSans 3"> </span>')

-- Create a textclock widget
mytextclock = awful.widget.textclock(" %H:%M")

-- Calendar
lain.widgets.calendar:attach(mytextclock, {font = 'Ubuntu Mono', followmouse = true})

-- ALSA volume bar
volicon = wibox.widget.imagebox(beautiful.vol)
volume = lain.widgets.alsabar({
    width = 54, ticks = true, ticks_size = 6,
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
        background = beautiful.bg_normal,
        mute = "#EB8F8F",
        unmute = beautiful.fg_normal
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

-- Coretemp
local temp_device = get_device('/sys/class/thermal','thermal_zone')
temp_device = temp_device[#temp_device]
tempicon = wibox.widget.imagebox(beautiful.widget_temp)
tempwidget = lain.widgets.temp({
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

-- Weather
yawn = cnweather({
    api  = 'lib360',
    city = '杭州',
    icons_path = theme.dir .. '/icons/cnweather/',
    followmouse = true
})
yawn.attach(yawn.icon)

-- Battery
baticon = {}
batwidget = {}
BAT_table = get_device('/sys/class/power_supply','BAT')
if #BAT_table == 0 then BAT_table = {'BAT0'} end
for i,BAT in ipairs(BAT_table) do
    baticon[i] = wibox.widget.imagebox(beautiful.bat)
    batwidget[i] = lain.widgets.bat({
        battery = BAT,
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
end
