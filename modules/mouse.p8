pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
mouse = {
  init = function()
    poke(0x5f2d, 1)
  end,

  -- return int:x, int:y, onscreen:bool
  pos = function()
    local x,y = stat(32)-1,stat(33)-1
    return stat(32)-1,stat(33)-1
  end,

  -- return int:button [0..4]
  -- 0 .. no button
  -- 1 .. left
  -- 2 .. right
  -- 4 .. middle
  button = function()
    return stat(34)
  end,
}

function _init()
  mouse.init()
end

function _draw()
  cls()
  local x,y = mouse.pos()
  local b = mouse.button()
  print("x:"..x.."\ny:"..y.."\nb:"..b)
  spr(0,x-1,y-1)
end
__gfx__
07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
78700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
