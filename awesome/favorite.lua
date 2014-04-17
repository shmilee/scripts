myfavorite = {
    { "文件管理 (&F)", function () awful.util.spawn("thunar") end },
    { "记事本 (&G)", function () awful.util.spawn("gvim") end },
    { "终端 (&T)", terminal },
    {"监视器 (&M)", function () awful.util.spawn("xterm -e htop") end },
    { "Chrome (&C)", function () awful.util.spawn("chromium") end },
    { "火狐 (&B)", function () awful.util.spawn("firefox") end },    
    -- { "微博", function () awful.util.spawn("weicoair") end },
    { "BT下载", function () awful.util.spawn("deluge") end },
    { "Pidgin (&I)", function () awful.util.spawn("pidgin") end },
    { "Audacious", function () awful.util.spawn("audacious") end },
    { "wps文字", function () awful.util.spawn("wps") end },
    { "辞典", function () awful.util.spawn("goldendict") end },
    { "sage (&S)", function () awful.util.spawn("xterm -e sage") end }
}
