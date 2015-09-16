#!/bin/bash
need_pkg=('awesome'
          'lain-git'
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
files=('alsa-bat.lua'
       'arch-icon.png'
       'favorite.lua'
       'init.sh'
       'new-key.lua'
       'separator.lua'
       'tag-name.lua'
       'theme.lua'
       'icons/*.png'
       'revelation'
       'run_once.lua')

## theme.lua : copy from /usr/share/awesome/themes/zenburn/
# theme.dir = os.getenv("HOME") .. "/.config/awesome"
# theme.wallpaper
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
n0=`grep -n 'gears.wallpaper.' rc.lua|cut -d: -f1`
sed -i "${n0} a \        if s == 2 then\n            gears.wallpaper.maximized(beautiful.wallpaper2, s, true)\n        end" rc.lua

## 2. terminal : xterm & editor : nano --> vim &窗口缝隙
sed -i '/^terminal =/s/xterm/xfce4-terminal/' rc.lua
sed -i '/^editor =/s/nano/vim/' rc.lua
sed -i '/keys = clientkeys,/s/,/,size_hints_honor = false,/' rc.lua

## 3. tags 宫商角徵羽
n1=`grep -n '1, 2, 3, 4, 5, 6, 7, 8, 9' rc.lua|cut -d: -f1`
sed -i "${n1} s/1, 2, 3, 4, 5, 6, 7, 8, 9/1, 2, 3, 4, 5/" rc.lua
sed -i "${n1} r tag-name.lua" rc.lua

## 4. mainmenu : add mainmenu favorite(2) xdgmenu(2)
# lxde-applications.menu  arch-applications.menu  xfce-applications.menu  kde-applications.menu
if ! xdg_menu --format awesome --root-menu /etc/xdg/menus/xfce-applications.menu >archmenu.lua; then
    echo "xdg_menu::error."
    exit 1
fi
# 加菜单
sed -i 's|{ "open terminal", terminal }|{ "所有 (\&A)", xdgmenu }, { "常用 (\&C)", myfavorite }|' rc.lua
# favorite2 xdgmenu2
n3=`grep -n '^mymainmenu =' rc.lua|head -n1|cut -d: -f1`
((n3--))
sed -i "${n3} i require(\"archmenu\")\nrequire(\"favorite\")\nmyfavorite2 = awful.menu({ items = myfavorite })\nxdgmenu2 = awful.menu({ items = xdgmenu })" rc.lua
# xdgmenu2 绑定 modkey + a, favorite2 绑定 modkey + c
sed -i 's|"w", function () mymainmenu:show() end),|"a", function () xdgmenu2:show() end),\n    awful.key({ modkey,           }, "c", function () myfavorite2:show() end),|' rc.lua

## 5.快捷键加最后: 截屏 suspend lain-alsabar
n3=`grep -n '\-\- Menubar$' rc.lua|cut -d: -f1`
((n3--))
sed -i "${n3} r new-key.lua" rc.lua

## 6. lain-wibox
# 1) add lain library, 寻找第一个空行
n2=`grep -n '^$' rc.lua|head -n1|cut -d: -f1`
((n2++))
sed -i "${n2} i local lain = require(\"lain\")" rc.lua
# 2) wibox height = 20
sed -i '/awful.wibox({ position/s|screen = s|screen = s, height = 20|' rc.lua
# 3) mytextclock with calendar
sed -i 's|mytextclock = awful.widget.textclock()|mytextclock = awful.widget.textclock(" %H:%M")\n\n-- Calendar\nlain.widgets.calendar:attach(mytextclock, {followmouse = true})|' rc.lua
# 4) weather 
id=1808926
n4=`grep -n '^-- Calendar' rc.lua|cut -d: -f1`
((n4++))
((n4++))
sed -i "${n4} a -- Weather\nyawn = lain.widgets.weather({\n    city_id = $id,\n    lang = \"zh\",\n    followmouse = true\n})\nyawn.attach(yawn.icon)\n" rc.lua
sed -i '/right_layout:add(mytextclock)/i \ \ \ \ right_layout:add(yawn.icon)' rc.lua
# 5) separator
n5=`grep -n '^-- Create a textclock widget' rc.lua|cut -d: -f1`
((n5--))
sed -i "${n5} r separator.lua" rc.lua
# 6) alsa-temp-bat bar
n6=`grep -n '^-- Weather' rc.lua|cut -d: -f1`
((n6--))
if ! BATs=(/sys/class/power_supply/BAT*); then
    echo "No battery found."
    exit 1
fi
if [ ${#BATs[@]} == 1 ];then
    BAT=$(basename ${BATs[0]})
    sed -e '/BAT#2#/d' -e "s/BAT#1#/$BAT/" \
        alsa-temp-bat.lua >./alsa-temp-bat.temp.lua
    BAT_Layout='right_layout:add(baticon)\n    right_layout:add(bat1widget)'
else
    if [ ${#BATs[@]} != 2 ];then
        echo "${#BATs[@]} batteries, take 2 only."
    fi
    BAT1=$(basename ${BATs[0]})
    BAT2=$(basename ${BATs[1]})
    sed -e "s/BAT#1#/$BAT1/" -e "s/BAT#2#/$BAT2/" \
        alsa-temp-bat.lua >./alsa-temp-bat.temp.lua
    BAT_Layout='right_layout:add(baticon)\n    right_layout:add(bat1widget)\n    right_layout:add(baticon)\n    right_layout:add(bat2widget)'
fi
sed -i "${n6} r alsa-temp-bat.temp.lua" rc.lua
rm ./alsa-temp-bat.temp.lua
sed -i "/right_layout:add(yawn.icon)/i \ \ \ \ right_layout:add(bar_spr)\n    $BAT_Layout\n    right_layout:add(bar_spr)\n    right_layout:add(tempicon)\n    right_layout:add(tempwidget)\n    right_layout:add(bar_spr)\n    right_layout:add(volicon)\n    right_layout:add(volumewidget)\n    right_layout:add(bar_spr)" rc.lua

## 7. revelation
n7=`grep -n '^local lain' rc.lua|cut -d: -f1`
((n7++))
sed -i "${n7} i local revelation=require(\"revelation\")" rc.lua
n7=`grep -n '^beautiful.init' rc.lua|cut -d: -f1`
((n7++))
sed -i "${n7} i revelation.init()" rc.lua
n7=`grep -n 'awful.key({ modkey,           }, "Escape",' rc.lua|cut -d: -f1`
((n7++))
sed -i "${n7} i \ \ \ \ awful.key({ modkey,           }, \"e\",      revelation)," rc.lua

## 8. window transparency
w_T=N
if [[ $w_T == Y ]]; then
    sed -i -e 's|c.border_color = beautiful.border_focus|& c.opacity = 1|' \
        -e 's|c.border_color = beautiful.border_normal|& c.opacity = 0.8|' rc.lua
fi

## 9. autostart programs
cat ./run_once.lua >> rc.lua
