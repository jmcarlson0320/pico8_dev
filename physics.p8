pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
title='physics simulation'
 
function _init()
 mouse.init()
 init_physics()
end

function _update()
 if btnp(4) then
  x,y=mouse.pos()
  add_object(x,y)
  if #objects > 1 then
   local a = objects[#objects]
   local b = objects[#objects - 1]
   add_link(a, b)
  end
  if #objects % 3 == 0 then
   local a = objects[#objects]
   local b = objects[#objects - 2]
   add_link(a, b)
  end
 end
 update_physics()
end

function _draw()
 cls(0)
 mouse.draw()
 print_cent(title,3,7)
 draw_physics()
end
-->8
-- physics
objects={}
links={}
grav = 0
floor = 0

function init_physics()
	grav=vec2(0.0,0.2)
 floor=127
end

function update_physics()
 for obj in all(objects) do
  apply_force(obj,grav)
  integrate(obj)
  constrain_flr(obj,floor)
 end

 for link in all(links) do
  constrain_link(link)
 end
end

function draw_physics()
 -- draw links
 for link in all(links) do
  local x0 = link.obj1.cur.x
  local y0 = link.obj1.cur.y
  local x1 = link.obj2.cur.x
  local y1 = link.obj2.cur.y
  line(x0, y0, x1, y1, 7)
 end

 -- draw objects
 for obj in all(objects) do
  local x=obj.cur.x
  local y=obj.cur.y
  circfill(x,y,2,11)
 end
end

function add_object(x,y)
 local o=verlet_obj(x,y)
 add(objects,o)
end

function add_link(a,b)
 l={}
 l.obj1=a
 l.obj2=b
 l.length=vec2_dist(a.cur,b.cur)
 add(links,l)
end
-->8
--verlet
function verlet_obj(x,y)
 local obj={}
 obj.old=vec2(x,y)
 obj.cur=vec2(x,y)
 obj.acc=vec2(0,0)
 return obj
end

function apply_force(obj,f)
 obj.acc=vec2_add(obj.acc,f)
end

function integrate(obj)
 local v=vec2_sub(obj.cur,obj.old)
 local nxt=vec2_add(obj.cur,v)
 nxt=vec2_add(nxt,obj.acc)
 obj.old=obj.cur
 obj.cur=nxt
 obj.acc=vec2(0,0)
end

--constraints
function constrain_flr(obj,fl)
 local y=obj.cur.y
 if y>fl then
  y=fl
  dy=obj.cur.y-obj.old.y
  obj.old.y=y+0.6*dy
  obj.cur.y=y
 end
end

function constrain_link(link)
 local a=link.obj1.cur
 local b=link.obj2.cur
 local l=link.length
 local d=vec2_dist(a,b)
 local delta=(d-l)/2
 local to=vec2_sub(a,b)
 to=vec2_nrm(to)
 mv_a=vec2_mul(to,(-delta))
 mv_b=vec2_mul(to,delta)
 link.obj1.cur = vec2_add(link.obj1.cur, mv_a)
 link.obj2.cur = vec2_add(link.obj2.cur, mv_b)
end	

function constrain_collision(obj1, obj2)

end
-->8
--vec2
function vec2(x,y)
 return {x=x,y=y}
end

function vec2_mag(v)
 return sqrt(v.x*v.x+v.y*v.y)
end

function vec2_magsqr(v)
 return v.x*v.x+v.y*v.y
end

function vec2_ang(v)
 return atan2(v.x,v.y)
end

function vec2_add(a,b)
 local v={}
 v.x=a.x+b.x
 v.y=a.y+b.y
 return v
end

function vec2_sub(a,b)
 local v={}
 v.x=a.x-b.x
 v.y=a.y-b.y
 return v
end

function vec2_mul(a,s)
 local v={}
 v.x=a.x*s
 v.y=a.y*s
 return v
end

function vec2_div(a,s)
 local v={}
 v.x=a.x/s
 v.y=a.y/s
 return v
end

function vec2_dot(a,b)
 return a.x*b.x+a.y*b.y
end

function vec2_nrm(v)
 local l=vec2_mag(v)
 return vec2_div(v,l)
end

function vec2_min(a,b)
 local v={}
 v.x=min(a.x,b.x)
 v.y=min(a.y,b.y)
 return v
end

function vec2_max(a,b)
 local v={}
 v.x=max(a.x,b.x)
 v.y=max(a.y,b.y)
 return v
end

function vec2_dist(a,b)
 local to=vec2_sub(b,a)
 return vec2_mag(to)
end
-->8
--utils
function print_cent(txt,y,col)
 local offset=64-#txt*4/2
 print(txt,offset,y,col)
end

--mouse
mouse={}

function mouse.init()
 poke(0x5f2d,1)
end

function mouse.pos()
	local x=stat(32)-1
	local y=stat(33)-1
	return x,y
end

function mouse.button()
 return stat(34)
end

function mouse.draw()
 x,y=mouse.pos()
 pset(x,y,11)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
