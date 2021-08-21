pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- main

function _init()
 states={
  init=0,
  main=1,
  stash=2,
  travel=3
 }
 
 gs={
  drugs={},
  day=0,
  cash=200,
  debt=650,
  interest=16.5,
  bank=0,
  stash={},
  stash_size=100,
  state=states.main,
  areas={},
  area=1,
  hideout_area=1,
  index=0,
  tick=0,
  buy_list={}
 }
 
 gs.drugs=init_drugs()
 gs.stash=init_stash()
 gs.areas=init_areas()
end

function _update60()
 gs.tick+=1
 if gs.state==states.main then
  update_main()
 elseif gs.state==states.stash then
  update_stash()
 end
end

function _draw()
 cls(1)
 draw_status()
 
 if gs.state==states.main then
  draw_main()
 elseif gs.state==states.stash then
  draw_stash()
 end
end
-->8
-- obj

function new_drug(id, name, low, high, unit)
 return {
  id=id,
  name=name,
  low=low,
  high=high,
  unit=unit or "g"
 }
end

function new_stash_entry(drug, amt)
 return {
  drug=drug,
  amt=amt
 }
end

function new_deal(drug,price)
 return {
  drug=drug,
  price=price
 }
end

function new_area(id, name, likes, dislikes)
 local area= {
  id=id,
  name=name,
  likes=likes or {},
  dislikes=dislikes or {},
  
  deals={},
  
  refresh_deals=function(self)
   self.deals={}
   
   for d in all(gs.drugs) do
    local chance=0.4
    local pmod=1
    
    if find(self.likes,d.id)>0 then
     pmod=1.1
     chance=0.75
    elseif find(self.dislikes,d.id)>0 then
     chance=0.15
     pmod=1-0.13
    end
    
    if rnd(1)<chance then
     local price=d.low
     price+=rnd(d.high*pmod-price)
     add(self.deals, new_deal(d,flr(price)))
    end
   end
  end
 }
 
 area:refresh_deals()
 return area
end

function new_buy_entry(id,amt,price)
 return{
  id=id,
  amt=amt,
  price=price
 }
end
-->8
-- init

function init_drugs()
 local drugs = {}
 drugs[1]=new_drug(1, "weed", 4, 16)
 drugs[2]=new_drug(2, "amp", 8, 25)
 drugs[3]=new_drug(3, "oxy", 12, 36, "pill")
 drugs[4]=new_drug(4, "mdma", 6, 18, "pill")
 drugs[5]=new_drug(5, "crack", 45, 90)
 drugs[6]=new_drug(6, "coke", 100, 250)
 drugs[7]=new_drug(7, "hero", 125, 225)
 drugs[8]=new_drug(8, "meth", 60, 130)
 drugs[9]=new_drug(9, "lsd", 5, 20, "tab")
 drugs[10]=new_drug(10, "shroom", 5, 20)
 drugs[11]=new_drug(11, "keth", 200, 450)
 drugs[12]=new_drug(12, "pcp", 20, 45)
 return drugs
end

function init_stash()
 local stash={}
 
 for d in all(gs.drugs) do
  print(d.id.." "..d.name)
  stash[d.id] = new_stash_entry(d, 0)
 end
 
 return stash
end

function init_areas()
 local areas={}
 
 add(areas, new_area(1, "gettho"))
 add(areas, new_area(2, "slums"))
 add(areas, new_area(3, "industrial district"))
 add(areas, new_area(4, "downtown"))
 add(areas, new_area(5, "suburbs"))
 add(areas, new_area(6, "the hills"))
 add(areas, new_area(7, "beach"))
 add(areas, new_area(8, "countryside"))
 add(areas, new_area(9, "clubs"))
 
 return areas
end
-->8
-- draw

function draw_status()
 rectfill(0,0,128,10,0)
 cursor(0,0,6)
 print("cash         debt          stash")
 
 cursor(0,1*6,3)
 print(format_cash(gs.cash))
 
 cursor(13*4,1*6,8)
 print(format_cash(gs.debt))
 
 local inv=get_stash_size().."/"..gs.stash_size
 cursor(32*4-#inv*4,1*6,7)
 print(inv)
 
 cursor(0,3*6,7)
end

function draw_main()
 local area=gs.areas[gs.area]
 color(12)
 print(area.name)
 print("")
 
 local start_cur=get_cursor()
 local selected=false
 local last_i=0
 
 for i,d in ipairs(area.deals) do
  local cur=get_cursor()
  local price=format_cash(d.price)
  selected=i==gs.index+1
  
  color(selected and 11 or 3)
  print("  "..d.drug.name..":")

  cursor(72-#price*4,cur.y,selected and 10 or 9)
  print(price)
  cursor(0,cur.y+6)
  last_i=i
 end
 
 selected=gs.index==last_i
 color(selected and 7 or 6)
 print("  confirm")
 
 local cur_spr=1
 if gs.tick%60>30 then
  cur_spr=2
 end
 spr(cur_spr,2,start_cur.y+gs.index*6)
 
 color()
end

function draw_stash()
 local empty=true
 
 for d in all(gs.stash) do
  if d.amt>0 then
   empty=false
   print(" "..d.drug.name..": "..d.amt..d.drug.unit)
  end
 end
 
 if empty then
  print(" -empty-")
 end
 
 print("")
 color(6)
 print("press 🅾️ to close stash")
 color()
end
-->8
-- utils

function get_stash_size()
 local res=0
 for d in all(gs.stash) do
  res += d.amt
 end
 return res
end

function choice(lst)
 return lst[flr(rnd(#lst))+1]
end

function find(lst,e)
 for i,t in ipairs(lst) do
  if e==t then
   return i
  end
 end
 
 return -1
end

function format_cash(cash)
 local int=flr(cash)
 local dec=flr(100*(cash-int))
 local dec_str=""
 
 if dec<10 then 
  dec_str="0"..dec
 else 
  dec_str=""..dec
 end
 
 return int.."."..dec_str.."$"
end

function get_cursor()
 return {
  x=peek(0x5f26),
  y=peek(0x5f27)
 }
end

function change_state(state)
 gs.state=state
 gs.index=0
 gs.tick=0
 gs.buy_list={}
end
-->8
-- logic

function update_main()
 local area=gs.areas[gs.area]
 if btnp(🅾️) then
  change_state(states.stash)
 end
 
 if btnp(⬆️) then
  gs.index=(gs.index-1)%(#area.deals+1)
 end
 
 if btnp(⬇️) then
  gs.index=(gs.index+1)%(#area.deals+1)
 end
end

function update_stash()
 if btnp(🅾️) then
  change_state(states.main)
 end
end
__gfx__
00000000600000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000760000000760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700776000000776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000760000000760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000600000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
