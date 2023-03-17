pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- main
-- todo
-- enemies
-- collision
-- weapon types

function _init()
 t=0
 last_shot_time=t
 b_cooldwn=4
 dt=1/30
 ship=make_ship()
 stars=make_starfield(40)
 star_colors={1,5}
 particles={}
 bullets={}
 lives=3
 score=10000
 init_title()
end

function _update()
 t+=1
 update_btn_state()
 _upd()
end

function _draw()
 _drw()
end


-- player ship
function make_ship()
 local s={}
 s.x=60
 s.y=112
 s.dx=0
 s.dir="straight"
 s.thrust=1000
 s.decel=200
 s.maxspd=75
 s.sprites={
  left=17,
  straight=18,
  right=19
 }
 return s
end

function update_ship()
 --- apply thrust
 if btn(0) then
  ship.dir="left"
  ship.dx-=ship.thrust*dt
 end
 if btn(1) then
  ship.dir="right"
  ship.dx+=ship.thrust*dt
 end

 -- limit max speed
 ship.dx=mid(
  -ship.maxspd,
  ship.dx,
  ship.maxspd
 )
 
 -- decellerate when not turning
 if not btn(0) and
    not btn(1) then
  ship.dir="straight"
  if ship.dx<-10 then
   ship.dx+=ship.decel*dt
  elseif ship.dx>10 then
   ship.dx-=ship.decel*dt
  else
   ship.dx=0
  end
 end
  
 -- change position
 ship.x+=ship.dx*dt
 
 -- clamp to screen
 ship.x=mid(0,ship.x,120)
 
 -- fire bullet
 if btn(4) or btn(5) then
  if t-last_shot_time>b_cooldwn then
   make_bullet(ship.x+1,ship.y+8)
   make_bullet(ship.x+6,ship.y+8)
   muzzel_flash(ship.x+1,ship.y-1)
   muzzel_flash(ship.x+6,ship.y-1)
   last_shot_time=t  
  end 
 end
end

