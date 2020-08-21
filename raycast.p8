pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function _init()
 pi=3.14159
 gs={
  dither=true,
  debug=true,
  db={},
  db_px={},
  
  back=0,
  bounds={
   p1=vec2(0,0),
   p2=vec2(127,127)
  },
  
  rendersize=vec2(128,128),
  mode="3d",
  drawdist=16,
  persp_correction=true
 }
 
 pl={
  pos=vec2(43,59),
  acc=0.5,
  col=11,
  face=vec2(-1,0),
  rotspeed=0.04,
  fov=90,
  dist_to_screen=0.5,
  
  rotate=function(self,direction)
   -- -1: clockwise, 1: counter-clockwise
   self.face=rot2d(self.face,self.rotspeed*direction)
  end,
  
  move=function(self,direction)
   -- -1:back, 1:forward
   local p=vec2(
    self.pos.x+self.face.x*self.acc*direction,
    self.pos.y+self.face.y*self.acc*direction
   )
   if collides(p.x,p.y,0)<1 then
    self.pos=p
   end
  end
 }
 
 cols={
  {vert=8,horz=2},
  {vert=9,horz=4},
  {vert=10,horz=9},
  {vert=11,horz=3},
  {vert=12,horz=1},
  ceiling=0,
  floor=5
 }
 
 cols[0]={vert=0,horz=0}
 loadmap()
 
 init_colors()
end

function _update60()
 gs.db={}
 gs.db_px={}
 
 handle_inputs()
end

function _draw()
 if gs.mode=="2d" then
  render_2d()
 elseif gs.mode=="3d" then
  render_3d()
 end 
 
 --db("pc: "..tostr(gs.persp_correction))
 db(stat(1))
 db(stat(7).."/"..stat(8))
 
 if gs.debug then
	 print_db(7)
	 draw_db_px(11)
 end
end
-->8
-- update
function handle_inputs()
 if btn(⬅️) then
  pl:rotate(1)
 end
 
 if btn(➡️) then
  pl:rotate(-1)
 end
 
 if btn(⬆️) then
  pl:move(1)
 end
 
 if btn(⬇️) then
  pl:move(-1)
 end
 
 if btnp(❎) then
  if gs.mode=="2d" then
   gs.mode="3d"
  elseif gs.mode=="3d" then
   gs.mode="2d"
  end
 end
 
 if btnp(🅾️) then
  --gs.persp_correction=not gs.persp_correction
 end
end
-->8
-- draw
function render_2d()
 cls(gs.back)
 map(0,0)
 
 --drawcasts(pl)
 drawcamplane(pl)
 drawface(pl)
 drawfov(pl)
 --drawgrid(6)
 pset(pl.pos.x,pl.pos.y,pl.col)
 
 --db("pos: ["..pl.pos.x..","..pl.pos.y.."]")
 --db("face: ["..pl.face.x..","..pl.face.y.."]")
end

