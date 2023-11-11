pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
title='physics simulation'
 
function _init()
 a=verlet_obj(64,64)
 a.acc=vec2(-0.5,0)
 g=vec2(0.0,0.2)
 min_bounds=vec2(0,0)
 max_bounds=vec2(127,127)
 path={}
end

function _update()
 apply_force(a,g)
 integrate(a)
 constrain(a,
           min_bounds,
           max_bounds)
 add(path,vec2(a.cur.x,a.cur.y))
end

function _draw()
 cls(0)
 print_cent(title,3,7)
 for p in all(path) do
  pset(p.x,p.y,6)
 end
 circfill(a.cur.x,a.cur.y,3,8)
 rect(0,0,127,127,7)
end

function constrain(obj,bmin,bmax)
 local y=obj.cur.y
 local by=bmax.y
 if y>by then
  y=by
  dy=obj.cur.y-obj.old.y
  obj.old.y=y+0.6*dy
  obj.cur.y=y
 end
end

function round(val)
 return flr(val+0.5)
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
 local v=vec2_sub(obj.cur,
                  obj.old)
 local nxt=vec2_add(obj.cur,v)
 nxt=vec2_add(nxt,obj.acc)
 obj.old=obj.cur
 obj.cur=nxt
 obj.acc=vec2(0,0)
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
-->8
--text
function print_cent(txt,y,col)
 local offset=64-#txt*4/2
 print(txt,offset,y,col)
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
