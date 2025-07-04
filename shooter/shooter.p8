pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- main

-- TODO
-- create enemy patterns
-- stage 1, 2, 3
-- save highscores
-- power ups
-- weapon component
-- other weapons
-- missles fire seperately

function _init()
    t=0
    init_title()
end

function _update()
    t+=1
    _upd()
end

function _draw()
    _drw()
end

-- sandbox
function init_sandbox()
    ship.x = 64
    ship.y = 64
    _upd = update_sandbox
    _drw = draw_sandbox
end

function update_sandbox()
    if btnp(4) then
        explode_player()
    end
    foreach(particles, update_particle)
end

function draw_sandbox()
    cls(0)
    foreach(particles,draw_particle)
    print("sandbox\n", 0, 0, 7)
end

-- title
function init_title()

    banner = {
        x = 28,
        y = 38,
        colors = {0, 8, 12, 8, 0, 12},
        color_idx = 1,
        flashing = false
    }

    num_menu_items = 2
    menu_selection = 0
    menu_x_pos = 44
    menu_y_pos = 66

    in_transition = false
    transition_timer = 0

    _upd = update_title
    _drw = draw_title
    stars = make_starfield(40)
end

function update_title()
    if btnp(4) or btnp(5) then
        if menu_selection == 0 then
            in_transition = true
            transition_timer = 30
            banner.flashing = true
        elseif menu_selection == 1 then
            init_highscore()
        end

    end

    if btnp(2) and menu_selection > 0 then
        menu_selection -= 1
    end

    if btnp(3) and menu_selection < num_menu_items - 1 then
        menu_selection += 1
    end

    if in_transition then
        if transition_timer <= 0 then
            init_ready()
        else
            transition_timer -=1
        end
    end

    foreach(stars,update_star)
end

function draw_title()
    cls(0)
    foreach(stars,draw_star)

    for i = 1, 3 do
        print("\^w\^tbot storm!", banner.x + i, banner.y + i, banner.colors[banner.color_idx])
        banner.color_idx += 1
        if banner.flashing then
            mod_val = 5
        else
            mod_val = 3
        end
        if banner.color_idx > mod_val then
            banner.color_idx = 1
        end
    end

    print("play", menu_x_pos, menu_y_pos, 7)
    print("best scores", menu_x_pos, menu_y_pos + 10, 7)
    print("◆", menu_x_pos - 10, menu_y_pos + menu_selection * 10, 7)
end

-- highscore
function init_highscore()
    _upd = update_highscore
    _drw = draw_highscore
end

function update_highscore()
    foreach(stars,update_star)
    if btnp(4) or btnp(5) then
        init_title()
    end
end

function draw_highscore()
    cls(0)
    foreach(stars,draw_star)
    print_cent("highscores", 0, 7)
    print("1.\tjmc\t100000", 0, 10, 7)
end

-- ready
function init_ready()
    ready_timer = 110
    blank_screen = true
    _upd = update_ready
    _drw = draw_ready
end

function update_ready()
    foreach(stars,update_star)
    ready_timer -= 1
    if ready_timer <= 0 then
        init_play()
    elseif ready_timer < 90 then
        blank_screen = false
    end
end

function draw_ready()
    cls(0)
    foreach(stars,draw_star)
    if (not blank_screen) then
        print_cent("get ready!!!", 54, 7)
        print(flr(ready_timer / 30) + 1, 64, 104, 7)
    end
end

-- play
function init_play()
    _upd = update_play
    _drw = draw_play
    t = 0
    lives = 3
    score = 0
    stars = make_starfield(15)
    particles = {}
    missiles = {}
    enemies = {}
    blaster_bullets = {}
    enemy_bullets = {}
    schedule = {}
    load_test_stage()
    init_ship()
end

function update_play()
    update_ship()
    process_schedule()
    foreach(enemies,update_enemy)
    foreach(missiles,update_missile)
    foreach(blaster_bullets,update_bullet)
    foreach(enemy_bullets,update_bullet)
    foreach(particles,update_particle)
    foreach(stars,update_star)
    bullet_enemy_collisions()
    bullet_player_collisions()
    enemy_player_collisions()
    if lives<=0 then
        init_gameover()
    end
    if btnp(4) then
        load_test_stage()
    end