function render_3d()
 cls(gs.back)
 fillp(0)
 rectfill(0,0,128,63,cols.ceiling) 
 rectfill(0,64,128,128,cols.floor)
  
 --local r=deg2rad(pl.fov/2)
 local steps=gs.rendersize.x
 --local rstep=-r*2/steps
 --local f=rot2d(pl.face,r)
 local p1=vec2(pl.pos.x,pl.pos.y)
 local h=gs.rendersize.y
 local p1x,p1y=p1.x,p1.y
 local pfx,pfy=pl.face.x,pl.face.y
 local drawdist=gs.drawdist
 local blib=0
 
 -- raycast direction and screen division method is heavily inspired from
 -- https://www.gamedev.net/forums/topic/635066-2d-ray-casting-problems-dont-align-correctly/
 
 -- k is the opposite side of a right triangle made by the
 -- length of the player facing vector (1 since it's normalized)
 -- and the fov/2.
 --
 -- k .-k
 -- __.__
 -- \ | /
 --  \|/
 --   .
 local k=-tanr(deg2rad(pl.fov/2))
 
 -- look_vector (lv) is player rotation vector modified by the dist_to_screen.
 local lv=vec2(pl.face.x*pl.dist_to_screen,pl.face.y*pl.dist_to_screen)
 
 -- screenv is the screen vector and starts perpendicular to our look vector. for a vector
 -- <a,b> a 90deg ccw rotation can be achieved with <b,-a>
 local screenv=vec2(lv.y,-lv.x)
 
 -- divide screenv equally between 0 and gs.rendersize.x.
 local inc=vec2(-2*k*screenv.x/steps,-2*k*screenv.y/steps)
 
 -- move screenv forward by pl.dist_to_screen and stretch it so it fits between
 -- -fov/2 and fov/2
 local screenv=vec2(lv.x+k*screenv.x,lv.y+k*screenv.y)

 for x=0,steps do
  -- find point #x on screenv, this will be the ray's direction vector.
  -- This won't be normalized because it will actually provide perspective correction
  -- due to the fact the vector's length will increase as we get farther from the middle point.
  local f=vec2(pl.face.x+screenv.x+x*inc.x,pl.face.y+screenv.y+x*inc.y)
  local cast=raycast(p1x,p1y,f.x,f.y)
  local d=cast.d
  local col=cast.col
  
  if d<drawdist then
	  local lh=h/d
	  
	  y1=mid(0,-lh\2+h\2,h)
	  y2=mid(0,lh\2+h\2,h)
	  
	  local c=cast.side and col.horz or col.vert
   --local ass=cast.side and 8 or 8
   
   if gs.dither then
    c=hcolor(c,1-d/drawdist)
   end
	  line(x,y1,x,y2,c)
    --line(x,y1,x,y2,ass+blib)
  end

  blib=(blib+1)%8
 end
end
-->8
-- util
-- linear algebra stuff
function vec2(x,y)
 return {
  x=x,
  y=y,
  norm=function(self)
   local l=len(self.x,self.y)
   self.x/=l
   self.y/=l
   return self
  end
 }
end

function rot2d(vec,r)
 return vec2(
  vec.x*cosr(r)-vec.y*sinr(r),
  vec.x*sinr(r)+vec.y*cosr(r)
 )
end

function rot(x,y,r)
 return x*cosr(r)-y*sinr(r),x*sinr(r)+y*cosr(r)
end

function rad2deg(r)
 return r*180/pi
end

function deg2rad(d)
 return d*pi/180
end

function sinr(r)
 return sin(r/(2*pi))
end

function cosr(r)
 return cos(r/(2*pi))
end

function tanr(r)
 return sinr(r)/cosr(r)
end

--function acos(x)
-- local negate = (x < 0 and 1.0 or 0.0)
-- x = abs(x);
-- local ret = -0.0187293;
-- ret *= x;
-- ret += 0.0742610;
-- ret *= x;
-- ret -= 0.2121144;
-- ret *= x;
-- ret += 1.5707288;
-- ret *= sqrt(1.0-x);
-- ret -= 2 * negate * ret;
-- return negate * 3.14159265358979 + ret;
--end

function acosr(x)
 return atan2(x,-sqrt(1-x*x))*2*pi
end

function dot(x1,y1,x2,y2)
 return x1*x2+y1*y2
end

function r_between_vec(x1,y1,x2,y2)
 return acosr(dot(x1,y1,x2,y2)/(len(x1,y1)*len(x2,y2)))
end

function d_between_vec(x1,y1,x2,y2)
 return rad2deg(r_between_vec(x1,y1,x2,y2))
end

function len(x,y)
 return sqrt(x^2+y^2)
end

-- collision stuff
function is_inside(x,y,b1,b2)
 -- inclusive, p is point being checked
 -- b1 is top left, b2 is bottom right
 -- all of them vec2
 
 return x>=b1.x and x<=b2.x and y>=b1.y and y<=b2.y
end

function colsn(x,y)
 local tile=maptest[y]
 
 if tile!=nil then
  tile=tile[x]
  if tile!=nil then
   return tile
  end
 end
 
 return 0
end

function collides(x,y,flag)
 local tile=mget(x\8,y\8)
 if fget(tile,flag) then
  return tile
 else
  return 0
 end
end

-- adapted from everyone's favorite raycast tutorial
-- https://lodev.org/cgtutor/raycasting.html
function raycast(px,py,fx,fy)
 local nx,ny=px/8,py/8
 local mx,my=flr(nx),flr(ny)
 local tx,ty=0,0
 local tile=0
 local side=false
 local d=0
 local dx,dy=abs(1/fx),abs(1/fy)
 
 if fx<0 then
  tx=(nx-mx)*dx
 else
  tx=(mx+1-nx)*dx
 end
 
 if fy<0 then
  ty=(ny-my)*dy
 else
  ty=(my+1-ny)*dy
 end
 
 -- slows cast down a bit too much, just make sure there's no holes
 -- in the walls and it won't crash.
 --while is_inside(mx*8,my*8,gs.bounds.p1,gs.bounds.p2) do
 while true do
  if tx<ty then
   tx+=dx
   mx+=sgn(fx)
   side=true
  else
   ty+=dy
   my+=sgn(fy)
   side=false
  end
  
  tile=colsn(mx,my)
  if tile>0 then break end
 end
 
 if side then
  d=(mx-nx+(1-sgn(fx))/2)/fx
 else
  d=(my-ny+(1-sgn(fy))/2)/fy
 end
  
 nx=px+fx*d*8
 ny=py+fy*d*8
 
 return {
  p=vec2(nx,ny),
  tile=tile,
  side=side,
  d=d,
  col=cols[tile]
 }
end

function smoothstep(x1,x2,w)
	w=mid(w,0,1)
	w=(w*w*(3-2*w))
	return (x2-x1)*w+x1
end

function smootherstep(x1,x2,w)
	w=mid(w,0,1)
	w=w*w*w*(w*(w*6-15)+10)
	return (x2-x1)*w+x1
end
-->8
-- debug stuff
function print_db(col)
 cursor(0,0)
 color(col or 7)
 
 for s in all(gs.db) do
  print(s)
 end
end

function drawface(e)
 local x1,y1=e.pos.x,e.pos.y
 local p=raycast(e.pos.x,e.pos.y,e.face.x,e.face.y).p
 
 line(x1,y1,p.x,p.y,8)
 pset(p.x,p.y,12)
end

function drawfov(e)
 local fov=deg2rad(e.fov/2)
 local left=rot2d(e.face,fov)
 local right=rot2d(e.face,-fov)
 local lres=raycast(e.pos.x,e.pos.y,left.x,left.y)
 local rres=raycast(e.pos.x,e.pos.y,right.x,right.y)
 local pl,pr=lres.p,rres.p
 
 --db("right: ["..right.x..","..right.y.."]")
 
 line(e.pos.x,e.pos.y,pl.x,pl.y,10)
 line(e.pos.x,e.pos.y,pr.x,pr.y,10)
 
 --db("ld: "..lres.d)
 --db("rd: "..rres.d)
 
 --db("left: ["..left.x..","..left.y.."]")
 --db("right: ["..right.x..","..right.y.."]")
 
 drawperphit(pl,rot2d(e.face,pi),lres.d)
 drawperphit(pr,rot2d(e.face,pi),rres.d)
 
 pset(pl.x,pl.y,12)
 pset(pr.x,pr.y,12)
end

function drawcasts(e)
 local r=deg2rad(e.fov/2)
 local steps=gs.rendersize.x
 local rstep=-r*2/steps
 local f=rot2d(e.face,r)
 local p1=vec2(e.pos.x,e.pos.y)
 local p1x,p1y=p1.x,p1.y
 local pfx,pfy=pl.face.x,pl.face.y
 
 for i=0,steps do
  local p2=raycast(p1x,p1y,f.x,f.y).p
  line(p1x,p1y,p2.x,p2.y,13)
  pset(p2.x,p2.y,15)
  f=rot2d(f,rstep)
 end
end

function drawgrid(col)
 for x=8,128,8 do
  line(x,0,x,128,col)
 end
 
 for y=8,128,8 do
	 line(0,y,128,y,col)
 end
end

function drawcamplane(e)
 local fl,fr=rot2d(e.face,pi/2),rot2d(e.face,-pi/2)

 local x1,y1=e.pos.x+fl.x*128,e.pos.y+fl.y*128
 local x2,y2=e.pos.x+fr.x*128,e.pos.y+fr.y*128
 line(x1,y1,x2,y2,5)
end

function drawperphit(p,f,d)
 local x1,y1=p.x,p.y
 local x2,y2=p.x+f.x*d*8,p.y+f.y*d*8
 line(x1,y1,x2,y2,14)
end

function db(s)
 add(gs.db,s)
end

function db_px(p)
 add(gs.db_px,p)
end

function draw_db_px(col)
 for p in all(gs.db_px) do
  pset(p.x,p.y,col)
 end
end
-->8
-- test
function loadmap()
 maptest={}
 for y=0,127 do
  maptest[y]={}
  for x=0,127 do
   maptest[y][x]=mget(x,y)
  end
 end
end
-->8
--colors

function init_colors(res)
 -- enable color fill patterns
 poke(0x5f34,1)
 
 -- res: resolution of brightness gradient, default 128
 res=res or 128
 
 local bright={
  0b0.1000000000000000,
  0b0.1000000000100000,
  0b0.1000000010100000,
  0b0.1010000010100000,
  0b0.1010010010100000,
  0b0.1010010010100001,
  0b0.1010010010100101,
  0b0.1010010110100101,
  0b0.1110010110100101,
  0b0.1110010110110101,
  0b0.1110010111110101,
  0b0.1111010111110101,
  0b0.1111010111110111,
  0b0.1111110111110111,
  0b0.1111110111111111,
  0b0.1111111111111111
 }
 
 local hues={
  {0},
  {0,1,1,12},
  {0,1,2},
  {0,1,3},
  {0,1,2,4},
  {0,1,5},
  {0,1,5,6},
  {0,1,5,6,7},
  {0,1,2,8},
  {0,1,2,4,9,9,10},
  {0,1,2,4,9,10,7},
  {0,1,3,11},
  {0,1,13,12,7},
  {0,1,13},
  {0,1,8,14},
  {0,1,4,14,15}
 }
 
	colors={res=res}
	
	for i=0,15 do
 	local h=hues[i+1]
 	local hi=1
 	local hstep=res\(#h-1)
		colors[i]={}
			
		for j=0,res do
		 local b=smoothstep(0,#bright,(j%hstep)/hstep)
		 if j>0 and j%hstep==0 then 
		  hi=hi+1
		 end
		 
		 -- setting first bit of the color
		 -- this enables the fill pattern stuff
		 local cleft=bor(0x1000,h[hi])
		 local cright=h[min(hi+1,#h)]
		 
		 colors[i][j]=bor(cleft,shl(cright,4))
		 colors[i][j]+=bright[flr(b)+1]
		end
	end
end

function hcolor(base,light)
	local l=light*colors.res
	return colors[base][flr(l)]
end
__gfx__
000000008888888899999999aaaaaaaabbbbbbbbcccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000008888888899999999aaaaaaaabbbbbbbbcccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
007007008888888899999999aaaaaaaabbbbbbbbcccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
000770008888888899999999aaaaaaaabbbbbbbbcccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
000770008888888899999999aaaaaaaabbbbbbbbcccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
007007008888888899999999aaaaaaaabbbbbbbbcccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000008888888899999999aaaaaaaabbbbbbbbcccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000008888888899999999aaaaaaaabbbbbbbbcccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000005555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000005666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000005666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000005666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000056555565000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000056566565000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000056566565000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000056555565000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000056566565000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000056566565000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000055666655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000055666655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000565666656500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000565555556500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000565666656500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000565666656500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000565666656500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000565666656500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000565666656500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000556666665500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005656666665650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005655555555650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005655666655650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005656666665650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
85558885558585558885555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
85558585585585558585555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
88858585585588858585555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
85858585585585858585555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
88858885855588858885555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000000000000000000000000000aab0000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000aaaaa08a0000000000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000000000000000aaaaa0000008a0000000000000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000000000000aaaaa0000000000800a000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000aaaaa000000000000008000a000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000aaaaaa00000000000000000008000a000000000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000aaaaa00000000000000000000000080000a000000000000000000000000000000000000000000000000000000055555555
5555555500000000000000000aaaaa0000000000000000000000000000800000a000000000000000000000000000000000000000000000000000000055555555
55555555000000000000aaaaa0000000000000000000000000000000008000000a00000000000000000000000000000000000000000000000000000055555555
555555550000000aaaaa000000000000000000000000000000000000080000000a00000000000000000000000000000000000000000000000000000055555555
5555555500aaaaa00000000000000000000000000000000000000000800000000a00000000000000000000000000000000000000000000000000000055555555
5555555caa0000000000000000000000000000000000000000000008000000000a00000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000008000000000a00000000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000000000000000000800000000000a0000000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000000000000000008000000000000a0000000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000000000000000008000000000000a0000000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000000000000000080000000000000a0000000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000000000000000800000000000000a0000000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000000000000000800000000000000a0000000000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000000000000000080000000000000000a000000000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000000000000000800000000000000000a000000000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000000000000000800000000000000000a000000000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000000000000008000000000000000000a000000000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000000000000080000000000000000000a000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000800000000000000000000a00000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000008000000000000000000000a00000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000080000000000000000000000a00000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000080000000000000000000000a00000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000800000000000000000000000a00000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000000080000000000000000000000000a0000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000000800000000000000000000000000a0000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000000800000000000000000000000000a0000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000008000000000000000000000000000a0000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000080000000000000000000000000000a0000000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000000800000000000000000000000000000a000000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000008000000000000000000000000000000a000000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000080000000000000000000000000000000a000000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000080000000000000000000000000000000a000000000000000000000000000000000000000000000000055555555
5555555500000000000000000000000000000800000000000000000000000000000000a000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000080000000000000000000000000000000000a00000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000080000000000000000000000000000000000a00000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000800000000000000000000000000000000000a00000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000008000000000000000000000000000000000000a00000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000008000000000000000000000000000000000000a00000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000080000000000000000000000000000000000000a00000000000000000000000000000000000000000000000055555555
555555550000000000000000000000008000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000055555555
555555550000000000000000000000008000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000055555555
555555550000000000000000000000080000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000055555555
555555550000000000000000000000800000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000055555555
555555550000000000000000000008000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000055555555
5555555500000000000000000000080000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000055555555
5555555500000000000000000000800000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000055555555
5555555500000000000000000008000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000055555555
5555555500000000000000000008000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000055555555
5555555500000000000000000080000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000055555555
55555555000000000000000008000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000055555555
55555555000000000000000008000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000055555555
555555555555555555555555c5555555555555555555555555555555555555555555555555c55555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555

__gff__
0001010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000303030303000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000002020000000300000403000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000002020005000300030303000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000005000300030000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000030000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000303030000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000005050500000004040000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000005050000000004040000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
