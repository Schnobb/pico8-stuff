pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
 gs={
  fparts={},
  bparts={},
  bullets={},
  max_star_front=16,
  max_star_back=32,
  max_bullets=128,
  pl={},
  debug={
   show=true,
   dbg={}
  },
  tick=0,
  entities={},
  collisions={}
 }
 
 init_efx()
 init_starfield()
 init_player()
 init_rock(flr(rnd(128)),0,0,rnd(2)+1)
 init_rock(flr(rnd(128)),0,0,rnd(2)+1)
 init_rock(flr(rnd(128)),0,0,rnd(2)+1)
 init_rock(flr(rnd(128)),0,0,rnd(2)+1)
 music(0)
end

function _update60()
 gs.debug.dbg={}
 gs.collisions={}
 update_timers()
 handle_inputs()
 
 for s in all(gs.bparts) do
  s:update()
 end
 
 for b in all(gs.bullets) do
  b:update()
 end
 
 --gs.pl:update()
 for e in all(gs.entities) do
  e:update()
 end
 
 for s in all(gs.fparts) do
  s:update()
 end
 
 gs.tick+=1
end

function _draw()
 cls()
 for s in all(gs.bparts) do
  s:draw()
 end
 
 --gs.pl:draw()
 
 for e in all(gs.entities) do
  e:draw()
 end
 
 for b in all(gs.bullets) do
  b:draw()
 end
 
 for s in all(gs.fparts) do
  s:draw()
 end
 
 draw_hud()
 draw_shake()
 draw_flash()
 draw_strobe()
 
 draw_debug()
end

function handle_inputs()
 local pl=gs.pl
 local x,y=pl.x,pl.y
 
 if btn(➡️) then
  x+=pl.speed
 end
 
 if btn(⬅️) then
  x-=pl.speed
 end
 
 if btn(⬆️) then
  y-=pl.speed
 end 
 
 if btn(⬇️) then
  y+=pl.speed
 end
 
 pl.x=x%132
 pl.y=mid(18,y,127)
 
 if btn(❎) then
  gs.pl:shoot()
 end
 
 if btn(🅾️) then
 
 end
end

function draw_hud()
 rectfill(0,0,127,12,1)
 rectfill(1,1,126,11,0)
 
 draw_health()
end

function draw_health()
 print("life:",4,4,7)
 
 for i=0,gs.pl.health-1 do
  rectfill(25+i*3,4,25+i*3+1,8,8)
 end
end

function draw_shake()
 if efx.shake_t<=0 then
  camera(0,0)
  return
 end
 
 local max_amt=efx.shake_amt
 
 if efx.shake_att then
  max_amt*=efx.shake_t/efx.shake_ot
 end
 
 local ox,oy=rnd(max_amt*2)-max_amt,rnd(max_amt*2)-max_amt
 camera(ox,oy)
end

function draw_flash()
 if efx.flash_t<=0 then
  return
 end
 
 cls(efx.flash_col)
end

function draw_strobe()
 if efx.strobe_t<=0 then
  return
 end
 
 local coli=efx.strobe_t%#efx.strobe_cols
 coli+=1
 
 local col=efx.strobe_cols[coli]
 
 if col<0 then
  return
 end
 
 cls(col)
end

function draw_debug()
 if not gs.debug.show or #gs.debug.dbg<=0 then
  return
 end

 local w=0
 local h=#gs.debug.dbg*6
 
 for _,t in pairs(gs.debug.dbg) do
  if #t>w then
   w=#t
  end
 end
 
 w*=4

 rectfill(0,0,w+2,h+2,7)
 rectfill(1,1,w+1,h+1,0)
 
 cursor(2,2)
  
 for d in all(gs.debug.dbg) do
  print(d,7)
 end
 
 cursor()
end

function update_timers()
 if efx.shake_t>0 then
  efx.shake_t-=1
 end
 
 if efx.flash_t>0 then
  efx.flash_t-=1
 end
 
 if efx.strobe_t>0 then
  efx.strobe_t-=1
 end
end
-->8
-- objects

