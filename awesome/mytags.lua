local awful = require("awful")
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
}
tags = {
   names = { "宫", "商", "角", "徵", "羽" },
   layout = { layouts[1], layouts[2], layouts[1], layouts[2], layouts[2] }
}
return tags