end

function draw_play()
    cls()
    foreach(stars,draw_star)
    foreach(missiles,draw_missile)
    foreach(blaster_bullets,draw_blaster_bullet)
    foreach(enemy_bullets,draw_enemy_bullet)
    foreach(particles,draw_particle)
    draw_ship()
    foreach(enemies,draw_enemy)
    draw_ui(4,4)
    print(#enemy_bullets)
end

function draw_ui(x,y)
    for i=1,lives do
        local offset=(i-1)*8
        spr(36,x+offset,y)
    end
    print(score,x+50,y,7)
end

-- gameover
function init_gameover()
    _upd = update_gameover
    _drw = draw_gameover
end

function update_gameover()
    foreach(stars, update_star)
    if btnp(4) or btnp(5) then
        init_title()
    end
end

function draw_gameover()
    cls(0)
    foreach(stars, draw_star)
    print("gameover\n", 50, 50, 7)
    print("press ❎ or 🅾️ to continue", 20, 58, 7)
end

-- enemies
enemies = {}

interceptor = {
    hp = 4,
    score = 50,
    sprite = 81,
    size = 1,
    hitbox = {
        x0 = 0,
        y0 = 0,
        x1 = 7,
        y1 = 6
    }
}

striker = {
    hp = 12,
    score = 100,
    sprite = 65,
    size = 1,
    hitbox = {
        x0 = 0,
        y0 = 0,
        x1 = 7,
        y1 = 6
    }
}

baddy = {
    hp = 100,
    score = 1000,
    sprite = 70,
    size = 2,
    hitbox = {
        x0 = 0,
        y0 = 0,
        x1 = 15,
        y1 = 15
    }
}

function add_enemy(enemy_type, x, y, rotation, brain)
    local e = {}
    e.x = x
    e.y = y
    e.heading = rotation
    e.speed = 0
    e.max_speed = 0
    e.decel = 0
    e.accel = 0
    e.hp = enemy_type.hp
    e.score = enemy_type.score
    e.sprite = enemy_type.sprite
    e.size = enemy_type.size
    e.rotation = rotation
    e.turn_speed = 0.03
    e.drift_params = create_slow_drift()
    e.hitbox = enemy_type.hitbox
    e.flash = 0
    e.brain = brain
    e.brain_inst_pointer = 1
    e.wait_timer = 0
    e.bullet_sprayer = {
        angle = 0.0,
        magazine = 0,
        shot_timer = 0
    }
    add(enemies, e)
end

function update_enemy(e)
    check_destroyed(e)
    process_brain(e)
    update_bullet_sprayer(e)
    move_enemy(e)
    rotate_enemy(e)
    check_offscreen(e)
end

function rotate_enemy(e)
    local delta = e.rotation - e.heading
    if abs(delta) > 0.5 then
        e.heading += delta / abs(delta)
        delta = e.rotation - e.heading
    end
    if abs(delta) > e.turn_speed then
        if e.rotation < e.heading then
            e.rotation += e.turn_speed
        elseif e.rotation > e.heading then
            e.rotation -= e.turn_speed
        end
    end
end

function move_enemy(e)
    e.speed = max(0, e.speed - e.decel)
    e.speed = min(e.max_speed, e.speed + e.accel)
    local dx = e.speed * cos(e.heading)
    local dy = e.speed * sin(e.heading)
    e.x += dx
    e.y += dy
    if e.drift_params then
        drift(e)
    end
end

function check_offscreen(e)
    if e.y < -30 or
       e.y > 140 or
       e.x < -50 or
       e.x > 170 then
        del(enemies, e)
        return
    end
end

function check_destroyed(e)
    if e.hp <= 0 then
        explode_enemy(e)
        score += e.score
        return
    end
end

function draw_enemy(e)
    spr_rot(e.sprite, e.rotation, e.x, e.y)
    pal()
end

function draw_enemy_flames(e)
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
end

function update_bullet_sprayer(e)
    local s = e.bullet_sprayer
    if s.shot_timer > 0 then
        s.shot_timer -= 1
    elseif (s.shot_timer == 0) and (s.magazine > 0) then
        local dx = 1.5*cos(s.angle)
        local dy = 1.5*sin(s.angle)
        make_enemy_bullet(e.x, e.y, dx, dy, green_orb)
        s.magazine -= 1
        s.shot_timer = 3
        s.angle += 0.05
    end
end

function explode_enemy(e)
    smoke(e.x + 4, e.y + 2)
    large_flash(e.x + 4, e.y + 2)
    sfx(1)
    del(enemies, e)
end

function drift(e)
    local d = e.drift_params
    e.x += d.ax * sin(t / d.tx + d.px)
    e.y += d.ay * sin(t / d.ty + d.py)
end

function create_slow_drift()
    local p = {
        ax = 0.2, tx = 60, px = rnd(),
        ay = 0.1, ty = 30, py = rnd()
    }
    return p
end

--ship
ship = {}

function init_ship()
    ship.x = 62
    ship.y = 104
    ship.dir = 0
    ship.prev_dir = 0
    ship.lastdir = 0
    ship.spd = 2*1.414
    ship.sprites = {
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
    ship.hitbox = {
        x0 = 2,
        y0 = 2,
        x1 = 5,
        y1 = 6
    }
    ship.invul = 0
    ship.draw = true
    ship.blaster_timer = 0
    ship.missile_timer = 0
end

function update_ship()
    ship.prev_dir = ship.dir
    ship.dir = get_dir_from_input()
    if ship.dir != ship.prev_dir then
        ship.x = flr(ship.x + 0.5)
        ship.y = flr(ship.y + 0.5)
    end

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
    ship.blaster_timer -= 1
    ship.missile_timer -= 1
end

function draw_ship()
    if ship.draw == false then
        return
    end
    local sp = ship.sprites[ship.dir]
    spr(sp, ship.x, ship.y)
    draw_ship_flames()
end

function draw_ship_flames()
    local ship_flames = {
        frames = { 6, 7, 8, 9 },
        rate = 3
    }
    if ship.sprites[ship.dir] == 35 then
        draw_animation(ship_flames, ship.x - 2, ship.y + 8)
        draw_animation(ship_flames, ship.x + 2, ship.y + 8)
    elseif ship.sprites[ship.dir] == 33 then
        draw_animation(ship_flames, ship.x - 3, ship.y + 8)
        draw_animation(ship_flames, ship.x + 1, ship.y + 8)
    else
        draw_animation(ship_flames, ship.x - 3, ship.y + 8)
        draw_animation(ship_flames, ship.x + 2, ship.y + 8)
    end
end

function fire_blaster()
    if ship.blaster_timer <= 0 then
        make_blaster_bullet(ship.x - 3, ship.y)
        make_blaster_bullet(ship.x + 3, ship.y)
        small_flash(ship.x + 1, ship.y)
        small_flash(ship.x + 6, ship.y)
        ship.blaster_timer = 4
        sfx(2)
        missle_trail(ship.x - 3, ship.y)
        missle_trail(ship.x + 3, ship.y)
    end
end

function fire_missile()
    if ship.missile_timer <= 0 then
        make_missile(ship.x - 4, ship.y)
        make_missile(ship.x + 4, ship.y)
        small_flash(ship.x + 1, ship.y - 1)
        small_flash(ship.x + 7, ship.y - 1)
        sfx(0)
        ship.missile_timer = 30
    end
end

function explode_player()
    slow_explode(ship.x, ship.y)
    smoke(ship.x + 4, ship.y + 2)
    large_flash(ship.x + 4, ship.y + 2)
end

function reset_ship()
    ship.invul = 45
end

dir_code = { [0] = 0, 1, 2, 0, 3, 5, 6, 3, 4, 8, 7, 4, 0, 1, 2, 0 }
x_dir = { [0] = 0, -1, 1, 0, 0, -0.707, 0.707, 0.707, -0.707 }
y_dir = { [0] = 0, 0, 0, -1, 1, -0.707, -0.707, 0.707, 0.707 }

function get_dir_from_input()
    local msk = btn() & 0xf
    local dir = dir_code[msk]
    return dir
end

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
        return
    end

    p.age += 1
    p.x += p.dx
    p.y += p.dy
    p.dy += p.ddy
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
    p.rad_tbl = { 7, 6, 5, 2, 0 }
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

function slow_explode(x, y)
    for i = 1, 15 do
        local p = {}
        p.x = x + sin(rnd())*rnd()
        p.y = y + sin(rnd())*rnd()
        p.dx = rnd(2) - 1
        p.dy = rnd(2) - 1
        p.ddy = 0
        p.lifetime = 15 + rnd(5)
        p.age = 0
        p.rad_tbl = {7}
        p.col_tbl = {7, 6, 5}
        add(particles, p)
    end
end

function sparks(x, y)
    for i = 1, 5 do
        local p = {}
        p.x = x
        p.y = y
        p.dx = rnd(10) - 5
        p.dy = rnd(20) - 18
        p.ddy = 0.2
        p.lifetime = rnd(5)
        p.age = 0
        p.rad_tbl = { 0 }
        p.col_tbl = { 7,10 }
        add(particles, p)
    end
end

function ship_explosion(x, y)
end

function make_starfield(n)
    local starfield = {}
    for i = 1, n do
        local s = {}
        s.x = rnd(128)
        s.y = rnd(128)
        s.layer = flr(rnd(2)) + 1
        s.dy = s.layer + 2 * s.layer
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

--weapons
green_orb = {
    animation = {
        frames = { 28, 29 },
        rate = 5
    },
    hitbox = {
        x0 = 3,
        y0 = 3,
        x1 = 4,
        y1 = 4
    }
}

blue_orb = {
    animation = {
        frames = { 12, 13 },
        rate = 3
    },
    hitbox = {
        x0 = 4,
        y0 = 4,
        x1 = 4,
        y1 = 4
    }
}

blaster = {
    sprite = 11,
    hitbox = {
        x0 = 2,
        y0 = 0,
        x1 = 5,
        y1 = 10
    }
}

missiles = {}
blaster_bullets = {}
enemy_bullets = {}

function make_blaster_bullet(x, y)
    local b = {}
    b.x = x
    b.y = y
    b.dx = 0
    b.dy = -8
    b.sprite = blaster.sprite
    b.hitbox = blaster.hitbox
    add(blaster_bullets, b)
end

function make_enemy_bullet(x, y, dx, dy, bullet_type)
    local b = {}
    b.x = x
    b.y = y
    b.dx = dx
    b.dy = dy
    b.animation = bullet_type.animation
    b.hitbox = bullet_type.hitbox
    add(enemy_bullets, b)
    for i = 1, 4 do
        missle_trail(x, y)
    end
end

function update_bullet(b)
    b.x += b.dx
    b.y += b.dy
    if b.x < -8 or
       b.x > 136 or
       b.y < -8 or
       b.y > 136 then
        del(blaster_bullets, b)
        del(enemy_bullets, b)
    end
end

function draw_enemy_bullet(b)
    local a = b.animation
    draw_animation(a, b.x, b.y)
end

function draw_blaster_bullet(b)
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

--collision
function draw_hitbox(o, col)
    local h = o.hitbox
    rect(o.x + h.x0, o.y + h.y0, o.x + h.x1, o.y + h.y1, col)
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

function check_collisions_groups(group_a, group_b, callback)
    for a in all(group_a) do
        for b in all(group_b) do
            if has_collided(a, b) then
                callback(a, b)
            end
        end
    end
end

function check_collisions_object_group(obj, group, callback, early_return)
    for o in all(group) do
        if has_collided(obj, o) then
            callback(obj, o)
            if early_return then
                return
            end
        end
    end
end

function bullet_enemy_collisions()
    local function handle_bullet_enemy_collision(b, e)
        e.flash = 4
        del(blaster_bullets, b)
        sparks(e.x + 4, e.y + 2)
        small_flash(e.x + 4, e.y + 2)
        e.hp -= 4
        sfx(3)
    end

    check_collisions_groups(blaster_bullets, enemies, handle_bullet_enemy_collision)
end

function bullet_player_collisions()
    local function handle_player_bullet_collision(p, b)
        del(enemy_bullets, b)
        explode_player()
        reset_ship()
        lives -=1
    end

    if ship.invul > 0 then return end
    check_collisions_object_group(ship, enemy_bullets, handle_player_bullet_collision, true)
end

function enemy_player_collisions()
    local function handle_player_enemy_collision(p, e)
        e.flash = 4
        e.hp -= 2
        explode_player()
        reset_ship()
        lives -= 1
    end

    check_collisions_object_group(ship, enemies, handle_player_enemy_collision, true)
end

-- brain
function process_brain(enemy)
    if enemy.wait_timer > 0 then
        enemy.wait_timer -= 1
        return
    end

    if enemy.brain_inst_pointer > #enemy.brain then
        return
    end

    local cmd = enemy.brain[enemy.brain_inst_pointer]
    local fn = cmd[1]
    fn(enemy, cmd[2], cmd[3])
    enemy.brain_inst_pointer += 1
end

-- ai commands
function heading(enemy, angle, speed)
    enemy.accel = 0
    enemy.decel = 0
    enemy.heading = angle
    enemy.speed = speed
    enemy.max_speed = speed
end

function decel(enemy, rate, min_speed)
    enemy.accel = 0
    enemy.decel = rate
    enemy.min_speed = min_speed
end

function accel(enemy, rate, max_speed)
    enemy.decel = 0
    enemy.accel = rate
    enemy.max_speed = max_speed
end

function stop(enemy)
    enemy.heading = enemy.rotation
    enemy.speed = 0.0
    enemy.max_speed = 0.0
end

function wait(enemy, frames)
    enemy.wait_timer = frames
end

function fire(enemy, angle, speed)
    local dx = cos(angle) * speed
    local dy = sin(angle) * speed
    make_enemy_bullet(enemy.x, enemy.y, dx, dy, green_orb)
end

function target(enemy, speed, bullet_type)
    local to_target_x = ship.x - enemy.x
    local to_target_y = ship.y - enemy.y
    local angle = atan2(to_target_x, to_target_y)
    local dx = cos(angle) * speed
    local dy = sin(angle) * speed

    local b
    if bullet_type == "blue" then
        b = blue_orb
    elseif bullet_type == "green" then
        b = green_orb
    end

    make_enemy_bullet(enemy.x, enemy.y, dx, dy, b)
end

function spray_bullets(enemy, num_bullets)
    local s = enemy.bullet_sprayer
    s.angle = 0.6
    s.magazine = num_bullets
    s.shot_timer = 0
end

function fire_pattern(enemy)
    local angle = 0.55
    for i = 1, 5 do
        local dx = 1.5 * cos(angle)
        local dy = 1.5 * sin(angle)
        make_enemy_bullet(enemy.x, enemy.y, dx, dy, green_orb)
        angle += 0.1
    end
end

----------------------------------
-- enemy behaviors
----------------------------------
test_brain = {
    {heading, 0.75, 0.5},
    {fire_pattern, 10},
    {wait, 90, nil},
    {spray_bullets, 10},
    {wait, 90},
    {fire_pattern, 10},
}

flyin_flyout_left = {
    {heading, 0.75, 1},
    {wait, 60},
    {decel, 0.04},
    {target, 2, "blue"},
    {heading, 0.50, 0},
    {accel, 0.04, 1},
    {wait, 30},
    {heading, 0.25, 0},
    {accel, 0.04, 1},
}

flyin_flyout_right = {
    {heading, 0.75, 1},
    {wait, 60},
    {decel, 0.04},
    {target, 2, "blue"},
    {heading, 0.0, 0},
    {accel, 0.04, 1},
    {wait, 30},
    {heading, 0.25, 0},
    {accel, 0.04, 1},
}

stationary = {
    {stop}
}

fly_left = {
    {heading, 0.5, 1.5},
    {wait, 10},
    {target, 2, "green"}
}

fly_right = {
    {heading, 0.0, 1.5},
    {wait, 10},
    {target, 2, "green"}
}

slow_advance_and_shoot = {
    {heading, 0.75, 1},
    {wait, 15},
    {target, 2, "green"},
    {wait, 15},
    {target, 2, "green"},
    {wait, 5},
    {accel, 0.02, 3}
}

--event schedule
schedule = {}

function schedule_event(time, fn)
    if not schedule[time] then
        schedule[time] = {}
    end
    add(schedule[time], fn)
end

function schedule_event_list(event_list, start_time)
    for e in all(event_list) do
        schedule_event(start_time + e.time, e.fn)
    end
end

function process_schedule()
    if schedule[t] then
        for f in all(schedule[t]) do
            f()
        end
    end
end

--waves
function spawn_wave_left(y_coor)
    for i = 1, 4 do
        local f = function()
            add_enemy(interceptor, -8, y_coor + (i - 1) * 15, 0, fly_right)
        end
        schedule_event(t + (i - 1) * 15, f)
    end
end

function spawn_wave_right(y_coor)
    for i = 1, 4 do
        local f = function()
            add_enemy(interceptor, 136, y_coor + (i - 1) * 15, 0.5, fly_left)
        end
        schedule_event(t + (i - 1) * 15, f)
    end
end

function spawn_triplet(x_coor)
    add_enemy(striker, x_coor + 10, -8, 0.75, flyin_flyout)
    add_enemy(striker, x_coor - 10, -8, 0.75, flyin_flyout)
    add_enemy(striker, x_coor, -18, 0.75, flyin_flyout)
end

function spawn_pair()
    add_enemy(striker, 40, -8, 0.75, flyin_flyout_left)
    add_enemy(striker, 88, -8, 0.75, flyin_flyout_right)
end

function spawn_line()
    add_enemy(interceptor, 15, -8, 0.75, slow_advance_and_shoot)
    add_enemy(interceptor, 35, -8, 0.75, slow_advance_and_shoot)
    add_enemy(interceptor, 54, -16, 0.75, slow_advance_and_shoot)
    add_enemy(interceptor, 74, -16, 0.75, slow_advance_and_shoot)
    add_enemy(interceptor, 92, -8, 0.75, slow_advance_and_shoot)
    add_enemy(interceptor, 113, -8, 0.75, slow_advance_and_shoot)
end

--stages
function load_test_stage()
    t=0
    schedule = {}
    schedule_event_list(test_stage, 30)
end

test_stage = {
    {
        time = 1,
        fn = spawn_pair
    },
    {
        time = 20,
        fn = spawn_pair
    },
    {
        time = 40,
        fn = spawn_pair
    },
    {
        time = 60,
        fn = spawn_pair
    },
    {
        time = 120,
        fn = spawn_line
    },
    {
        time = 165,
        fn = spawn_line
    },
    {
        time = 210,
        fn = spawn_line
    },
}

-- utils
function draw_animation(animation, x, y)
    local frames = animation.frames
    local rate = animation.rate
    local i = flr(t / rate % #frames) + 1
    spr(frames[i], x, y)
end

function round(n)
    return flr(n+0.5)
end

function spr_rot(spr, angle, x, y)
    --working area on map (tile coords)
    local mx = 0
    local my = 0

    --offset into tile to rotate around (tile coords)
    local rotx = mx + 0.5
    local roty = my + 0.5

    --width of area to rotate is 1.414 tiles to cover diagonal rotation
    local w = 1.414

    local flip = false
    local scale = 1
    mset(mx, my, spr)
    pd_rotate(x, y, angle, rotx, roty, w, flip, scale)
end

function pd_rotate(x,y,rot,mx,my,w,flip,scale)
    scale=scale or 1
    w*=scale*4

    local cs, ss = cos(rot)*.125/scale,-sin(rot)*.125/scale
    local sx, sy = mx+cs*-w, my+ss*-w
    local hx = flip and -w or w

    local halfw = -w
    for py=y-w, y+w do
        tline(x-hx, py, x+hx, py, sx-ss*halfw, sy+cs*halfw, cs, ss)
        halfw+=1
    end
end

function print_cent(txt,y,color)
    local offset=64-#txt*2
    print(txt,offset,y,color)
end

__gfx__
000000000200080008000080008000200000000000008000000090000000a0000000a0000000a000000280000009900000000000000000000000000000000000
00000000020008000800008000800020008080000000800000008000000090000000a00000009000000670000097790000000000000000000000000000000000
00700700020002808200002808200020088088000000200000008000000000000000900000008000000670000097790000000000000000000000000000000000
000770000207c2808207c0280827c02008888800000000000000000000000000000000000000000000600700009779000001c100000c7c000000000000000000
0007700002282280828888280822822000808000000000000000000000000000000000000000000000000000009aa900000c7c00000777000000000000000000
0070070002022880880220880882202000000000000000000000000000000000000000000000000000000000009aa9000001c100000c7c000000000000000000
0000000002000800080000800080002000000000000000000000000000000000000000000000000000000000009aa90000000000000000000000000000000000
0000000005000d000d0000d000d00050000000000000000000000000000000000000000000000000000000000009900000000000000000000000000000000000
0000000003000b000b0000b000b00030000000000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000003000b000b0000b000b0003000b0b0000000b00000000000000000000000000000000000000000000000000000022000000ee0000000000000000000
00000000030003b0b300003b0b3000300bb0bb0000003000000000000000000000000000000000000000000000000000002ee20000e77e000000000000000000
000000000307c3b0b307c03b0b37c0300bbbbb000000000000000000000000000000000000000000000000000000000002e77e200e7777e00000000000000000
00000000033b33b0b3bbbb3b0b33b33000b0b0000000000000000000000000000000000000000000000000000000000002e77e200e7777e00000000000000000
0000000003033bb0bb0330bb0bb330300000000000000000000000000000000000000000000000000000000000000000002ee20000e77e000000000000000000
0000000003000b000b0000b000b00030000000000000000000000000000000000000000000000000000000000000000000022000000ee0000000000000000000
0000000005000d000d0000d000d00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000009000a000a0000a000a00090000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000009000a000a0000a000a0009000a0a0000000a00000000000000000000000000000000000000000000000000000044000000990000000000000000000
00000000090009a0a900009a0a9000900aa0aa000000900000000000000000000000000000000000000000000000000000499400009779000000000000000000
000000000907c9a0a907c09a0a97c0900aaaaa000000000000000000000000000000000000000000000000000000000004977940097777900000000000000000
00000000099a99a0a9aaaa9a0a99a99000a0a0000000000000000000000000000000000000000000000000000000000004977940097777900000000000000000
0000000009099aa0aa0990aa0aa99090000000000000000000000000000000000000000000000000000000000000000000499400009779000000000000000000
0000000009000a000a0000a000a00090000000000000000000000000000000000000000000000000000000000000000000044000000990000000000000000000
0000000005000d000d0000d000d00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d000c000c0000c000c000d0000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d000c000c0000c000c000d000c0c0000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d000dc0cd0000dc0cd000d00cc0cc000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d07cdc0cd07c0dc0cd7c0d00ccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ddcddc0cdccccdc0cddcdd000c0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d0ddcc0cc0dd0cc0ccdd0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d000c000c0000c000c000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005000d000d0000d000d00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000e00000999000000e000000000000000000000000000000000000000000000000000000404000000000000090900000404000000000000000000000000000
00e2e02077700000020e2e00000000000000000000000000000660000006600000000000004040000090900000a0a00000909000000000000000000000000000
00ec2020099900000202ce000000000000000000000000007226620000266227000000000090900000a0a00000a0a00000a0a000000000000000000000000000
00222000097c99900002220000000000000000000000000078277222222772870000000000000000000000000000000000000000000000000000000000000000
00200000097c99900000020000000000000000000000000078877228822778870000000000000000000000000000000000000000000000000000000000000000
00000000099900000000000000000000000000000000000078877282282778870000000000000000000000000000000000000000000000000000000000000000
00000000777000000000000000000000000000000000000078222828828222870000000000000000000000000000000000000000000000000000000000000000
00000000009990000000000000000000000000000000000072002828828200270000000000000000000000000000000000000000000000000000000000000000
000003003b00000000300000000000000000000000000000b00028c88c82000b0000000000000000000000000000000000000000000000000000000000000000
00033b0003bb000000b33000000000000000000000000000000028cccc8200000000000000000000000000000000000000000000000000000000000000000000
003b3300333330000033b3000000000000000000000000000000028cc82000000000000000000000000000000000000000000000000000000000000000000000
00bc300003bc33000003cb0000000000000000000000000000000288882000000000000000000000000000000000000000000000000000000000000000000000
0003300003bc33000003300000000000000000000000000000000288882000000000000000040000000040000000000000000000000000000000000000000000
00000000333330000000000000000000000000000000000000000028820000000000000000094000000490000000400000040000000000000000000000000000
0000000003bb000000000000000000000000000000000000000000288200000000000000000a90000004a0000004900000049000000000000000000000000000
000000003b00000000000000000000000000000000000000000000022000000000000000000aa0000009a000000aa0000009a000000000000000000000000000
0000700000000000000700000000000000000000000000000bb3000000003bb00000000000000000000000000000000000000000000000000000000000000000
000d7000777077000007d000000000000000000000000000b33500bbbb00533b0000000000000000000000000000000000000000000000000000000000000000
000dd000777dd770000dd0000000000000000000000000003355bbbbbbbb55330000000000000000000000000000000000000000000000000000000000000000
000c70000ddddcdd0007c000000000000000000000000000355bbb3333bbb5530000000000000000000000000000000000000000000000000000000000000000
000770000ddddcdd0007700000000000000000000000000035bb33555533bb530000000000000000000000000000000000000000000000000000000000000000
00000000777dd7700000000000000000000000000000000035bb35bbbb53bb530000000000000000000000000000000000000000000000000000000000000000
00000000777077000000000000000000000000000000000035bb35cccc53bb530000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000035bb357cc753bb530000000000000000000000000000000000000000000000000000000000000000
00070000009990000007000000000000000000000000000035bb33b77b33bb530000000000000000000000000000000000000000000000000000000000000000
00079000777700000097000000000000000000000000000035bb3bbbbbb3bb530000000000000000000000000000000000000000000000000000000000000000
00099000000990000099000000000000000000000000000035bb3b3bb3b3bb530000000000000000000000000000000000000000000000000000000000000000
009990000000c90000999000000000000000000000000000635bbb3333bbb5360000000000000000000000000000000000000000000000000000000000000000
00c90000000990000009c0000000000000000000000000006365bb3333bb56360000000000000000000000000000000000000000000000000000000000000000
00090000777700000009000000000000000000000000000063636036630636360000000000000000000000000000000000000000000000000000000000000000
0000000000999000000000000000000000000000000000006360d068860d06360000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000d0d0000dd0000d0d0000000000000000000000000000000000000000000000000000000000000000
__map__
4100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
7b0500003e6103161025610206102061020610216102061020610206101e6101f6101e6101e6101d6101d6101d6101d6101d6101c6101a6101a61019610196101961018610186101761016610166101661015610
970600002967000670006700067000670006700065000650006200062000620006200062000610006100061000610006100061000610006100061000610006100061000610006000060000600006000060000600
94010000225701e5601c5601955017550165401554013540125402950026500255000b50008500065000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000200000e0202f000290000a000150000a000130000a000010000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
