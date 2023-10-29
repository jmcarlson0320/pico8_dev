pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

-- main
-- todo
-- cleanup enemies and bullets when off screen
-- player ship explosion
-- enemy types
-- - bigger enemies
-- simplify scheduler
--  - use a simple table
--  - {time, x, y, type, brain}
--  - allow events at same time in succession for wave spawning
-- wave system
-- general animation component/system
-- animations should use local t
-- power ups
-- weapon component
-- missles fire seperately
-- other weapons

function debug(x)
    print(x)
end

function _init()
    t = 0
    init_title()
end

function _update()
    t += 1
    _upd()
end

function _draw()
    _drw()
end
-->8
-- title
function init_title()
    _upd = update_title
    _drw = draw_title
    stars = make_starfield(40)
end

function update_title()
    if btnp(4) or btnp(5) then
        init_play()
    end

    foreach(stars, update_star)
    foreach(particles, update_particle)
end

function draw_title()
    cls(0)
    foreach(stars, draw_star)
    foreach(particles, draw_particle)
    print("title screen\n", 50, 50, 7)
    print("press ❎ or 🅾️ to start", 30, 58, 7)
end

function title_input()
end
-->8
-- play
function init_play()
    t = 0
    _upd = update_play
    _drw = draw_play
    lives = 3
    score = 10000
    particles = {}
    missiles = {}
    enemies = {}
    init_weapon_timers()
    ship = make_ship()
    ship.x = 60
    ship.dx = 0
    ship.dir = "straight"
    lives = 3
    add_event(60, 0, 5)
end

function update_play()
    blaster_timer -= 1
    missile_timer -= 1
    update_ship()
    update_wave_spawner()
    foreach(enemies, update_enemy)
    foreach(missiles, update_missile)
    foreach(blaster_bullets, update_bullet)
    foreach(enemy_bullets, update_bullet)
    foreach(particles, update_particle)
    foreach(stars, update_star)
    bullet_enemy_collisions()
    bullet_player_collisions()
    enemy_player_collisions()
    if lives <= 0 then
        init_gameover()
    end
    if btnp(4) then
        add_intercepter(20 + rnd(80), -10, slow_advance_and_shoot)
    end
end

function draw_play()
    cls()
    foreach(stars, draw_star)
    draw_ship()
    foreach(missiles, draw_missile)
    foreach(blaster_bullets, draw_bullet)
    foreach(enemy_bullets, draw_bullet)
    foreach(particles, draw_particle)
    foreach(enemies, draw_enemy)
    draw_ui(4, 4)
end

function draw_ui(x, y)
    for i = 1, lives do
        local offset = (i - 1) * 8
        spr(36, x + 0 + offset, y + 0)
    end
    print(score, x + 50, y, 7)
end
-->8
-- sandbox
function init_sandbox()
    _upd = update_sandbox
    _drw = draw_sandbox
    add_intercepter(60, 10, slow_advance_and_shoot)
end

function update_sandbox()
    foreach(enemies, update_enemy)
    foreach(enemy_bullets, update_bullet)
end

function draw_sandbox()
    cls(0)
    foreach(enemies, draw_enemy)
    foreach(enemy_bullets, draw_bullet)
    print("sandbox\n", 0, 0, 7)
end
-->8
-- gameover
function init_gameover()
    _upd = update_gameover
    _drw = draw_gameover
end

function update_gameover()
    if btnp(4) or btnp(5) then
        init_title()
    end
    foreach(stars, update_star)
end

function draw_gameover()
    cls(0)
    foreach(stars, draw_star)
    print("gameover\n", 50, 50, 7)
    print("press ❎ or 🅾️ to continue", 20, 58, 7)
end
-->8
-- enemies
enemies = {}

function add_intercepter(x, y, brain)
    local e = {}
    e.x = x
    e.y = y
    e.angle = 0
    e.speed = 0
    e.hp = 5
    e.score = 10
    e.sprite = 65
    e.drift_params = slow_drift
    e.hitbox = {
        x0 = 2,
        y0 = 1,
        x1 = 5,
        y1 = 3
    }
    e.flash = 0
    e.brain = brain
    e.brain_inst_pointer = 1
    e.wait_timer = 0
    add(enemies, e)
end

