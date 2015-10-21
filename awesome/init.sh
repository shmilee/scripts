#!/bin/bash
need_pkg=('awesome'
          'lain-git'
          'garcon'
          'ttf-ubuntu-font-family'
          'volnoti'
          'arandr'
          'slock'
          'deepin-scrot'
          'conky'
          'compton'
          'fcitx'
          'parcellite'
          'fcitx-sogoupinyin'
          'wicd-gtk')
files=('icons/*.png'
       'revelation'
       'favorite.lua'
       'init.sh'
       'mykeys.lua'
       'mytags.lua'
       'mywidgets.lua'
       'run_once.lua'
       'theme.lua')

## theme.lua : copy from /usr/share/awesome/themes/zenburn/
# theme.dir = os.getenv("HOME") .. "/.config/awesome"
# theme.wallpaper
# theme.wallpaper2
# theme.font
# Widgets
# theme.awesome_icon = theme.dir .. "/arch-icon.png"

## BEGIN ##
workdir=`pwd`
if [ "${workdir}" != "${HOME}/.config/awesome" ];then
    echo "ERROR: not awesome config dir."
    exit 1
fi

## rc.lua ##
# copy from /etc/xdg/awesome/rc.lua
[ -f rc.lua ] && mv rc.lua rc.lua.bak
cp /etc/xdg/awesome/rc.lua rc.lua

## 1. add theme
sed -i 's|"/usr/share/awesome/themes/default/theme.lua"|os.getenv("HOME") .. "/.config/awesome/theme.lua"|' rc.lua

## 2. terminal : xterm & editor : nano --> vim &窗口缝隙
sed -i '/^terminal =/s/xterm/xfce4-terminal/' rc.lua
# xfce4-terminal -e 'cmd arg'
sed -i "/^editor_cmd =/ s/-e /-e '/" rc.lua
sed -i "s/man awesome/'man awesome'/" rc.lua
sed -i "s/awesome.conffile/awesome.conffile .. \"'\"/" rc.lua
sed -i '/^editor =/s/nano/vim/' rc.lua
sed -i '/keys = clientkeys,/s/,/,size_hints_honor = false,/' rc.lua

## 3. wallpaper
sed -i '/gears.wallpaper.maximized/a \
        if s == 2 then\
            gears.wallpaper.maximized(beautiful.wallpaper2, s, true)\
        end' rc.lua

## 4. tags
sed -i '/^tags.*=.*{}$/ s/{}/require("mytags")/' rc.lua
sed -i '/1, 2, 3, 4, 5, 6, 7, 8, 9/ s/awful.tag(.*$/awful.tag(tags.names, s, tags.layout)/' rc.lua

## 5. mainmenu : add mainmenu favorite(2) xdgmenu(2)
# lxde-applications.menu  arch-applications.menu  xfce-applications.menu  kde-applications.menu
if ! xdg_menu --format awesome --root-menu /etc/xdg/menus/xfce-applications.menu >archmenu.lua; then
    echo "xdg_menu::error."
    exit 1
fi
# 加菜单
sed -i 's|{ "open terminal", terminal }|{ "所有 (\&A)", xdgmenu }, { "常用 (\&C)", myfavorite }|' rc.lua
# favorite2 xdgmenu2
sed -i '/^mymainmenu =/i \
require(\"archmenu\")\
require(\"favorite\")\
myfavorite2 = awful.menu({ items = myfavorite })\
xdgmenu2 = awful.menu({ items = xdgmenu })\n' rc.lua
# xdgmenu2 绑定 modkey + a, favorite2 绑定 modkey + c
sed -i 's|"w", function () mymainmenu:show() end),|"a", function () xdgmenu2:show() end),\n    awful.key({ modkey,           }, "c", function () myfavorite2:show() end),|' rc.lua

## 6. mykeys & revelation
sed -i '/menubar.*=.*menubar/a local revelation=require("revelation")' rc.lua
sed -i '/beautiful.init/a revelation.init()' rc.lua
sed -i '/--.*Key bindings$/ i mykeys = require("mykeys")' rc.lua
sed -i '/-- Menubar$/ i \
    awful.key({ modkey,           }, "e", revelation),\
    -- keycode 152 = XF86Explorer\
    awful.key({ }, "XF86Explorer", revelation),\
    mykeys,' rc.lua

## 7. lain-wibox
# 1) wibox height = 20
sed -i '/awful.wibox({ position/s|screen = s|screen = s, height = 20|' rc.lua
# 2) mywidgets
sed -i 's/^.*Create.*textclock.*widget.*$/require("mywidgets")/' rc.lua
sed -i '/mytextclock.*=.*widget/d' rc.lua
sed -i '/left_layout:add(mypromptbox\[s\])/i \
    left_layout:add(spr)' rc.lua
sed -i '/left_layout:add(mypromptbox\[s\])/a \
    left_layout:add(spr)\
    left_layout:add(netdownicon)\
    left_layout:add(netdowninfo)\
    left_layout:add(netupicon)\
    left_layout:add(netupinfo)' rc.lua
sed -i '/right_layout:add(mytextclock)/i \
\
    local right_layout_toggle = true\
    local function right_layout_add (arg)\
        if right_layout_toggle then\
            right_layout:add(arrl_ld)\
            for i, n in pairs(arg) do\
                right_layout:add(wibox.widget.background(n ,beautiful.bg_focus))\
            end\
        else\
            right_layout:add(arrl_dl)\
            for i, n in pairs(arg) do\
                right_layout:add(n)\
            end\
        end\
        right_layout_toggle = not right_layout_toggle\
    end\
\
    right_layout:add(spr)\
    right_layout:add(arrl)\
    --right_layout_add({netdownicon,netdowninfo, netupicon,netupinfo})\
    right_layout_add({memicon,memwidget})\
    right_layout_add({cpuicon,cpuwidget, tempicon,tempwidget})\
    right_layout_add(BAT_Widgets)\
    right_layout_add({volicon,volumewidget})\
    right_layout_add({spr,yawn.icon,mytextclock})\
    right_layout_add({mylayoutbox[s]})' rc.lua
sed -i '/right_layout:add(mytextclock)/d' rc.lua
sed -i '/right_layout:add(mylayoutbox\[s\])/d' rc.lua

## 8. window transparency
w_T=N
if [[ $w_T == Y ]]; then
    sed -i -e 's|c.border_color = beautiful.border_focus|& c.opacity = 1|' \
        -e 's|c.border_color = beautiful.border_normal|& c.opacity = 0.8|' rc.lua
fi

## 9. autostart programs
echo 'require("run_once")' >>rc.lua
