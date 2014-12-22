-- revelation .lua
--
-- Library that implements Expose like behavior.
--
-- @author Perry Hargrave resixian@gmail.com
-- @author Espen Wiborg espenhw@grumblesmurf.org
-- @author Julien Danjou julien@danjou.info
-- @auther Quan Guo guotsuan@gmail.com
--
-- @copyright 2008 Espen Wiborg, Julien Danjou
--


local beautiful    = require("beautiful")
local wibox        = require("wibox")
local awful        = require('awful')
local aw_rules     = require('awful.rules')
local pairs        = pairs
local setmetatable = setmetatable
local naughty      = require("naughty")
local table        = table
local tostring     = tostring
local capi         = {
    tag            = tag,
    client         = client,
    keygrabber     = keygrabber,
    mousegrabber   = mousegrabber,
    mouse          = mouse,
    screen         = screen
}

local revelation ={}
local clientData = {} -- table that holds the positions and sizes of floating clients

charorder = "jkluiopyhnmfdsatgvcewqzx1234567890"
hintbox = {} -- Table of letter wiboxes with characters as the keys

revelation = {
    -- Name of expose tag.
    tag_name = "Revelation",

    -- Match function can be defined by user.
    -- Must accept a `rule` and `client` and return `boolean`.
    -- The rule forms follow `awful.rules` syntax except we also check the
    -- special `rule.any` key. If its true, then we use the `match.any` function
    -- for comparison.
    match = {
        exact = aw_rules.match,
        any   = aw_rules.match_any
    },
    property_to_watch={
        minimized            = false,
        fullscreen           = false,
        maximized_horizontal = false,
        maximized_vertical   = false,
        sticky               = false,
        ontop                = false,
        above                = false,
        below                = false,
    },
    tags_status = {},
    is_excluded = false,
    curr_tag_only = false
}


-- Executed when user selects a client from expose view.
--
-- @param restore Function to reset the current tags view.
local function selectfn(restore)
    return function(c)
        restore()
        -- Pop to client tag
        awful.tag.viewonly(c:tags()[1], c.screen)
        -- Focus and raise
        if c.minimized then
            c.minimized = false
        end
        capi.client.focus = c
        awful.screen.focus(c.screen)
        c:raise()
    end
end

-- Tags all matching clients with tag t
-- @param rule The rule. Conforms to awful.rules syntax.
-- @param clients A table of clients to check.
-- @param t The tag to give matching clients.
local function match_clients(rule, clients, t, is_excluded)
    local mfc = rule.any and revelation.match.any or revelation.match.exact
    local mf = is_excluded and function(c,rule) return not mfc(c,rule) end or mfc 
    local k,v, flt
    for _, c in pairs(clients) do
        if mf(c, rule) then
            -- Store geometry before setting their tags
            clientData[c] = {}
            if awful.client.floating.get(c) then 
                clientData[c]["geometry"] = c:geometry()
                flt = awful.client.property.get(c, "floating") 
                if flt ~= nil then 
                    clientData[c]["floating"] = flt
                    awful.client.property.set(c, "floating", false) 
                end

            end

            for k,v in pairs(revelation.property_to_watch) do
                clientData[c][k] = c[k]
                c[k] = v
                
            end
            awful.client.toggletag(t, c)
        end
    end
    return clients
end


-- Implement Exposé (ala Mac OS X).
--
-- @param rule A table with key and value to match. [{class=""}]