function update_enemy(e)
    if e.hp <= 0 then
        explode_enemy(e)
        return
    end
    if e.wait_timer > 0 then
        e.wait_timer -= 1
    else
        process_brain(e)
    end
    move_enemy(e)
    drift(e)
end

function move_enemy(e)
    local dx = e.speed * cos(e.angle)
    local dy = e.speed * sin(e.angle)
    e.x += dx
    e.y += dy
end

function draw_enemy(e)
    local frames = { 89, 90, 91, 92 }
    local ticks_per_frame = 3
    local i = flr(t / ticks_per_frame % #frames) + 1
    spr(frames[i], e.x, e.y - 7)
    if e.flash > 0 then
        e.flash -= 1
        for i = 1, 16 do
            pal(i, 7)
        end
    end
    spr(e.sprite, e.x, e.y)
    pal()
end

function explode_enemy(e)
    smoke(e.x + 4, e.y + 2)
    large_flash(e.x + 4, e.y + 2)
    sfx(1)
    del(enemies, e)
end

function drift(e)
    local d = e.drift_params
    if not d then
        return
    end
    e.x += d.ax * sin(t / d.tx + d.px)
    e.y += d.ay * sin(t / d.ty + d.py)
end

slow_drift = {
        ax = 0.1, tx = 90, px = 0,
        ay = 0.05, ty = 60, py = 0
}
-->8
--ship
function make_ship()
    local s = {}
    s.x = 60
    s.y = 112
    s.dir = 0
    s.lastdir = 0
    s.spd = 2
    s.sprites = {
        [1] = 33,
        [5] = 33,
        [8] = 33,
        [0] = 34,
        [3] = 34,
        [4] = 34,
        [2] = 35,
        [6] = 35,
        [7] = 35
    }
    s.hitbox = {
        x0 = 2,
        y0 = 2,
        x1 = 5,
        y1 = 6
    }
    s.invul = 0
    s.draw = true
    return s
end

function update_ship()
    ship.dir = get_dir_from_input()
    ship.x += x_dir[ship.dir] * ship.spd
    ship.y += y_dir[ship.dir] * ship.spd
    ship.x = mid(0, ship.x, 120)
    ship.y = mid(0, ship.y, 120)

    if ship.invul > 0 then
        ship.invul -= 1
        if ship.invul % 3 == 0 then
            ship.draw = not ship.draw
        end
        if ship.invul == 0 then
            ship.draw = true
        end
    else
        if btn(4) then fire_missile() end
        if btn(5) then fire_blaster() end
    end

end

function draw_ship()
    if ship.draw == false then return end

    local sp = ship.sprites[ship.dir]
    spr(sp, ship.x, ship.y)

    local left_offset = 0
    local right_offset = 0
    if sp == 35 then
        left_offset = 1
    elseif sp == 33 then
        right_offset = -1
    end

    local frames = { 6, 7, 8, 9 }
    local ticks_per_frame = 3
    local i = flr(t / ticks_per_frame % #frames) + 1
    spr(frames[i], ship.x - 3 + left_offset, ship.y + 8)
    spr(frames[i], ship.x + 2 + right_offset, ship.y + 8)
end

function fire_blaster()
    if blaster_timer <= 0 then
        make_blaster_bullet(ship.x - 3, ship.y)
        make_blaster_bullet(ship.x + 3, ship.y)
        small_flash(ship.x + 1, ship.y)
        small_flash(ship.x + 6, ship.y)
        sfx(2)
        blaster_timer = 5
    end
end

function fire_missile()
    if missile_timer <= 0 then
        make_missile(ship.x - 4, ship.y)
        make_missile(ship.x + 4, ship.y)
        small_flash(ship.x + 1, ship.y - 1)
        small_flash(ship.x + 7, ship.y - 1)
        sfx(0)
        missile_timer = 30
    end
end

function reset_ship()
    ship.invul = 30
end

dir_code = { [0] = 0, 1, 2, 0, 3, 5, 6, 3, 4, 8, 7, 4, 0, 1, 2, 0 }
x_dir = { [0] = 0, -1, 1, 0, 0, -0.8, 0.8, 0.8, -0.8 }
y_dir = { [0] = 0, 0, 0, -1, 1, -0.8, -0.8, 0.8, 0.8 }

function get_dir_from_input()
    local msk = btn() & 0xf
    local dir = dir_code[msk]
    return dir
end
-->8
--effects
particles = {}
star_colors = { 1, 5 }
stars = {}

function make_particle(x, y)
    local p = {}
    p.x = x
    p.y = y
    p.dx = rnd()
    p.dy = rnd()
    p.ddy = 0
    p.lifetime = 30
    p.age = 0
    p.rad_tbl = { 0 }
    p.col_tbl = { 7 }
    add(particles, p)
end

function update_particle(p)
    if p.age > p.lifetime then
        del(particles, p)
    else
        p.age += 1
        p.x += p.dx
        p.y += p.dy
        p.dy += p.ddy
    end
end

function draw_particle(p)
    local n_col = #p.col_tbl
    local n_rad = #p.rad_tbl
    local c = flr(p.age / p.lifetime * n_col) + 1
    local r = flr(p.age / p.lifetime * n_rad) + 1
    circfill(p.x, p.y, p.rad_tbl[r], p.col_tbl[c])
end

--particle effects
function missle_trail(x, y)
    local p = {}
    p.x = x + rnd(4) - 2
    p.y = y + rnd(4) - 2
    p.dx = rnd(0.6) - 0.3
    p.dy = -0.3
    p.ddy = 0.1
    p.lifetime = 5 + rnd(30)
    p.age = 0
    p.rad_tbl = { 2, 1, 1, 0 }
    p.col_tbl = { 7, 7, 10, 9, 8, 4, 4, 4, 7, 5, 5, 5 }
    add(particles, p)
end

function small_flash(x, y)
    local p = {}
    p.x = x
    p.y = y
    p.dx = 0
    p.dy = 0
    p.ddy = 0
    p.lifetime = 2
    p.age = 0
    p.rad_tbl = { 5, 4, 3, 2, 0 }
    p.col_tbl = { 7 }
    add(particles, p)
end

function large_flash(x, y)
    local p = {}
    p.x = x
    p.y = y
    p.dx = 0
    p.dy = 0
    p.ddy = 0
    p.lifetime = 6
    p.age = 0
    p.rad_tbl = { 14, 8, 5, 0 }
    p.col_tbl = { 7 }
    add(particles, p)
end

function smoke(x, y)
    for i = 1, 10 do
        local p = {}
        p.x = x
        p.y = y
        p.dx = rnd(2) - 1
        p.dy = rnd(2) - 1
        p.ddy = 0
        p.lifetime = 5 + rnd(15)
        p.age = 0
        p.rad_tbl = { 6, 3, 2 }
        p.col_tbl = { 10, 9, 5 }
        add(particles, p)
    end
end

function sparks(x, y)
    for i = 1, 10 do
        local p = {}
        p.x = x
        p.y = y
        p.dx = rnd(3) - 1.5
        p.dy = rnd(3) - 1.5
        p.ddy = 0
        p.lifetime = 5 + rnd(10)
        p.age = 0
        p.rad_tbl = { 0 }
        p.col_tbl = { 10, 9 }
        add(particles, p)
    end
end

function make_starfield(n)
    local starfield = {}
    for i = 1, n do
        local s = {}
        s.x = rnd(128)
        s.y = rnd(128)
        s.layer = flr(rnd(2)) + 1
        s.dy = s.layer
        add(starfield, s)
    end
    return starfield
end

function update_star(s)
    s.y += s.dy
    if s.y > 127 then s.y = 0 end
end

function draw_star(s)
    local prev_y_pos = s.y - s.dy
    local col = star_colors[s.layer]
    line(s.x, s.y, s.x, prev_y_pos, col)
end
-->8
--weapons
missiles = {}
blaster_bullets = {}
enemy_bullets = {}
blaster_timer = 0
missile_timer = 0

function make_blaster_bullet(x, y)
    local b = {}
    b.x = x
    b.y = y
    b.dx = 0
    b.dy = -6
    b.sprite = 11
    b.hitbox = {
        x0 = 2,
        y0 = 1,
        x1 = 5,
        y1 = 6
    }
    add(blaster_bullets, b)
end

function make_enemy_bullet(x, y, dx, dy)
    local b = {}
    b.x = x
    b.y = y
    b.dx = dx
    b.dy = dy
    b.sprite = 12
    b.hitbox = {
        x0 = 2,
        y0 = 2,
        x1 = 5,
        y1 = 5
    }
    add(enemy_bullets, b)
end

function update_bullet(b)
    b.x += b.dx
    b.y += b.dy
    if b.y < -8 then
        del(blaster_bullets, b)
    end
end

function draw_bullet(b)
    spr(b.sprite, b.x, b.y)
end

function make_missile(x, y)
    local m = {}
    m.x = x
    m.y = y
    m.dy = -3
    m.hitbox = {
        x0 = 3,
        y0 = 0,
        x1 = 4,
        y1 = 2
    }
    add(missiles, m)
end

function update_missile(m)
    m.y += m.dy
    if m.y < 0 then
        del(missiles, m)
    end
    missle_trail(m.x + 4, m.y + 10)
end

function draw_missile(m)
    spr(10, m.x, m.y)
end

function init_weapon_timers()
    time_of_last_shot = t
    b_cooldwn = 15
end

-->8
--collision
function draw_hitbox(o)
    local h = o.hitbox
    rect(o.x + h.x0, o.y + h.y0, o.x + h.x1, o.y + h.y1, 8)
end

function has_collided(a, b)
    local ha = a.hitbox
    local hb = b.hitbox
    if a.y + ha.y0 > b.y + hb.y1 then return false end
    if b.y + hb.y0 > a.y + ha.y1 then return false end
    if a.x + ha.x1 < b.x + hb.x0 then return false end
    if b.x + hb.x1 < a.x + ha.x0 then return false end
    return true
end

function bullet_enemy_collisions()
    for b in all(blaster_bullets) do
        for e in all(enemies) do
            if has_collided(b, e) then
                e.flash = 4
                del(blaster_bullets, b)
                sparks(e.x + 4, e.y + 2)
                small_flash(e.x + 4, e.y + 2)
                e.hp -= 4
                sfx(3)
            end
        end
    end
end

function bullet_player_collisions()
    if ship.invul > 0 then return end
    for b in all(enemy_bullets) do
        if has_collided(b, ship) then
            del(enemy_bullets, b)
            sparks(ship.x + 4, ship.y + 2)
            small_flash(ship.x + 4, ship.y + 2)
            sfx(3)
            reset_ship()
            lives -=1
            return
        end
    end
end

function enemy_player_collisions()
    for e in all(enemies) do
        if has_collided(e, ship) then
            e.flash = 4
            e.hp -= 2
            reset_ship()
            lives -= 1
            return
        end
    end
end
-->8
--waves
schedule = {}

function add_event(t, e, num)
    local s = {
        t = t,
        e = e,
        num = num
    }
    add(schedule, s)
end

function update_wave_spawner()
    local next_event = schedule[1]
    if next_event and t >= next_event.t then
        deli(schedule, 1)
        handle_event(next_event)
    end
end

function handle_event(e)
    local enemy = e.e
    local num = e.num
    for i = 1, num do
        add_intercepter(20 + rnd(80), -20 + rnd(20), seek_and_destroy)
    end
end
-->8
--brain
stationary = {
    {"sto"}
}

slow_advance_and_shoot = {
    {"hea", 0.75, 0.3},
    {"wai", 30},
    {"tar", 2},
    {"wai", 30},
    {"tar", 2},
    {"wai", 30},
    {"tar", 2},
    {"wai", 30},
    {"tar", 2},
    {"wai", 30},
    {"tar", 2},
    {"wai", 30},
    {"tar", 2},
    {"wai", 30},
    {"tar", 2},
    {"wai", 30},
    {"tar", 2},
    {"wai", 30},
    {"hea", 0.75, 1.5}
}

slow_advance = {
    {"hea", 0.75, 0.3}
}

seek_and_destroy = {
    {"hea", 0.6, 0.9},
    {"wai", 30},
    {"hea", 0.25, 0.8},
    {"wai", 30},
    {"sto"},
    {"wai", 60},
    {"hea", 0.5, 2}
}

function process_brain(e)
    if e.brain_inst_pointer > #e.brain then
        return
    end
    local inst = e.brain[e.brain_inst_pointer]
    if inst[1] == "hea" then
        heading(e, inst[2], inst[3])
    elseif inst[1] == "sto" then
        stop(e)
    elseif inst[1] == "wai" then
        wait(e, inst[2])
    elseif inst[1] == "fir" then
        fire(e, e.x, e.y, inst[2], inst[3])
    elseif inst[1] == "tar" then
        target(e, inst[2])
    end
    e.brain_inst_pointer += 1
end

function heading(enemy, angle, speed)
    enemy.angle = angle
    enemy.speed = speed
end

function stop(enemy)
    enemy.angle = 0.0
    enemy.speed = 0.0
end

function wait(enemy, frames)
    enemy.wait_timer = frames
end

function fire(enemy, angle, speed)
    local dx = cos(angle) * speed
    local dy = sin(angle) * speed
    make_enemy_bullet(enemy.x, enemy.y, dx, dy)
end

function target(enemy, speed)
    local to_target_x = ship.x - enemy.x
    local to_target_y = ship.y - enemy.y
    local angle = atan2(to_target_x, to_target_y)
    local dx = cos(angle) * speed
    local dy = sin(angle) * speed
    make_enemy_bullet(enemy.x, enemy.y, dx, dy)
end

__gfx__
000000000200080008000080008000200000000000008000000090000000a0000000a0000000a000000280000009900000000000000000000000000000000000
00000000020008000800008000800020008080000000800000008000000090000000a00000009000000670000097790000888800000000000000000000000000
00700700020002808200002808200020088088000000200000008000000000000000900000008000000670000097790008eeee80000000000000000000000000
000770000207c2808207c0280827c020088888000000000000000000000000000000000000000000006007000097790008e77e80000000000000000000000000
0007700002282280828888280822822000808000000000000000000000000000000000000000000000000000009aa90008e77e80000000000000000000000000
0070070002022880880220880882202000000000000000000000000000000000000000000000000000000000009aa90008eeee80000000000000000000000000
0000000002000800080000800080002000000000000000000000000000000000000000000000000000000000009aa90000888800000000000000000000000000
0000000005000d000d0000d000d00050000000000000000000000000000000000000000000000000000000000009900000000000000000000000000000000000
0000000003000b000b0000b000b00030000000000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000003000b000b0000b000b0003000b0b0000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000030003b0b300003b0b3000300bb0bb000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000307c3b0b307c03b0b37c0300bbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000033b33b0b3bbbb3b0b33b33000b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000003033bb0bb0330bb0bb33030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000003000b000b0000b000b00030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005000d000d0000d000d00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000009000a000a0000a000a00090000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000009000a000a0000a000a0009000a0a0000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000090009a0a900009a0a9000900aa0aa000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000907c9a0a907c09a0a97c0900aaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000099a99a0a9aaaa9a0a99a99000a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000009099aa0aa0990aa0aa99090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000009000a000a0000a000a00090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005000d000d0000d000d00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d000c000c0000c000c000d0000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d000c000c0000c000c000d000c0c0000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d000dc0cd0000dc0cd000d00cc0cc000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d07cdc0cd07c0dc0cd7c0d00ccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ddcddc0cdccccdc0cddcdd000c0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d0ddcc0cc0dd0cc0ccdd0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d000c000c0000c000c000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005000d000d0000d000d00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000e00000e00e00000e000000000000000000000000000000000000000000000000000000404000000000000090900000404000000000000000000000000000
00e2e02000e22e00020e2e00000000000000000000000000000000000000000000000000004040000090900000a0a00000909000000000000000000000000000
00ec2020020cc0200202ce000000000000000000000000000000000000000000000000000090900000a0a00000a0a00000a0a000000000000000000000000000
00222000020220200002220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00200000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000300000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00033b000303303000b3300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003b33000b3bb3b00033b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bc3000003cc3000003cb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00033000000330000003300000000000000000000000000000000000000000000000000000040000000040000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000094000000490000000400000040000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000a90000004a0000004900000049000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000aa0000009a000000aa0000009a000000000000000000000000000
00007000007007000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d7000007dd7000007d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dd000000dd000000dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c7000007cc7000007c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000770000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000070007000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00079000070007000097000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099000970007900099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999000979097900099900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c90000909c90900009c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00090000000900000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
7b0500003e6103161025610206102061020610216102061020610206101e6101f6101e6101e6101d6101d6101d6101d6101d6101c6101a6101a61019610196101961018610186101761016610166101661015610
970600002967000670006700067000670006700065000650006200062000620006200062000610006100061000610006100061000610006100061000610006100061000610006000060000600006000060000600
94010000225701e5601c5601955017550165401554013540125402950026500255000b50008500065000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000200000e0202f000290000a000150000a000130000a000010000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
