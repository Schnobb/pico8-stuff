pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function _init()
 pi=3.1415
 
 startx=63
 starty=63
 
 dist_tresh=2
 
 stars={}
 starcnt=64
 
 for i=0,starcnt do
  local s=star():init()
  add(stars,s)
 end
end

function _update60()
 for _,s in pairs(stars) do
  s.x+=s.face.x*s.spd
  s.y+=s.face.y*s.spd
  
  s.spd+=0.02
  
  if s.x>127 or s.x<0 or s.y>127 or s.y<0 then
   s:init()
  end
 end
end

function _draw()
 cls(0)
 for _,s in pairs(stars) do
  local distx=startx-s.x
  local disty=starty-s.y
  local dist=sqrt(distx*distx+disty*disty)
  
  if dist>dist_tresh then
   pset(s.x,s.y,s.c)
  end
 end
end

function star()
 return {
  x=0,
  y=0,
  face={},
  spd=0,
  c=0,
  
  init=function(self)
   local ang=rnd(361)
   local r=deg2rad(ang)
   self.x=startx
   self.y=starty
   self.face=rot2d(vec2(0,1),r)
   self.spd=rnd(2)
   self.c=choice({7,7,7,7,7,7,6,6,6})
   return self
  end
 }
end

function choice(arr)
 local r=flr(rnd(#arr)+1)
 return arr[r]
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

-- gui stuff
function px_len(str)
 return #str*4
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