function draw_ship()
 local sp=ship.sprites[ship.dir]
 spr(sp,ship.x,ship.y)

 -- adjust position of engine sprite
 local left_offset=0
 local right_offset=0
 if ship.dir=="right" then
  left_offset=1
 elseif ship.dir=="left" then
  right_offset=-1
 end
 
 -- engine sprite
 local frames={6,7,8,9}
 local ticks_per_frame=3
 local i=flr(t/ticks_per_frame%#frames)+1
 spr(frames[i],ship.x-3+left_offset,ship.y+8)
 spr(frames[i],ship.x+2+right_offset,ship.y+8)
end


-- bullet
function make_bullet(x,y)
 local b={}
 b.x=x
 b.y=y
 b.dy=-200
 add(bullets,b)
end

function update_bullet(b)
 b.y+=b.dy*dt
 if b.y<0 then
  del(bullets,b)
 end
 sparkle_trail(b.x,b.y+4)
end

function draw_bullet(b)
 spr(10,b.x-4,b.y-8)
end


-- particle system
function add_particle(
 x,y,spread,
 radius,
 shrink,grow,
 dx,dy,
 life_min,life_max,
 colors
)
 local p={}
 p.x=x+rnd(2*spread)-spread
 p.y=y+rnd(2*spread)-spread
 p.rad=radius
 p.shrink=shrink
 p.grow=grow
 p.dx=dx
 p.dy=dy
 p.lifetime=life_min+rnd(life_max-life_min)
 p.age=0
 p.col_tbl=colors
 add(particles,p)
end

function update_particle(p)
 if p.age>p.lifetime then
  del(particles,p)
 else
  p.age+=1
  p.x+=p.dx
  p.y+=p.dy
 end
end

function draw_particle(p)
 local num_col=#p.col_tbl
 local i=flr(p.age/p.lifetime*num_col)+1
 local radius=p.rad-flr(p.age/p.lifetime*p.rad)-1
 circfill(p.x,p.y,radius,p.col_tbl[i])
end


-- particle effects
function sparkle_trail(x,y)
 add_particle(
  x,y,2,
  2,
  false,false,
  rnd(0.6)-0.3,-0.3,
  5,35,
  {7,10,9,8,2,2,2,2,7,2,2,2}
 )
end

function muzzel_flash(x,y)
 add_particle(
  x,y,0,
  6,
  true,false,
  0,0,
  3,3,
  {7}
 )
end


-- starfield
function make_starfield(n)
 local starfield={}
 for i=1,n do
  local s={}
  s.x=rnd(128)
  s.y=rnd(128)
  s.layer=flr(rnd(2))+1
  s.dy=s.layer
  add(starfield,s)
 end
 return starfield
end

function update_star(s)
 s.y+=s.dy
 if s.y>127 then s.y=0 end
end

function draw_star(s)
 local prev_y_pos=s.y-s.dy
 local col=star_colors[s.layer]
 line(s.x,s.y,s.x,prev_y_pos,col)
end


-- ui
function draw_ui(x,y)
 for i=1,lives do
  local offset=(i-1)*8
  spr(20,x+0+offset,y+0)
 end
 print(score,x+50,y,7)
end


-- user input
prev_btn_state={
 [0]=false,
 [1]=false,
 [2]=false,
 [3]=false,
 [4]=false,
 [5]=false
}

cur_btn_state={
 [0]=false,
 [1]=false,
 [2]=false,
 [3]=false,
 [4]=false,
 [5]=false
}

function update_btn_state()
 for b=0,6 do
  prev_btn_state[b]=cur_btn_state[b]
  cur_btn_state[b]=btn(b)
 end
end

function pressed(b)
 return not prev_btn_state[b] 
        and cur_btn_state[b]
end

function released(b)
 return prev_btn_state[b] and
    not cur_btn_state[b]
end
-->8
-- title
function init_title()
 _upd=update_title
 _drw=draw_title
end

function update_title()
 if btnp(4) or btnp(5) then
  init_play()
 end
 foreach(stars,update_star)

end

function draw_title()
 cls(0)
 foreach(stars,draw_star)
 print("title screen\n",50,50,7)
 print("press ❎ or 🅾️ to start",30,58,7)
end
-->8
-- play
function init_play()
 _upd=update_play
 _drw=draw_play
 particles={}
 bullets={}
 ship.x=60
 ship.dx=0
 ship.dir="straight"
 lives=3
end

function update_play()
 update_ship()
 foreach(bullets,update_bullet)
 foreach(particles,update_particle)
 foreach(stars,update_star)
 if btnp(⬆️) then lives-=1 end
 if lives<=0 then
  init_gameover()
 end
end

function draw_play()
 cls()
 foreach(stars,draw_star)
 draw_ship()
 foreach(particles,draw_particle)
 foreach(bullets,draw_bullet)
 draw_ui(4,4)
end
-->8
-- gameover
function init_gameover()
 _upd=update_gameover
 _drw=draw_gameover
end

function update_gameover()
 if btnp(4) or btnp(5) then
  init_title()
 end
 foreach(stars,update_star)
end

function draw_gameover()
 cls(0)
 foreach(stars,draw_star)
 print("gameover\n",50,50,7)
 print("press ❎ or 🅾️ to continue",20,58,7)
end
__gfx__
000000000200080008000080008000200000000000008000000090000000a0000000a0000000a000000280000000000000000000000000000000000000000000
00000000020008000800008000800020008080000000800000008000000090000000a00000009000000560000000000000000000000000000000000000000000
00700700020002808200002808200020088088000000200000008000000000000000900000008000000560000000000000000000000000000000000000000000
000770000207c2808207c0280827c020088888000000000000000000000000000000000000000000005006000000000000000000000000000000000000000000
00077000022822808288882808228220008080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700020228808802208808822020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000020008000800008000800020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005000d000d0000d000d00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
