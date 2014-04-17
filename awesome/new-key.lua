    --休眠
    awful.key({ modkey, "Control" }, "s", function () awful.util.spawn("systemctl suspend") end),
    -- 截屏
    awful.key({ }, "Print", function() awful.util.spawn("deepin-scrot") end)
