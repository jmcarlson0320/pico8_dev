pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
t = 0.2
function _init()
    p1 = {x = 10, y = 30}
    p2 = {x = 100, y = 100}
    my_layout = {
        {1},
        {2},
        {3}
    }
    set_layout(my_layout)
end

function _update()
    cls()
    local p = affine_comb(p1, p2, t)
    line(p1.x, p1.y, p2.x, p2.y, 6)
    circfill(p.x, p.y, 2, 10)
    circfill(p1.x, p1.y, 2, 8)
    circfill(p2.x, p2.y, 2, 12)
    update_cursor()
    t = do_slider(1, "t", 0, 100, cursor_over(1), 0, 1, t, 50)
    p1.x = do_slider(2, "p1.x", 0, 110, cursor_over(2), 0, 128, p1.x, 50)
    p1.y = do_slider(3, "p1.y", 0, 120, cursor_over(3), 0, 128, p1.y, 50)
    print("affine combination demo", 0, 0, 6)
    print("p = ap1 + bp2")
    print("where a + b = 1")
    print("a = 1 - t")
    print("b = t")
    flip()
end

function affine_comb(p1, p2, t)
    local a = 1 - t
    local b = t
    p = {}
    p.x = a * p1.x + b * p2.x
    p.y = a * p1.y + b * p2.y
    return p
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
