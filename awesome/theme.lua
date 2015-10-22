-------------------------------
--  "Zenburn" awesome theme  --
--    By Adrian C. (anrxc)   --
-------------------------------

-- Alternative icon sets and widget icons:
--  * http://awesome.naquadah.org/wiki/Nice_Icons

-- {{{ Main
theme = {}
theme.dir       = os.getenv("HOME") .. "/.config/awesome"
theme.wallpaper = "/usr/share/wallpapers-shmilee/1200/think-1920x1200.jpg"
theme.wallpaper2 = "/usr/share/wallpapers-shmilee/1080/violin-1920x1080.jpg"
-- }}}

-- {{{ Styles
theme.font      = "Microsoft YaHei 9"

-- {{{ Colors
theme.fg_normal  = "#DCDCCC"
theme.fg_focus   = "#F0DFAF"
theme.fg_urgent  = "#CC9393"
theme.bg_normal  = "#3F3F3F"
theme.bg_focus   = "#1E2320"
theme.bg_urgent  = "#3F3F3F"
theme.bg_systray = theme.bg_normal
-- }}}

-- {{{ Borders
theme.border_width  = 1
theme.border_normal = "#3F3F3F"
theme.border_focus  = "#6F6F6F"
theme.border_marked = "#CC9393"
-- }}}

-- {{{ Titlebars
theme.titlebar_bg_focus  = "#3F3F3F"
theme.titlebar_bg_normal = "#3F3F3F"
-- }}}

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- [taglist|tasklist]_[bg|fg]_[focus|urgent]
-- titlebar_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- Example:
--theme.taglist_bg_focus = "#CC9393"
-- }}}

-- {{{ Widgets
-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.fg_widget        = "#AECF96"
--theme.fg_center_widget = "#88A175"
--theme.fg_end_widget    = "#FF5656"
--theme.bg_widget        = "#494B4F"
--theme.border_widget    = "#3F3F3F"
theme.widget_bg   = theme.dir .. "/icons/widget_bg.png"
theme.vol         = theme.dir .. "/icons/vol.png"
theme.vol_low     = theme.dir .. "/icons/vol_low.png"
theme.vol_no      = theme.dir .. "/icons/vol_no.png"
theme.vol_mute    = theme.dir .. "/icons/vol_mute.png"
theme.ac          = theme.dir .. "/icons/ac.png"
theme.bat         = theme.dir .. "/icons/bat.png"
theme.bat_low     = theme.dir .. "/icons/bat_low.png"
theme.bat_no      = theme.dir .. "/icons/bat_no.png"
theme.play        = theme.dir .. "/icons/play.png"
theme.pause       = theme.dir .. "/icons/pause.png"
theme.temp        = theme.dir .. "/icons/temp.png"
theme.cpu         = theme.dir .. "/icons/cpu.png"
theme.mem         = theme.dir .. "/icons/mem.png"
theme.netdown     = theme.dir .. "/icons/net_down.png"
theme.netup       = theme.dir .. "/icons/net_up.png"
theme.arrl        = theme.dir .. "/icons/arrl.png"
theme.arrr        = theme.dir .. "/icons/arrr.png"
-- }}}

-- {{{ Mouse finder
theme.mouse_finder_color = "#CC9393"
-- mouse_finder_[timeout|animate_timeout|radius|factor]
-- }}}

-- {{{ Menu
-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_height = 20
theme.menu_width  = 100
-- }}}

-- {{{ Icons
-- {{{ Taglist
theme.taglist_squares_sel   = "/usr/share/awesome/themes/zenburn/taglist/squarefz.png"
theme.taglist_squares_unsel = "/usr/share/awesome/themes/zenburn/taglist/squarez.png"
--theme.taglist_squares_resize = "false"
-- }}}

-- {{{ Misc
-- theme.awesome_icon           = "/usr/share/awesome/themes/zenburn/awesome-icon.png"
theme.awesome_icon           = theme.dir .. "/icons/arch-icon.png"
theme.menu_submenu_icon      = "/usr/share/awesome/themes/default/submenu.png"
-- }}}

-- {{{ Layout
theme.layout_tile       = theme.dir .. "/icons/tile.png"
theme.layout_tileleft   = theme.dir .. "/icons/tileleft.png"
theme.layout_tilebottom = theme.dir .. "/icons/tilebottom.png"
theme.layout_tiletop    = theme.dir .. "/icons/tiletop.png"
theme.layout_fairv      = theme.dir .. "/icons/fairv.png"
theme.layout_fairh      = theme.dir .. "/icons/fairh.png"
theme.layout_spiral     = theme.dir .. "/icons/spiral.png"
theme.layout_dwindle    = theme.dir .. "/icons/dwindle.png"
theme.layout_max        = theme.dir .. "/icons/max.png"
theme.layout_fullscreen = theme.dir .. "/icons/fullscreen.png"
theme.layout_magnifier  = theme.dir .. "/icons/magnifier.png"
theme.layout_floating   = theme.dir .. "/icons/floating.png"
-- }}}

-- {{{ Titlebar
theme.titlebar_close_button_focus  = "/usr/share/awesome/themes/zenburn/titlebar/close_focus.png"
theme.titlebar_close_button_normal = "/usr/share/awesome/themes/zenburn/titlebar/close_normal.png"

theme.titlebar_ontop_button_focus_active  = "/usr/share/awesome/themes/zenburn/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active = "/usr/share/awesome/themes/zenburn/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive  = "/usr/share/awesome/themes/zenburn/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive = "/usr/share/awesome/themes/zenburn/titlebar/ontop_normal_inactive.png"

theme.titlebar_sticky_button_focus_active  = "/usr/share/awesome/themes/zenburn/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active = "/usr/share/awesome/themes/zenburn/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive  = "/usr/share/awesome/themes/zenburn/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive = "/usr/share/awesome/themes/zenburn/titlebar/sticky_normal_inactive.png"

theme.titlebar_floating_button_focus_active  = "/usr/share/awesome/themes/zenburn/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active = "/usr/share/awesome/themes/zenburn/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive  = "/usr/share/awesome/themes/zenburn/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive = "/usr/share/awesome/themes/zenburn/titlebar/floating_normal_inactive.png"

theme.titlebar_maximized_button_focus_active  = "/usr/share/awesome/themes/zenburn/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active = "/usr/share/awesome/themes/zenburn/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive  = "/usr/share/awesome/themes/zenburn/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = "/usr/share/awesome/themes/zenburn/titlebar/maximized_normal_inactive.png"
-- }}}
-- }}}

return theme
