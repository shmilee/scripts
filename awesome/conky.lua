conky.config = {
    -- Use double buffering (eliminates flickering)
    double_buffer = true,
    -- Run conky in the background
    background = true,
    -- Update interval in seconds
    update_interval = 1.0,
    -- Set to zero to run forever
    total_run_times = 0,
    -- Subtract file system buffers from used memory
    no_buffers = true,
    -- For intermediary text, such as individual lines
    text_buffer_size = 2048,
    -- Imlib2 image cache size, for $image
    imlib_cache_size = 0,
    temperature_unit = 'celsius',
    -- Number of samples to take for CPU and network readings
    cpu_avg_samples = 2,
    net_avg_samples = 2,

    -- Force UTF8? requires XFT
    override_utf8_locale = true,
    -- Use Xft (anti-aliased font and stuff)
    use_xft = true,
    font = 'WenQuanYi Micro Hei:size=9',
    --font = '微软雅黑:size=9',
    xftalpha = 0.5,
    uppercase = false,

    -- Default color and border settings
    default_color = 'white',
    draw_shades = false,
    draw_outline = false,
    draw_borders = false,
    draw_graph_borders = false,

    -- Window specifications
    alignment = 'top_right',
    gap_x = 16,
    gap_y = 50,
    maximum_width = 400,
    -- Makes conky window transparent
    own_window = true,
    own_window_class = 'conky-semi',
    own_window_argb_visual = true,
    own_window_argb_value = 10,
    own_window_transparent = false,
    -- override #desktop #normel #panel #dock #
    own_window_type = 'override',
    own_window_hints = 'undecorated,below,skip_taskbar,sticky,skip_pager'
}

conky.text = [[
${font openlogos:size=20}${color #0090FF}B${color}${font} ${font Blod:size=20}$alignc$uptime${font}${alignr}
]]

disk_devices = {'sda', 'sdb', 'sdc'}
disk_text = [[${if_existing /dev/%s}
${color green}@Disk: %s ${hr 1}${color}
${color blue}${diskiograph_write %s 15,90} ${alignr}${diskiograph_read %s 15,90}${color}
${font Arrows}i${font}${diskio_write %s} ${alignr}${diskio_read %s}${font Arrows}a${font}
${endif}]]
for i,n in pairs(disk_devices) do
    conky.text = conky.text .. string.format(disk_text, n,n,n,n,n,n)
end

net_devices = {'eth0', 'wlan0', 'docker0', 'ap0'}
net_text = [[${if_existing /sys/class/net/%s/operstate up}
${color green}@%s: ${addr %s} ${hr 1}${color}
${color green}${downspeedgraph %s 15,90} ${alignr}${upspeedgraph %s 15,90}${color}
${font Arrows}i${font}${downspeed %s}/s ${alignr}${upspeed %s}/s${font Arrows}a${font}
Total ${totaldown %s} ${alignr}Total ${totalup %s}
${endif}]]
for i,n in pairs(net_devices) do
    conky.text = conky.text .. string.format(net_text, n,n,n,n,n,n,n,n,n)
end

conky.text = conky.text .. [[${color green}${hr 1}${color}
]]
the_Date = {
    {y = 2015, m = 10, d =  1, name = '国庆'},
    {y = 2015, m = 11, d = 12, name = '(秋)考试周'},
    {y = 2016, m =  1, d =  1, name = '元旦'},
    {y = 2016, m =  1, d = 14, name = '(冬)考试周'},
    {y = 2016, m =  1, d = 24, name = '寒假'},
    {y = 2016, m =  4, d =  4, name = '清明'},
    {y = 2016, m =  5, d =  1, name = '劳动节'},
    {y = 2016, m =  4, d = 23, name = '(春)考试周'},
    {y = 2016, m =  6, d =  9, name = '端午'},
    {y = 2016, m =  6, d = 24, name = '(夏)考试周'},
    {y = 2016, m =  7, d =  4, name = '暑假'}
}
n     = 1
space = '    '
from  = os.date('*t')
from  = os.time({year = from.year, month = from.month, day = from.day, hour = 12})
for i = 1,#the_Date,1 do
    to  = os.time({year = the_Date[i].y, month = the_Date[i].m, day = the_Date[i].d, hour = 12})
    spr = to - from
    if spr > 0 then
        spr = (string.format("%.0f", spr / 86400))
        conky.text = conky.text .. string.format([[${font Bold:size=16}%s${font}天 ${alignr}${font Bold:size=12}%s${font}
%s]], spr, the_Date[i].name, space)
        if n == 2 then break; end
        n = n + 1
        space = space .. '    '
    end
end

for i = 1,#space/4,1 do
    conky.text = conky.text .. [[

]]
end
