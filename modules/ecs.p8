pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--main
function _init()
 es={}
 add(es,make_player())
end

function _update()
 control_mvmt(es)
 move(es)
 animate(es)
end

function _draw()
 cls()
 draw_sprite(es)
end
-->8
--ecs
function system(ks,f)
 return function(es)
  for e in all(es) do
   if _has(e,ks) then
    f(e)
   end
  end
 end
end

function _has(e,ks)
 for k in all(ks) do
  if not e[k] then
   return false
  end
 end
 return true
end
-->8
--entities

function make_player(x,y,spr)
 local p={}
 create_pos(p,100,100)
 create_sprite(p,1)
 create_move(p,0,0)
 create_control(p)
 create_anim(p,{1,2,3},10)
 return p
end
-->8
--components
function create_pos(e,x,y)
 local p={
  x=x,
  y=y
 }
 e.pos=p
end

function create_move(e,dx,dy)
 local m={
  dx=dx,
  dy=dy
 }
 e.move=m
end

function create_control(e)
 local c={
  accept_input=true
 }
 e.control=c
end

function create_sprite(e,sp)
 local s={
  sp=sp
 }
 e.sprite=s
end

function create_anim(e,fs,r)
 local a={
  t=0,
  frames=fs,
  rate=r
 }
 e.animation=a
end
-->8
--systems
move=system({"pos","move"},
 function(e)
  local p=e.pos
  local m=e.move
  p.x+=m.dx
  p.y+=m.dy
 end
)
 
draw_sprite=system({"pos",
                    "sprite"},
 function(e)
  local p=e.pos
  local s=e.sprite
  spr(s.sp,p.x,p.y)
 end
)

control_mvmt=system({"control",
                     "move"},
 function(e)
  local c=e.control
  local m=e.move
  if not c.accept_input then
   return
  end
  m.dx,m.dy=0,0
  if (btn(0)) m.dx=-1
  if (btn(1)) m.dx=1
  if (btn(2)) m.dy=-1
  if (btn(3)) m.dy=1
 end
)

animate=system({"animation",
                "sprite"},
 function(e)
  local a=e.animation
  local s=e.sprite
  local i=0
  a.t+=1
  i=flr(a.t/a.rate%#a.frames)+1
  s.sp=a.frames[i]
 end
)
__gfx__
00000000006666000055550000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000065555600511115001000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700655115565110011510000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000651111565100001510000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000651111565100001510000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700655115565110011510000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000065555600511115001000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006666000055550000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
