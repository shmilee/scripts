-- ALSA volume bar
volicon = wibox.widget.imagebox(beautiful.vol)
volume = lain.widgets.alsabar({width = 55, ticks = true, ticks_size = 6,
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
}})
volmargin = wibox.layout.margin(volume.bar, 2, 7)
volmargin:set_top(6)
volmargin:set_bottom(6)
volumewidget = wibox.widget.background(volmargin)
volumewidget:set_bgimage(beautiful.widget_bg)

-- Coretemp
tempicon = wibox.widget.imagebox(beautiful.widget_temp)
tempwidget = lain.widgets.temp({
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
baticon = wibox.widget.imagebox(beautiful.bat)
batwidget = lain.widgets.bat({battery = "BAT1",
    settings = function()
        if bat_now.perc == "N/A" or bat_now.perc == "100" then
            widget:set_markup(" AC ")
            baticon:set_image(beautiful.ac)
            return
        else
            bat_perc = tonumber(bat_now.perc)
            if bat_perc > 50 then
                widget:set_markup(" " .. bat_now.perc .. "% ")
                baticon:set_image(beautiful.bat)
            elseif bat_perc > 15 then
                widget:set_markup(markup("#EB8F8F", bat_now.perc .. "% "))
                baticon:set_image(beautiful.bat_low)
            else
                widget:set_markup(markup("#D91E1E", bat_now.perc .. "% "))
                baticon:set_image(beautiful.bat_no)
            end
        end
    end
})