function new_star(x,y,size,speed,static)
 -- size is 1, 2, or 3
 return {
  x=x,
  y=y,
  size=mid(1,size,3),
  speed=speed,
  static=static,
  update=function(self)
   if self.static then
    return
   end
   
   self.y+=self.speed
   if self.y>127 then
    remove_part(self)
    
    if self.speed<1 then
     create_back_star()
    else
     create_star()
    end
   end
  end,
  draw=function(self)
   local x,y=self.x,self.y
   if self.size<2 then
    pset(x,y,5)
   elseif self.size<3 then
    pset(x,y,6)
   else
    line(x,y-1,x,y+1,5)
    line(x-1,y,x+1,y,5)
    pset(x,y,7)
   end
  end,
 }
end

function new_trail(x,y)
 return {
  x=x,
  y=y,
  size=2,
  max_size=2,
  speed=1,
  tick=0,
  max_tick=6,
  sp={7,8,9,10,11,12},
  --col=7+5*flr(rnd(2)), -- 7 or 12
  update=function(self)
   self.y+=self.speed
   self.size*=0.6
   self.size=mid(1,self.size,3)
   
   if self.tick>=self.max_tick then
    remove_part(self)
   end
   
   self.tick+=1
  end,
  draw=function(self)
   local col=7+5*flr(rnd(2))
   circfill(self.x,self.y,self.size,col)
   --local f=flr(#self.sp - (self.size/self.max_size)*#self.sp)-1
   --spr(self.sp[mid(1,f,#self.sp)],self.x-4,self.y-4)
  end
 }
end

function new_player(x,y)
 return {
  x=x,
  y=y,
  tick=0,
  speed=1,
  sp={1,2,3},
  anim_int=3,
  trail_int=1,
  trail_left=true,
  cooldown=0,
  max_cooldown=12,
  shoot_left=true,
  health=6,
  max_health=6,
  fuel=100,
  max_fuel=100,
  inv_t=0,
  r=4,
  update=function(self)
   self.tick+=1
   if self.tick%self.trail_int==0 then
    if self.trail_left then
     create_trail(self.x-2,self.y+6)
    else
     create_trail(self.x+1,self.y+6)
    end
    
    self.trail_left=not self.trail_left
   end
   
   if self.cooldown>0 then
    self.cooldown-=1
   end
   
   if self.inv_t>0 then
    self.inv_t-=1
   end
  end,
  draw=function(self)
   if self.inv_t>0 and self.tick%8<=3 then
    return
   end
  
   local frame=flr(self.tick/3)%#self.sp
   frame+=1
   spr(self.sp[frame],self.x-4,self.y-4)
   --pset(self.x,self.y,14)
  end,
  shoot=function(self)
   if self.cooldown>0 then
    return
   end
   
   if #gs.bullets>=gs.max_bullets then
    return
   end
   
   self.cooldown=self.max_cooldown
   
   local x=self.x
   if self.shoot_left then
    x-=3
   else
    x+=2
   end
   
   create_bullet(x,self.y-5,0,-4,11,1)
   sfx(0)
   sfx(1)
   sfx(2)
   
   self.shoot_left=not self.shoot_left
  end,
  damage=function(self,dmg)
   if self.inv_t>0 then
    return
   end
   
   self.health=max(0,self.health-dmg)
   flash(1,7)
   shake(8,4,true)
   sfx(5)
   sfx(6)
   sfx(7)
   
   if self.health<=0 then
    self:die()
    --return
   end
   
   self.inv_t=40
  end,
  die=function(self)
  
  end
 }
end

function new_bullet(x,y,sx,sy,col,dmg)
 return {
  x=x,
  y=y,
  sx=sx,
  sy=sy,
  ox=x,
  oy=y,
  col=col,
  dmg=dmg,
  tick=0,
  update=function(self)
   self.ox=self.x
   self.oy=self.y
   self.x=self.x+self.sx
   self.y=self.y+self.sy
   
   if self.y>136 or self.y<-8 or 
      self.x>136 or self.x<-8 then
    remove_bullet(self)
   end
   
   for e in all(gs.entities) do
    if e!=gs.pl then
     if collides(self.x,self.y,e.x,e.y,0.5,e.r) then
      remove_bullet(self)
      e:damage(self.dmg)
      shake(2,1,false)
      sfx(3)
      sfx(4)
     end
    end
   end
   
   self.tick+=1
  end,
  draw=function(self)
   if self.tick%2==0 then
    circfill(self.x,self.y,2,col)
   end
   
   line(self.ox,self.oy,self.x,self.y,self.col)
   
   local tx=flr((self.x-self.ox)/2)+self.ox
   local ty=flr((self.y-self.oy)/2)+self.oy
   
   line(tx,ty,self.x,self.y,7)
   circfill(self.x,self.y,1,7)
  end  
 } 
end

function new_rock(x,y,sx,sy)
 return {
  x=x,
  y=y,
  sx=sx,
  sy=sy,
  etype=enemy_type.rock,
  tick=0,
  health=4,
  flash_t=0,
  sp=flr(rnd(3))+4,
  r=4,
  dmg=4,
  update=function(self)
   local x,y=self.x,self.y
   x=(self.sx+x)%132
   y=(self.sy+y)
   
   if y>128 then
    self:die()
    return
   end
   
   self.x=x
   self.y=y
   
   for e in all(gs.entities) do
    if e!=self and not contains(gs.collisions,{e,self}) then
     if e.etype!=enemy_type.rock then
      if collides(self.x,self.y,e.x,e.y,self.r,e.r) then
       --debug("yes")
       add(gs.collisions,{self,e})
       e:damage(self.dmg)
       --self:die()
      end
     end
    end
   end
   
   if self.flash_t>0 then
    self.flash_t-=1
   end
  end,
  draw=function(self)
   if self.flash_t>0 and self.tick%2==0 then
    return
   end
   
   --debug("sprite: "..self.sp)
   --debug("pos: "..self.x..","..self.y)
   
   spr(self.sp,self.x-4,self.y-4)
  end,
  damage=function(self,dmg)
   self.health=max(0,self.health-dmg)
   self.flash_t=6   
   
   if self.health<=0 then
    self:die()
   end
  end,
  die=function(self)
   del(gs.entities,self)
   init_rock(flr(rnd(128)),0,0,flr(rnd(2)+1))
  end
 }
end
-->8
-- inits

enemy_type={
 rock=0
}

function create_star()
 local x=flr(rnd(128))
 local y=rnd(128)*-1
 local size=flr(rnd(3))+1
 local speed=flr(rnd(10)+1)
 
 add(gs.fparts,new_star(x,y,size,speed,false))
end

function create_back_star()
 local x=flr(rnd(128))
 local y=flr(rnd(128+64))-64
 local size=flr(rnd(2))+1
 local speed=rnd(1)*0.05
 
 add(gs.bparts,new_star(x,y,size,speed,false))
end

function create_trail(x,y)
 add(gs.bparts,new_trail(x,y))
end

function create_bullet(x,y,sx,sy,col,dmg)
 add(gs.bullets,new_bullet(x,y,sx,sy,col,dmg))
end

function remove_part(part)
 del(gs.fparts,part)
 del(gs.bparts,part)
end

function remove_bullet(bullet)
 del(gs.bullets,bullet)
end

function init_efx()
 efx={
  flash_t=0,
  flash_col=0,
  shake_t=0,
  shake_ot=0,
  shake_amt=0,
  shake_att=false,
  strobe_t=0,
  strobe_cols={},
 }
end

function init_starfield()
 for i=0,gs.max_star_front do
  create_star()
 end
 
 for i=0,gs.max_star_back do
  create_back_star()
 end
end

function init_player()
 gs.pl=new_player(64,64)
 add(gs.entities,gs.pl)
end

function init_rock(x,y,sx,sy)
 add(gs.entities,new_rock(x,y,sx,sy))
end
-->8
-- utils

function collides(x1,y1,x2,y2,r1,r2)
 return x1-r1<=x2+r2 and
        x1+r1>=x2-r2 and
        y1-r1<=y2+r2 and
        y1+r1>=y2-r2
end

function debug(txt)
 add(gs.debug.dbg,txt)
end

function printc(txt,col,y)
 local x=64-#txt*2
 print(txt,x,y,col)
end

function printb(txt,col1,col2,x,y)
 local dirx={0,1,1,1,0,-1,-1,-1}
 local diry={-1,-1,0,1,1,1,0,-1}
 for i=1,8 do
  print(txt,x+dirx[i],y+diry[i],col2)
 end
 print(txt,x,y,col1)
end

function printcb(txt,col1,col2,y)
 local x=64-(#txt/2)*4
 printb(txt,col1,col2,x,y)
end

function format_time(ticks)
 local m,s
 s=flr(ticks/60)
 m=flr(s/60)
 
 s=s%60
 
 if m>99 then
  return "99:59"
 end
 
 return lpad(m,"0",2)..":"..lpad(s,"0",2)
end

function lpad(txt,pad,len)
 local res=""..txt
 
 while #res<len do
  res=pad..res
 end
 
 return res
end

function contains(tbl,v)
 for _,t in pairs(tbl) do
  if t==v then
   return true
  end
 end
 
 return false
end

function flash(len,col)
 efx.flash_t=len
 efx.flash_col=col
end

function strobe(len,cols)
 efx.strobe_t=len
 efx.strobe_cols=cols
end

function shake(len,amt,att)
 efx.shake_t=len
 efx.shake_ot=len
 efx.shake_amt=amt
 efx.shake_att=att or false
end
__gfx__
000000000b0880b00b0880b00b0880b000555000005556500005500000c77c00000cc000000cc000000c00000000000000000000000000000000000000000000
000000000b0880b00b0880b00b0880b00567655556666665005765600c7777c000c77c0000077000000700000007000000070000000000000000000000000000
00700700086cc680086cc680086cc6805567766655566765566666760c7777c000c77c0000c77c00000070000000700000007000000000000000000000000000
0007700008611680086116800861168065655666566666655666665500c77c00000cc000000cc000000cc0000000c00000000000000000000000000000000000
00077000266886622668866226688662566576655657666656576665000cc0000000000000000000000000000000000000000000000000000000000000000000
00700700265885622658856226588562566666655655675656556665000000000000000000000000000000000000000000000000000000000000000000000000
000000008570075885c00c5885c00c58555666505666655055666650000000000000000000000000000000000000000000000000000000000000000000000000
0000000080c00c088070070880c00c08056555500055560000555550000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000315602b560235501a530155200f5100a51006510035100051000500085000650004500025000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
00010000316302e6202a62027620216101e6101b61014610116100e61008610056100161000600026000060003600026000160000600056000460004600036000060003600026000160001600006000060000600
001000000c72300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703
00020000206501b640146300a62000610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600001c75318700107000270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000266302a6502264020630246302a6502d64016610006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002c7502a750277501c7500d750067500075000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010700001075300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000c6450c7430c743000000c6450c7040c743000000c6450c7430c743000000c6450c7040c743000000c6450c7430c743000000c6450c7040c743000000c6450c7430c743000000c6450c7040c74300000
010c0000101320e1310b132151000713204132101321a1000b1320913213100041321013110131171000913007130041301c1001a1000b132151000713210100101300e1310b130151001310004130071300e130
010c00001c5551c5551c5551c55500500005001a5501a55000500005001a5551a55517551175501755517555175500050017550005001a5551a5551a5551a555175551755517555175551a5511a5551755117545
010c0000105431054310543105430e5030e5030e5030e5030e5430e5430e5430e5430b5030b5030b5030b5030b5430b5430b5430b5430e5030e5030e5030e5030b5430b5430b5430b54313503135031350313503
010c00000414007100091400b1000e140101000414007100091400b1000e140101000414007100091400b1000e140101410414007100091420b1420e142101000414007141091400b1000e140101000b14007140
010c0000175551755517555175551a5011a5011a5551a555155551555515505155451c5511c5551c5551c55513505135051355513545155051550515555155551f5551f5051f5551f5551c5511c5551c5051c505
__music__
01 14151617
00 14151617
00 14181917
02 14181917

