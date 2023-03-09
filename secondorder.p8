pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
 pi=3.141592
 global_t=0.05

 back_col=1
 line_col=8
 secord_col=11
 t=0
 
 funcs = {
  sinus,
  constant,
  linear,
  square,
  move_sin
 }
 
 func_idx=4
 
 sec_const_delta=0.01
 
 sec_f=1
 sec_z=1
 sec_r=2
 
 show_secord=true
 lines=true
end

function _update60()
 t+=0.01
 
 if btnp(➡️) then
  --move_func(1)
 end
 
 if btnp(⬅️) then
  --move_func(-1)
 end
 
 if btnp(🅾️) then
  --show_secord=not show_secord
 end
 
 if btn(⬆️) then
  sec_f+=sec_const_delta
 end
 
 if btn(⬇️) then
  sec_f-=sec_const_delta
 end
 
 if btn(➡️) then
  sec_z+=sec_const_delta
 end
 
 if btn(⬅️) then
  sec_z-=sec_const_delta
 end
 
 if btn(❎) then
  sec_r+=sec_const_delta
 end
 
 if btn(🅾️) then
  sec_r-=sec_const_delta
 end
end

function _draw()
 cls(back_col)
 
 local y=0
 local yd=0
 
 local pxs={}
 local pys={}
 
 for screen_x=0,128 do
  local x=screen_x/128
  local prev_x=(screen_x-1)/128
  local func=funcs[func_idx]
  local input=func(x,t)
  --point(screen_x, 64-input*64, line_col, )
  add(pxs,64-input*64)
  
  local output=secondorder(func,x,prev_x,y,yd,t)
  --print(x..": ["..output.y..","..output.yd.."]")
  --point(screen_x,64-output.y*64,secord_col)
  add(pys,64-output.y*64)
  y=output.y
  yd=output.yd
 end
 
 if lines then
  for i=2,#pxs do  
   line(i-2,pxs[i-1],i-1,pxs[i],line_col)
  end
  
  if show_secord then
   for i=2,#pys do
    line(i-2,pys[i-1],i-1,pys[i],secord_col)
   end
  end
 else
  for i=0,#pxs-1 do
   pset(i,pxs[i+1],line_col)
  end
  
  if show_secord then
   for i=0,#pys-1 do
    pset(i,pys[i+1],secord_col)
   end
  end
 end
 
 color(7)
 print("func_idx: "..func_idx)
 print("f: "..sec_f)
 print("z: "..sec_z)
 print("r: "..sec_r)
end

function move_func(amt) 
 local idx=func_idx-1
 idx+=amt
 idx=idx%#funcs
 func_idx=idx+1
end
-->8
-- functions

function sinus(x,t)
 return sin(x)/2
end

function constant(x,t)
 return 0
end

function linear(x,t)
 return x
end

function square(x,t)
 return x%(1/2)>(1/4) and 0.5 or -0.5
end

function move_sin(x,t)
 return sin(x/2+t)*0.75
end
-->8
-- secondorder
function secondorder(func,in_x,prev_in_x,pos_prev,vel_prev,tf)
 local k1=sec_z / (pi*sec_f)
 local k2=1/((2*pi*sec_f)*(2*pi*sec_f))
 local k3=sec_r*sec_z/(2*pi*sec_f)
 
 local t=global_t
 -- make sure k2 is stable
 --k2=max(k2,1.1*(t*t/4+t*k1/2))
 k2=max(k2,t*t/2+t*k1/2,t*k1)
 local x=func(in_x,tf)
 local xd=(x-func(prev_in_x,tf))/t
 --print(x..": "..xd.." ["..in_x.."]")
 --local xd=0
 
 --if in_x>0 then
 -- xd=(x-func(in_x-1,tf))/t
 --end
 
 local pos=pos_prev+t*vel_prev
 local vel=vel_prev+t*(x+k3*xd-pos-k1*vel_prev)/k2

 return {y=pos,yd=vel}
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
