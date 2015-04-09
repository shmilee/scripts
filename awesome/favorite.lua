myfavorite = {
    { "文件管理 (&F)", function () awful.util.spawn("thunar") end },
    { "记事本 (&V)", function () awful.util.spawn("gvim") end, "/usr/share/pixmaps/gvim.png" },
    { "终端 (&T)", terminal },
    {"监视器 (&M)", function () awful.util.spawn("xterm -e htop") end },
    { "Chrome (&C)", "chromium" },
    { "火狐 (&B)", function () awful.util.spawn("firefox") end, "/usr/share/icons/hicolor/16x16/apps/firefox.png" },    
    { "BT下载 (&D)", function () awful.util.spawn("transmission-gtk") end },
    { "Pidgin (&I)", function () awful.util.spawn("pidgin") end, "/usr/share/icons/hicolor/16x16/apps/pidgin.png" },
    { "Audacious", function () awful.util.spawn("audacious") end },
    { "wps文字 (&W)", function () awful.util.spawn("wps") end },
    { "辞典 (&G)", function () awful.util.spawn("goldendict") end },
    { "sage (&S)", function () awful.util.spawn("xterm -e sage") end }
}
