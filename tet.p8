pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
	gs={
		tick=0,
		maxtick=60,
		speed=1,
		
		width=10,
		height=20,
		
		backcolor=0,
		
		grid={},
		
		debug={
		 dbg={},
		 enabled=true
		},
	}
	
	init_grid()
end

function _update60()
 gs.debug.dbg={}
 
	gs.tick+=gs.speed
	if gs.tick>=gs.maxtick then
	 gs.tick=0
	 gametick()
	end
end

function _draw()
 cls(0)
 
 for x=0,gs.width-1 do
  for y=0,gs.height-1 do
   pset(x,y,gs.grid[x][y])
  end
 end
 
 if gs.debug.enabled then
  draw_debug()
 end
end

function draw_debug()
 for s in all(gs.debug.dbg) do
  print(s)
 end
end
-->8
function gametick()
 for x=gs.width-1,0,-1 do
  for y=gs.height-1,0,-1 do
   local cell=gs.grid[x][y]
   if cell>1 and y<gs.height-1 then
    gs.grid[x][y]=1
    gs.grid[x][y+1]=cell
   end
  end
 end
end
-->8
-- init

function init_grid()
 gs.grid={}
 
 for x=0,gs.width-1 do
  gs.grid[x]={}
  
  for y=0,gs.height-1 do
   gs.grid[x][y]=1
  end
 end
 
 gs.grid[5][0]=14
end
-->8
-- utils

function debug(s)
 add(gs.debug.dbg, s)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
