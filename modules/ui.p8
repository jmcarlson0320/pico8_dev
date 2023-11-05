pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- main

function _init()
    background = 1
    red = 150
    blue = 0
    green = 10
    alpha = 50
    local my_layout = {
        { 1, 2, 3, 4 },
        { 5 },
        { 6 },
        { 7 },
        { 8 }
    }
    set_layout(my_layout)
end

function _update()
end

function _draw()
    cls(background)
    if do_button(1, "file", 0, 0, cursor_over(1)) then
        background += 1
    end
    update_cursor()
    do_button(2, "settings", 20, 0, cursor_over(2))
    do_button(3, "edit", 56, 0, cursor_over(3))
    do_button(4, "run", 76, 0, cursor_over(4))
    red = do_slider(5, "red", 0, 20, cursor_over(5), 0, 256, red, 25)
    blue = do_slider(6, "blue", 0, 30, cursor_over(6), 0, 1, blue, 25)
    green = do_slider(7, "green", 0, 40, cursor_over(7), 0, 250, green, 25)
    alpha = do_slider(8, "alpha", 0, 50, cursor_over(8), 0, 100, alpha, 25)
end

-->8
-- ui

active = 0

layout = {{}}
curs_x = 1
curs_y = 1

function set_layout(new_layout)
    layout = new_layout
    curs_x = 1
    curs_y = 1
    active = 0
end

function update_cursor()
    if btnp(0) then curs_x -= 1 end
    if btnp(1) then curs_x += 1 end
    if btnp(2) then curs_y -= 1 end
    if btnp(3) then curs_y += 1 end
    curs_y = mid(1, curs_y, #layout)
    curs_x = mid(1, curs_x, #layout[curs_y])
end

function cursor_over(id)
    return id == layout[curs_y][curs_x]
end

function do_button(id, txt, x, y, over)
    local result = do_button_logic(id, over)
    draw_button(id, txt, x, y, over)
    return result
end

function do_button_logic(id, over)
    local result = false
    if id == active then
        if not btn(5) then
            result = true
            active = nil
        end
    elseif over then
        if btn(5) then
            active = id
        end
    end
    return result
end

function draw_button(id, txt, x, y, over)
    local w = #txt * 4 + 2
    local h = 8
    if id == active then
        rectfill(x, y, x + w, y + h, 8)
    end
    if over then
        rect(x, y, x + w, y + h, 13)
    end
    print(txt, x + 2, y + 2, 6)
end

function do_slider(id, txt, x, y, over, min, max, val, length)
    local val = do_slider_logic(id, over, min, max, val, length)
    draw_slider(id, txt, x, y, over, min, max, val, length)
    return val
end

function do_slider_logic(id, over, min, max, val, length)
    local stepsize = (max - min) / length
    if id == active then
        if btn(5) then
            if btn(0) then val -= stepsize end
            if btn(1) then val += stepsize end
        elseif btn(4) then
            if btnp(0) then val -= stepsize end
            if btnp(1) then val += stepsize end
        end
        if (not btn(4) and not btn(5)) or
           (not over) then
            active = nil
        end
    elseif over then
        if btn(4) or btn(5) then
            active = id
        end
    end
    return mid(min, val, max)
end

function draw_slider(id, txt, x, y, over, min, max, val, length)
    local norm = (val - min) / (max - min)
    local slider_offset = flr(norm * length + 0.5)
    line(x + 2, y + 3, x + length + 2, y + 3, 6)
    line(x + 2 + slider_offset, y + 2, x + 2 + slider_offset, y + 4, 13)
    if id == active then
        line(x + 2 + slider_offset, y + 2, x + 2 + slider_offset, y + 4, 8)
    end
    if over then
        print(txt..":"..val, x + length + 6, y + 1, 13)
        rect(x, y, x + length + 4, y + 6, 13)
    end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
