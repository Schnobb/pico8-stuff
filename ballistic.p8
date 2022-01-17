pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
 pi=3.1415927
 g=9.81
 scale=1/5
 fric=1.0
 
 ground=120
 cliff_h=30
 --cls()
 can=new_cannon(12,119-cliff_h,1,-2,4)
 can:rotate(30)
 
 force=60
 min_force=20
 max_force=100
 delta_force=(max_force/3)/60
 
 ready=true
 
 history={}
 max_history=60
 
 turn_speed=30/60
 
 show_range=false
 
 debug_time=false
 timer=0
 up_timer=0
end

function _update60()
 if btn(⬅️) then
  can:rotate(-turn_speed)
 end
 
 if btn(➡️) then
  can:rotate(turn_speed)
 end
 
 if btn(⬆️) then
  force=mid(min_force,force+delta_force,max_force)
 end
 
 if btn(⬇️) then
  force=mid(min_force,force-delta_force,max_force)
 end
 
 if btnp(❎) and ready then
  proj=new_proj(can.x+can.ox,can.y+can.oy,8)
  proj.dx=force*can.dir.x
  proj.dy=force*can.dir.y
  ready=false
  timer=0
  up_timer=0
 end
 
 if btnp(🅾️) then
  show_range=not show_range
 end

 if proj then
  if proj.dy<0 then
  	up_timer+=1
  end
  
  update_proj()
  timer+=1
 end
end

function _draw()
 cls()
 
 rectfill(0,ground-cliff_h,18,128,4)
 rectfill(0,ground,128,128,3)
 
 if proj then
  draw_proj()
 end
 
 draw_history()
 draw_cannon()
 
 if show_range then
  draw_range()
 end
 
 draw_force()
 
 if debug_time then
 	print(timer/60)
 	print(up_timer/60)
 end
end

function update_proj()
 proj.dx*=fric
 proj.dy+=g/60
 proj.x+=(proj.dx*scale)/60
 proj.y+=(proj.dy*scale)/60
 
 proj.x=proj.x%128
 if proj.y >= ground then
  proj.dy=0
  proj.y=ground-1
  ready=true
  
  if #history>=max_history then
   del(history,history[1])
  end
  
  add(history,vec2(proj.x,proj.y))
  proj=nil
 end
end

function draw_proj()
 pset(proj.x,proj.y,proj.col)
end

function draw_cannon()
 local can_end=can:get_end()
 line(can.x+can.ox,can.y+can.oy,can_end.x,can_end.y,3)
 spr(1,can.x-4,can.y-7)
 --pset(can.x+can.ox,can.y+can.oy,8)
 for i=0,6 do
  local dist=can.len*i*2
  local dot=can:get_end(dist)
  pset(dot.x,dot.y,6)
 end
end

function draw_history()
 for h in all(history) do
  pset(h.x,h.y,2)
 end
end

function draw_force()
 local cols={12,11,10,9,8}
 local col
 local w,h=2,80
 local x,y=5,15
 
 local fm=max_force-min_force
 fm=(force-min_force)/fm
 
 local col_idx=flr(#cols*fm)+1
 col_idx=min(#cols,col_idx)
 col=cols[col_idx]
 
 rect(x-2,y-2,x+w+2,y+h+2,col)
 local fy=h*(1-fm)
 rectfill(x,fy+y,x+w,y+h,col)
end

function draw_range()
 local ox,oy=-3,-7
 local h_diff=ground-can.y-1-can.oy
 local h_diff/=scale
 local range=get_range(force,can.dir,h_diff)
 local x=can.x+can.ox+range*scale
 local y=ground-1
 
 spr(2,(x+ox)%128,y+oy)
end
-->8
-- objects
function new_proj(x,y,col)
 return {
  x=x,
  y=y,
  col=col,
  dx=0,
  dy=0
 }
end

function new_cannon(x,y,ox,oy,len)
 return {
  x=x,
  y=y,
  ox=ox,
  oy=oy,
  len=len,
  dir=vec2(0,-1),
  
  get_end=function(self,dist)
   local len=dist or self.len
   local res=vec2(self.x+self.ox,self.y+self.oy)
   res.x+=self.dir.x*len
   res.y+=self.dir.y*len
   
   return res
  end,
  
  rotate=function(self,d)
   local temp=rot2d(self.dir,deg2rad(-d))
   if temp.y<0 then
    self.dir=temp
   end
  end
 }
end
-->8
-- utils
function vec2(x,y)
 return {
  x=x,
  y=y,
  norm=function(self)
   local l=len(self.x,self.y)
   self.x/=l
   self.y/=l
   return self
  end,
  mul=function(self,n)
   self.x*=n
   self.y*=n
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

function len(x,y)
 return sqrt(x^2+y^2)
end
-->8
-- ballistics

-- vel in meters/sec
-- dir is a direction vector
-- returns range in meters
function get_range(vel,dir,h_diff)
 h_diff=h_diff or 0
 local vxo=abs(dir.x)*vel
 local vyo=abs(dir.y)*vel
 
 --print(vxo..","..vyo)
 if debug_time then
  print(h_diff)
 end
 
 local t_rise=vyo/g
 local h=h_diff+vyo*t_rise-0.5*g*t_rise*t_rise
 local t_fall=sqrt(2*h/g)
 local t_flight=t_rise+t_fall
 
 if debug_time then
  print(t_rise)
  print(t_fall)
  print(t_flight)
  print(h)
  pset(63,ground-(h*scale),8)
 end
 
 return force*dir.x*t_flight
end

--function ball_func(vel,dir,x)
-- return x*tan()
--end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000000000a00a00a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000000b0000a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000bbbb0000aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000055500000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
