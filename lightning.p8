pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function _init()
 pi=3.1415
 gs={
  trand=rnd(),
  light_seed=rnd(),
  light_t=0,
  max_light_t=20,
  light_max_depth=8,
  light_max_split=16
 }
end

function _update60()
 if btnp(❎) and gs.light_t<=0 then
  gs.light_t=gs.max_light_t
  sfx(2)
  gs.light_seed=rnd(-1)
 else
  gs.light_t-=1
 end
end

function _draw()
 local backcol=0
 
 if gs.light_t>0 then
  if gs.light_t>0.75*gs.max_light_t then
   cls(7)
   return
  end
  
  if rnd()>0.25 then backcol=7 end
 end
 
 cls(backcol)
 
 if gs.light_t>0 then
  drawlight(63,-32,gs.light_seed,backcol<7)
 end
 
 --print(gs.light_seed)
end

function drawlight(x,y,seed,inv)
 gs.trand=rnd(-1)*time()*stat(2)
 srand(seed)
 
 local col=inv and 7 or 0
 local pts={}
 --add(pts,vec2(x,y))
 local pt=vec2(x,y)
 local l=light_part(pt)
 
 local c=light_recursive(pts,pt,0,gs.light_max_depth,0)
 add(l.childs,c)
 add(pts,l)
 l.id=#pts
 
 --for i,l in pairs(pts) do
 -- print(i..": "..l.id..",["..l.pt.x..","..l.pt.y.."],"..#l.childs)
 --end
 
 for _,l in pairs(pts) do
  if #l.childs>0 then
   for _,cidx in pairs(l.childs) do
    local c=pts[cidx]
    if c then
     line(l.pt.x,l.pt.y,c.pt.x,c.pt.y,col)
    end
   end
  end
 end
 
 srand(gs.trand)
end

function light_recursive(pts,par,depth,max_depth,cursplit)
 local len,ang=flr(rnd(27)+5),flr(rnd(120)-60)
 local pt=light_next(par.x,par.y,len,ang)
 local l=light_part(pt)
 
 if depth<max_depth then
  local num=1
  if rnd()>0.75 and cursplit<=gs.light_max_split then 
   num+=1
   cursplit+=1
  end
  
  for i=1,num do
   local c=light_recursive(pts,pt,depth+1,max_depth,cursplit)
   add(l.childs,c.id)
  end
 end
 
 add(pts,l)
 l.id=#pts
 
 return l
end

function light_next(x,y,len,ang)
 local r=vec2(0,1)
 r=rot2d(r,deg2rad(ang))
 return vec2(x+r.x*len,y+r.y*len)
end

function light_part(pt)
 return {
  id=-1,
  pt=pt,
  childs={}
 }
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

function len(x,y)
 return sqrt(x^2+y^2)
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

-- maths stuff
function decimal(x)
 return x-flr(x)
end

function lerp(x1,x2,w)
 return (1-w)*x1+w*x2
end

function smoothstep(x1,x2,w)
	w=mid(w,0,1)
	w=(w*w*(3-2*w))
	--w=-2*w^3+3*w^2
	return (x2-x1)*w+x1
end

function smootherstep(x1,x2,w)
	w=mid(w,0,1)
	--w=w*w*w*(10+(-15+6*w)*w)
	w=w*w*w*(w*(w*6-15)+10)
	--w=6*w^5-15*w^4+10*w^3
	return (x2-x1)*w+x1
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000900001c6201c6211d61021611276302c630376301e6311b6201862017620176211961018610136100f6100c6100b6100a6100961009610096100a6100b6100761004610036100261001610016100161101600
