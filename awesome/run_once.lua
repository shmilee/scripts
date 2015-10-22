local awful = require("awful")

-- autostart programs
function run_once(prg,arg_string,pname,screen)
    if not prg then
        do return nil end
    end

    if not pname then
       pname = prg
    end

    if not arg_string then 
        awful.util.spawn_with_shell("pgrep -f -u $USER -x '" .. pname .. "' || (" .. prg .. ")",screen)
    else
        awful.util.spawn_with_shell("pgrep -f -u $USER -x '" .. pname .. " ".. arg_string .."' || (" .. prg .. " " .. arg_string .. ")",screen)
    end
end
run_once("compton","-CGfF -o 0.38 -O 200 -I 200 -t 0 -l 0 -r 3 -D2 -m 0.88")
run_once("conky","-c " .. os.getenv("HOME") .. "/.config/awesome/conky.lua")
run_once("fcitx")
run_once("parcellite")
run_once("sogou-autostart","","sogou-qimpanel")
run_once("volnoti","-t 2 -a 0.8 -r 50")
run_once("wicd-gtk","-t","/usr/bin/python2 -O /usr/share/wicd/gtk/wicd-client.py")
