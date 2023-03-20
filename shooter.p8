pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- main
-- todo
-- enemy types
-- weapon types
function _init()
 t=0
 time_of_last_shot=t
 b_cooldwn=15
 dt=1/30
 ship=make_ship()
 enemies={}
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

-- bullet
function make_bullet(x,y)
 local b={}
 b.x=x
 b.y=y
 b.dy=-100
 b.hitbox={
  x0=3,
  y0=0,
  x1=4,
  y1=2
 }
 add(bullets,b)
end

function update_bullet(b)
 b.y+=b.dy*dt
 if b.y<0 then
  del(bullets,b)
 end
 missle_trail(b.x+4,b.y+10)
end

function draw_bullet(b)
 spr(10,b.x,b.y)
end

--particles
function make_particle(x,y)
 local p={}
 p.x=x
 p.y=y
 p.dx=dx
 p.dy=dy
 p.ddy=0
 p.lifetime=30
 p.age=0
 p.rad_start=0
 p.rad_final=0
 p.col_tbl={7}
 return p
end

function update_particle(p)
 if p.age>p.lifetime then
  del(particles,p)
 else
  p.age+=1
  p.x+=p.dx
  p.y+=p.dy
  p.dy+=p.ddy
 end
end

function draw_particle(p)
 local n=#p.col_tbl
 local i=flr(p.age/p.lifetime*n)+1
 local diff=p.rad_final-p.rad_start
 local r=p.rad_start+p.age/p.lifetime*diff
 circfill(p.x,p.y,r,p.col_tbl[i])
end

--particle effects
function missle_trail(x,y)
 local p={}
 p.x=x+rnd(4)-2
 p.y=y+rnd(4)-2
 p.dx=rnd(0.6)-0.3
 p.dy=-0.3
 p.ddy=0.1
 p.lifetime=5+rnd(30)
 p.age=0
 p.rad_start=2
 p.rad_final=0
 p.col_tbl={7,7,10,9,8,4,4,4,7,5,5,5}
 add(particles,p)
end

function muzzel_flash(x,y)
 local p={}
 p.x=x
 p.y=y
 p.dx=0
 p.dy=0
 p.ddy=0
 p.lifetime=4
 p.age=0
 p.rad_start=6
 p.rad_final=0
 p.col_tbl={7}
 add(particles,p)
end

function missle_explosion(x,y)
 for i=1,20 do
  local p={}
  p.x=x
  p.y=y
  p.dx=rnd(2)-1
  p.dy=rnd(2)-1
  p.ddy=0
  p.lifetime=20
  p.age=0
  p.rad_start=5
  p.rad_final=1
  p.col_tbl={10,8,2,1}
 add(particles,p)
 end
end

function explosion_flash(x,y)
 local p={}
 p.x=x
 p.y=y
 p.dx=0
 p.dy=0
 p.ddy=0
 p.lifetime=4
 p.age=0
 p.rad_start=12
 p.rad_final=0
 p.col_tbl={7}
 add(particles,p)
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

--collision
function draw_hitbox(o)
 local h=o.hitbox
 rect(o.x+h.x0,o.y+h.y0,o.x+h.x1,o.y+h.y1,8)
end

function has_collided(a,b)
 local ha=a.hitbox
 local hb=b.hitbox
 if a.y+ha.y0>b.y+hb.y1 then return false end
 if b.y+hb.y0>a.y+ha.y1 then return false end
 if a.x+ha.x1<b.x+hb.x0 then return false end
 if b.x+hb.x1<a.x+ha.x0 then return false end
 return true
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
 enemies={}
 ship.x=60
 ship.dx=0
 ship.dir="straight"
 lives=3
 add_intercepter(64,20)
end

function update_play()
 update_ship()
 foreach(enemies,update_enemy)
 foreach(bullets,update_bullet)
 foreach(particles,update_particle)
 foreach(stars,update_star)
 if lives<=0 then
  init_gameover()
 end
 for b in all(bullets) do
  for e in all(enemies) do
   if has_collided(b,e) then
    del(enemies,e)
    del(bullets,b)
    missle_explosion(e.x+4,e.y+2)
    explosion_flash(e.x+4,e.y+2)
   end
  end
 end
end

function draw_play()
 cls()
 foreach(stars,draw_star)
 draw_ship()
 foreach(particles,draw_particle)
 foreach(bullets,draw_bullet)
 foreach(enemies,draw_enemy)
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
-->8
-- enemies
function add_intercepter(x,y)
 local e={}
 e.x=x
 e.y=y
 e.hp=10
 e.score=10
 e.sprite=65
 e.drift_params=slow_drift()
 e.hitbox={
  x0=1,
  y0=0,
  x1=6,
  y1=3
 }
 add(enemies,e)
end

function update_enemy(e)
 if e.hp<=0 then
  del(enemies,e)
 end
 drift(e)
end

function draw_enemy(e)
 local frames={89,90,91,92}
 local ticks_per_frame=3
 local i=flr(t/ticks_per_frame%#frames)+1
 spr(frames[i],e.x,e.y-7)
 spr(e.sprite,e.x,e.y)
end

function drift(e)
 local d=e.drift_params
 e.x+=d.ax*sin(t/d.tx+d.px)
 e.y+=d.ay*sin(t/d.ty+d.py)
end

function slow_drift()
 local params={
  ax=0.1,tx=90,px=0,
  ay=0.05,ty=60,py=0
 }
 return params
end
-->8
--ship
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
 if pressed(4) or pressed(5) then
  if t-time_of_last_shot>b_cooldwn then
   make_bullet(ship.x-4,ship.y)
   make_bullet(ship.x+4,ship.y)

   muzzel_flash(ship.x+1,ship.y-1)
   time_of_last_shot=t  
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
__gfx__
000000000200080008000080008000200000000000008000000090000000a0000000a0000000a000000280000000000000000000000000000000000000000000
00000000020008000800008000800020008080000000800000008000000090000000a00000009000000670000000000000000000000000000000000000000000
00700700020002808200002808200020088088000000200000008000000000000000900000008000000670000000000000000000000000000000000000000000
000770000207c2808207c0280827c020088888000000000000000000000000000000000000000000006007000000000000000000000000000000000000000000
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
00010000150501505014050140501405019050130501e0501e0501e0501d0501f0501d050120501c050120501c0501c050120501c0501c0501c0500e0500e0500d05000000000000000000000000000000000000
