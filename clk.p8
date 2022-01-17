pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
 btns={}
 
 init_mouse()
 
 add(btns,new_btn(8,8,"blablablab",beep))
end

function _update60()
 update_mouse()
 
 for _,b in pairs(btns) do
  b:update()
 end
end

function _draw()
 cls()
 
 for _,b in pairs(btns) do
  b:draw()
 end
 
 draw_mouse()
end

function beep()
 sfx(0)
end
-->8
-- inits
function init_mouse()
 mouse={
  x=0,
  y=0,
  lclick=false,
  rclick=false,
  pos_updated=false,
  lclick_updated=false,
  rclick_updated=false,
  enabled=true,
  downx=0,
  downy=0
 }
 
 poke(0x5f2d,0x1)
 update_mouse()
end
-->8
-- updates
function update_mouse()
 local x,y=stat(32),stat(33)
 local lclick=(stat(34) & 0x1)>0
 local rclick=(stat(34) & 0x2)>0
 
 mouse.pos_updated=false
 mouse.lclick_updated=false
 mouse.rclick_updated=false
 
 if mouse.x!=x or mouse.y!=y then
  mouse.pos_updated=true
  mouse.x=x
  mouse.y=y
 end
 
 if mouse.lclick!=lclick then
  mouse.updated=true
  mouse.lclick_updated=true
  mouse.lclick=lclick
 end
 
 if mouse.rclick!=rclick then
  mouse.updated=true
  mouse.rclick_updated=true
  mouse.rclick=rclick
 end
 
 if mouse.click_updated and (rclick or lclick) then
  mouse.downx=x
  mouse.downy=y
 end
end
-->8
-- draws
function draw_mouse()
 local x,y=mouse.x,mouse.y
 local click=mouse.lclick or mouse.rclick
 local sp=click and 2 or 1
 
 spr(sp,x,y)
 --pset(x,y,8)
end
-->8
-- objects
function new_btn(x,y,label,on_click)
 return {
  x=x,
  y=y,
  w=#label*4+4,
  h=10,
  label=label,
  on_click=on_click,
  
  draw=function(self)
   local col1,col2=6,5
   
   if is_inside(mouse.x,mouse.y,self.x,self.y,self.w,self.h) then
    col1=12
    col2=13
    
    if mouse.lclick then
     col1=13
     col2=12
    end
   end
   
   rect(self.x,self.y,self.x+self.w,self.y+self.h,col1)
   rect(self.x+1,self.y+1,self.x+self.w-1,self.y+self.h-1,col2)
   rectfill(self.x+2,self.y+2,self.x+self.w-2,self.y+self.h-2,col1)
   print(self.label,self.x+3,self.y+3,col2)
  end,
  
  update=function(self)
   if is_inside(mouse.x,mouse.y,self.x,self.y,self.w,self.h) then
    if not mouse.lclick and mouse.lclick_updated then
     self.on_click()
    end
   end
  end
 }
end
-->8
-- utils
function is_inside(px,py,x,y,w,h)
 return px>=x and px<=x+w
    and py>=y and py<=y+h
end
__gfx__
00000000010000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000171000002620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700177100002662000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000177710002666200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000177771002666620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700177110002662200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011710000226200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000270502c05030050300502d050110500505000050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
