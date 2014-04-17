#!/bin/bash
need_pkg=('awesome'
          'lain-git')
my_files=('arch-icon.png'
       'favorite.lua'
       'init.sh'
       'tag-name.lua'
       'new-key.lua'
       'theme.lua')

## theme.lua : copy from /usr/share/awesome/themes/zenburn/
# theme.wallpaper
# theme.font
# theme.awesome_icon = os.getenv("HOME") .. "/.config/awesome/arch-icon.png"

## archmenu.lua xdgmenu.lua
get_menu_file() {
    # lxde-applications.menu  arch-applications.menu  xfce-applications.menu  kde-applications.menu
    if xdg_menu --format awesome --root-menu /etc/xdg/menus/xfce-applications.menu |sed -e 's/local menu/menu/' > /tmp/xdg-awesome-menu ; then
        local end_row=`grep xdgmenu -n /tmp/xdg-awesome-menu |cut -d: -f1`
        ((end_row--))
        # output menuxxxxxxxxxx and xdgmenu
        cat /tmp/xdg-awesome-menu > archmenu.lua
        # output xdgmenu2(包含常用) which will be added to rc.lua
        sed -e "1,${end_row}d" -e 's/xdgmenu =/xdgmenu2 = awful.menu({ items =/' -e 's|}$|    {"常用 (\&C)", myfavorite}\n}\n})|' /tmp/xdg-awesome-menu > xdgmenu2.lua
    else
        echo "xdg_menu::error."
        return 1
    fi
}

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
sed -i "s|/usr/share/awesome/themes/default/theme.lua|${HOME}/.config/awesome/theme.lua|" rc.lua

## 2. terminal : xterm & editor : nano --> vim
sed -i '/^terminal =/s/xterm/xfce4-terminal/' rc.lua
sed -i '/^editor =/s/nano/vim/' rc.lua

## 3. tags 宫商角徵羽
n1=`grep -n '1, 2, 3, 4, 5, 6, 7, 8, 9' rc.lua|cut -d: -f1`
sed -i "${n1} s/1, 2, 3, 4, 5, 6, 7, 8, 9/1, 2, 3, 4, 5/" rc.lua
((n1++))
sed -i "${n1} r tag-name.lua" rc.lua

## 4. mainmenu : add favorite xdgmenu(2)
get_menu_file
#寻找第一个空行,add library
n2=`grep -n '^$' rc.lua|head -n1|cut -d: -f1`
sed -i "${n2} i require(\"archmenu\")" rc.lua
((n2++)) #for lain
# 加菜单
sed -i 's|{ "open terminal", terminal }|{ "所有应用", xdgmenu },\n                                   { "常用 (\&C)", myfavorite }|' rc.lua
n3=`grep -n '^mymainmenu =' rc.lua|head -n1|cut -d: -f1`
((n3--))
sed -i "${n3} r favorite.lua" rc.lua
n3=`grep -n '^mymainmenu =' rc.lua|head -n1|cut -d: -f1`
((n3--))
sed -i "${n3} r xdgmenu2.lua" rc.lua
rm xdgmenu2.lua
# xdgmenu2 绑定 modkey + p ; 去除menubar
sed -i '/"w", function () mymainmenu:show() end/s/mymainmenu/xdgmenu2/' rc.lua
sed -i '/"w", function () xdgmenu2:show() end/s/"w"/"p"/' rc.lua
n3=`grep -n '\-\- Menubar$' rc.lua|cut -d: -f1`
((n3++)); sed -i "${n3} s|^ | \-\-|" rc.lua

## 7.快捷键加最后: 截屏 suspend
sed -i "${n3} r new-key.lua" rc.lua

## 8. wibox
# 1) add lain library
sed -i "${n2} i local lain = require(\"lain\")" rc.lua
# 2) wibox height = 20
sed -i '/awful.wibox({ position/s|screen = s|screen = s, height = 20|' rc.lua
# 3) mytextclock with calendar
sed -i 's|mytextclock = awful.widget.textclock()|mytextclock = awful.widget.textclock(" %H:%M")\n\n-- Calendar\nlain.widgets.calendar:attach(mytextclock)|' rc.lua
# 4) weather 
id=2132574
n4=`grep -n '^-- Calendar' rc.lua|cut -d: -f1`
((n4++))
((n4++))
sed -i "${n4} a -- Weather\nyawn = lain.widgets.yawn($id,\n{\n    settings = function()\n        yawn_notification_preset.fg = white\n    end\n})\n" rc.lua
sed -i '/right_layout:add(mytextclock)/i \ \ \ \ right_layout:add(yawn.icon)\n\ \ \ \ right_layout:add(yawn.widget)' rc.lua
sed -i '/-- Prompt/i \ \ \ \ awful.key({ modkey, "Shift"      }, "w",      function () yawn.show(7) end),\n' rc.lua