function revelation.expose(args)
    local args = args or {}
    local rule = args.rule or {}
    local is_excluded = args.is_excluded or false
    local curr_tag_only = args.curr_tag_only or false

    revelation.is_excluded = is_excluded
    revelation.curr_tag_only = curr_tag_only

    local t={}
    local zt={}


    for scr=1,capi.screen.count() do

        all_tags = awful.tag.gettags(scr)

        t[scr] = awful.tag.new({revelation.tag_name},
        scr,
        awful.layout.suit.fair)[1]
        zt[scr] = awful.tag.new({revelation.tag_name.."_zoom"},
        scr,
        awful.layout.suit.fair)[1]


        if curr_tag_only then 
            match_clients(rule, awful.client.visible(scr), t[scr], is_excluded)
        else
            match_clients(rule, capi.client.get(scr), t[scr], is_excluded)
        end

        awful.tag.viewonly(t[scr], t.screen)
    end 


    local hintindex = {} -- Table of visible clients with the hint letter as the keys
    local clientlist = awful.client.visible()
    for i,thisclient in pairs(clientlist) do 
        -- Move wiboxes to center of visible windows and populate hintindex
        local char = charorder:sub(i,i)
        hintindex[char] = thisclient
        local geom = thisclient.geometry(thisclient)
        hintbox[char].visible = true
        hintbox[char].x = geom.x + geom.width/2 - hintsize/2
        hintbox[char].y = geom.y + geom.height/2 - hintsize/2
        hintbox[char].screen = thisclient.screen
    end

    local function restore()
        local k,v
        for scr=1, capi.screen.count() do
            awful.tag.history.restore(scr)
            t[scr].screen = nil
        end
        capi.keygrabber.stop()
        capi.mousegrabber.stop()
        for scr=1, capi.screen.count() do
            t[scr].activated = false
            zt[scr].activated = false
        end

        local clients
        for scr=1, capi.screen.count() do
            if revelation.curr_tag_only then 
                clients = awful.client.visible(scr)
            else
                clients = capi.client.get(scr)
            end

            for _, c in pairs(clients) do
                if clientData[c] then
                    for k,v in pairs(clientData[c]) do 
                        if v ~= nil then 
                            if k== "geometry" then
                                c:geometry(v)
                            elseif k == "floating" then
                                awful.client.property.set(c, "floating", v) 
                            else
                                c[k]=v
                            end
                        end
                    end
                end
            end
        end

        for i,j in pairs(hintindex) do
            hintbox[i].visible = false
        end

    end

    local zoomed = false
    local zoomedClient = nil
    local keyPressed = false

    capi.keygrabber.run(function (mod, key, event)
        local c = nil
        local keyPressed = false

        if event == "release" then return true end
            
        --if awful.util.table.hasitem(mod, "Shift") then
            --debuginfo("dogx")
            --debuginfo(string.lower(key))
        --end
            
        if awful.util.table.hasitem(mod, "Shift") then
            if keyPressed then
                keyPressed = false
            else
                c = hintindex[string.lower(key)]
                if not zoomed and c ~= nil then
                    awful.tag.viewonly(zt[capi.mouse.screen], capi.mouse.screen)
                    awful.client.toggletag(zt[capi.mouse.screen], c)
                    zoomedClient = c
                    zoomed = true
                elseif zoomedClient ~= nil then
                    awful.tag.history.restore(capi.mouse.screen)
                    awful.client.toggletag(zt[capi.mouse.screen], zoomedClient)
                    zoomedClient = nil
                    zoomed = false 
                end
            end
        end

        if hintindex[key] then 
            --client.focus = hintindex[key]
            --hintindex[key]:raise()
            

            selectfn(restore)(hintindex[key])

            for i,j in pairs(hintindex) do
                hintbox[i].visible = false
            end

            return false
        end 

        if key == "Escape" then
            for i,j in pairs(hintindex) do
                hintbox[i].visible = false
            end
            restore()
            return false
        end

        return true
    end)


    local pressedMiddle = false
    local pressedRight = false

    capi.mousegrabber.run(function(mouse)
        local c = awful.mouse.client_under_pointer()
        if mouse.buttons[1] == true then
            selectfn(restore)(c)

            for i,j in pairs(hintindex) do
                hintbox[i].visible = false
            end
            return false
        elseif mouse.buttons[2] == true and pressedMiddle == false and c ~= nil then 
            -- is true whenever the button is down. 
            pressedMiddle = true 
            -- extra variable needed to prevent script from spam-closing windows
            c:kill()
            return true
        elseif mouse.buttons[2] == false and pressedMiddle == true then
            pressedMiddle = false
        elseif mouse.buttons[3] == true and pressedRight == false then
            if not zoomed and c ~= nil then
                awful.tag.viewonly(zt[capi.mouse.screen], capi.mouse.screen)
                awful.client.toggletag(zt[capi.mouse.screen], c)
                zoomedClient = c
                zoomed = true
            elseif zoomedClient ~= nil then
                awful.tag.history.restore(capi.mouse.screen)
                awful.client.toggletag(zt[capi.mouse.screen], zoomedClient)
                zoomedClient = nil
                zoomed = false 
            end
        end

        return true
        --Strange but on my machine only fleur worked as a string.
        --stole it from
        --https://github.com/Elv13/awesome-configs/blob/master/widgets/layout/desktopLayout.lua#L175
    end,"fleur")
end

-- Create the wiboxes, but don't show them

function revelation.init(args)
    hintsize = 60
    local fontcolor = beautiful.fg_normal
    local letterbox = {}

    local args = args or {}

    revelation.tag_name = args.tag_name or revelation.tag_name
    if args.match then 
        revelation.match.exact = args.match.exact or revelation.match.exact
        revelation.match.any = args.match.any or revelation.match.any
    end


    for i = 1, #charorder do
        local char = charorder:sub(i,i)
        hintbox[char] = wibox({fg=beautiful.fg_normal, bg=beautiful.bg_focus, border_color=beautiful.border_focus, border_width=beautiful.border_width})
        hintbox[char].ontop = true
        hintbox[char].width = hintsize
        hintbox[char].height = hintsize
        letterbox[char] = wibox.widget.textbox()
        letterbox[char]:set_markup("<span color=\"" .. beautiful.fg_normal.."\"" .. ">" .. char.upper(char) .. "</span>")
        letterbox[char]:set_font("dejavu sans mono 40")
        letterbox[char]:set_align("center")
        hintbox[char]:set_widget(letterbox[char])
    end
end

local function debuginfo( message )

    mm = message

    if not message then
        mm = "false"
    end

    nid = naughty.notify({ text = tostring(mm), timeout = 10 })
end
setmetatable(revelation, { __call = function(_, ...) return revelation.expose(...) end })

return revelation
