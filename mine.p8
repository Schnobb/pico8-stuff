pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
 gs={
  tiles={},
  cur_x=0,
  cur_y=0,
  cur_timer=0,
  cur_max_timer=60,
  mine_cnt=30,
  ind_col={},
  mines_laid=false,
  mines={},
  game_over=false,
  w=16,
  h=14,
  ticks=0,
  flags=0,
  back_col=0,
  flagged_tiles={},
  won=false,
  hidden_tiles=0
 }
 
 gs_debug={
  reveal=false,
  show=true,
  dbg={}
 }
 
 init_tiles(gs.w,gs.h)
 init_ind_col()
end

function _update60()
 gs_debug.dbg={}
 handle_inputs()
 
 if not gs.game_over and not gs.won then
  eval_state()
  gs.ticks+=1
 end
 --debug("test")
end

function _draw()
 cls(gs.back_col)
 
 for x,c in pairs(gs.tiles) do
  for y,t in pairs(c) do
   local s,s2=nil,nil
   local draw_ind=false
   
   if t.state == tile_state.revealed then
    if t.mine then
     s=4
    else
     s=3
     draw_ind=true
    end
   elseif t.state == tile_state.flagged then
				s=1
				s2=2
   else
    s=1
   end
   
   local p=t2p(x,y)
   
   if s!=nil then
    spr(s,p.x,p.y)
   end
   
   if s2!=nil then
    spr(s2,p.x,p.y)
   end
   
   if draw_ind then
    if t.mine_cnt!=nil and t.mine_cnt>0 then
     local col=gs.ind_col[t.mine_cnt]
     local p=t2p(x,y)
     print(t.mine_cnt,p.x+3,p.y+2,col)
    end
   end
  end
 end
 
 if gs.game_over then
  draw_game_over()
 elseif gs.won then
  draw_won()
 else
  draw_cursor(gs.cur_x, gs.cur_y)
 end
 
 draw_hud() 
 draw_debug()
end

function draw_cursor(x,y) 
 local col=12
 
 if gs.cur_timer<gs.cur_max_timer/2 then
  col=13
 end
 
 if gs.cur_timer<=0 then
  gs.cur_timer=gs.cur_max_timer
 else
  gs.cur_timer-=1
 end
 
 local p1=t2p(x,y)
 local p2=t2p(x+1,y+1)
 
 rect(p1.x+1,p1.y+1,p2.x-1,p2.y-1,col)
end

function handle_inputs()
 if gs.game_over or gs.won then
  if btnp(❎) then
   _init()
  end
  
  return
 end

 if btnp(⬆️) then
  gs.cur_y-=1
 end
 
 if btnp(⬇️) then
  gs.cur_y+=1
 end
 
 if btnp(➡️) then
  gs.cur_x+=1
 end
 
 if btnp(⬅️) then
  gs.cur_x-=1
 end
 
 gs.cur_x=gs.cur_x%gs.w
 gs.cur_y=gs.cur_y%gs.h
 
 if btnp(❎) then
  if not gs.mines_laid then
   init_mines(gs.mine_cnt,gs.cur_x,gs.cur_y)
  end
  
  reveal_tile(gs.cur_x, gs.cur_y)
 end
 
 if btnp(🅾️) then
  flag_tile(gs.cur_x, gs.cur_y)
  --won()
 end
end

function draw_debug()
 if gs_debug.show then
  color()
  cursor()
  
  for d in all(gs_debug.dbg) do
   print(d)
  end
 end
end

function draw_game_over()
 -- rectangle
 local y0=128/2-6*2-3
 local y1=128/2+6*2+3
 --rectfill(0,y0,127,y1,0)
 
 -- "game over"
 printcb("game over",8,0,128/2-7)
 
 -- flashing "press ❎ to restart"
 local col=5
 
 if gs.cur_timer<gs.cur_max_timer/2 then
  col=7
 end
 
 if gs.cur_timer<=0 then
  gs.cur_timer=gs.cur_max_timer
 else
  gs.cur_timer-=1
 end
 
 printcb("press ❎ to restart",col,0,128/2+6)
end

function draw_hud()
 -- time
 local t=format_time(gs.ticks)
 print(t,3,2,7)
 
 -- flags
 spr(2,128-9,0)
 local t=gs.flags.."/"..gs.mine_cnt
 print(t,128-#t*4-9,2,7)
end

function draw_won() 
 -- "you won!"
 printcb("you won!",11,0,128/2-7)
 
 -- flashing "press ❎ to restart"
 local col=5
 
 if gs.cur_timer<gs.cur_max_timer/2 then
  col=7
 end
 
 if gs.cur_timer<=0 then
  gs.cur_timer=gs.cur_max_timer
 else
  gs.cur_timer-=1
 end
 
 printcb("press ❎ to restart",col,0,128/2+6)
end
-->8
-- inits

function init_tiles(max_x,max_y) 
 for x=0,max_x-1 do
  for y=0,max_y-1 do
   if gs.tiles[x] == nil then
    gs.tiles[x]={}
   end
   
   gs.tiles[x][y]=new_tile()
  end
 end
 
 gs.hidden_tiles=max_x*max_y
 gs.cur_x=flr((max_x-1)/2)
 gs.cur_y=flr((max_y-1)/2)
end

function init_mines(cnt,cx,cy)
 for i=0,cnt-1 do  
  while true do
   local x,y=flr(rnd(gs.w)),flr(rnd(gs.h))
   local skip=x==cx and y==cy
   local t=gs.tiles[x][y]
   
   if not skip and not t.mine then
    t.mine=true
    add(gs.mines,t)
    
    if gs_debug.reveal then
     t.state=tile_state.revealed
    end
    
    break
   end
  end
 end
 
 gs.mines_laid=true
end

function init_ind_col()
 gs.ind_col[1]=12
 gs.ind_col[2]=11
 gs.ind_col[3]=10
 gs.ind_col[4]=9
 gs.ind_col[5]=14
 gs.ind_col[6]=15
 gs.ind_col[7]=8
 gs.ind_col[8]=0
end
-->8
-- objects

tile_state={
 hidden=0,
 revealed=1,
 flagged=2
}

function new_tile(x,y)
 return {
 	x=x,
 	y=y,
  state=tile_state.hidden,
  mine=false,
  mine_cnt=nil
 }
end
-->8
-- logic
function reveal_tile(x,y)
 local tile=gs.tiles[x][y]
 local neighbors={}
 
 if tile.state!=tile_state.hidden then
  return
 end
 
 if tile.mine then
  game_over()
  return
 end
 
 for i=-1,1 do
  for j=-1,1 do
   if x+i>=0 and x+i<gs.w and y+j>=0 and y+j<gs.h then
    if not(i==0 and j==0) then
     add(neighbors,{x+i,y+j})
    end
   end
  end
 end
 
 tile.state=tile_state.revealed
 gs.hidden_tiles-=1
 
 local mines=0
 for n in all(neighbors) do
  local ntile=gs.tiles[n[1]][n[2]]
  if ntile.mine then
   mines+=1
  end
 end
 
 tile.mine_cnt=mines
 
 if mines<=0 then
  for n in all(neighbors) do
   reveal_tile(n[1],n[2])
  end
 end
end

function flag_tile(x,y)
 local tile=gs.tiles[x][y]
 
 if tile.state==tile_state.hidden then
  if gs.flags>=gs.mine_cnt then
   return
  end
  
  add(gs.flagged_tiles,tile)
  tile.state=tile_state.flagged
 elseif tile.state==tile_state.flagged then
  del(gs.flagged_tiles,tile)
  tile.state=tile_state.hidden
 end
 
 gs.flags=#gs.flagged_tiles
end

function game_over()
 for t in all(gs.mines) do
  t.state=tile_state.revealed
 end
 
 gs.game_over=true
end

function won()
 for x=0,#gs.tiles do
  for y=0,#gs.tiles[x] do
   local t=gs.tiles[x][y]
   
   if t.state==tile_state.hidden and not contains(gs.mines,t) then
    reveal_tile(x,y)
   end
   
   if t.state==tile_state.hidden then
    flag_tile(x,y)
   end
  end
 end
 
 gs.won=true
end

function eval_state()
 -- all tiles are revealed
 if gs.hidden_tiles<=gs.mine_cnt then
  won()
  return
 end
 
 -- all mines are flagged
 --if #gs.mines<=0 then
 -- return
 --end
 
 --local all_flagged=true
 --for _,t in pairs(gs.mines) do
 -- if not contains(gs.flagged_tiles,t) then
 --  all_flagged=false
 --  break
 -- end
 --end
 
 --if all_flagged then
 -- won()
 --end
end
-->8
-- utils

function debug(txt)
 add(gs_debug.dbg,txt)
end

function printc(txt,col,y)
 local x=128/2-#txt/2*4
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
 local x=128/2-#txt/2*4
 printb(txt,col1,col2,x,y)
end

function t2p(x,y)
 -- tile to pixel coord
 local ix,iy=max(16-gs.w,0),max(16-gs.h,0)
 ix=ceil(ix/2)
 iy=ceil(iy/2)
 
 local rx,ry=(x+ix)*8,(y+iy)*8
 
 return {x=rx,y=ry}
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
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000033333330000000005555555022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700033333330000860005555555022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000033333330008860005555555022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000033333330088860005555555022585220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700033333330000060005555555025555520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000033333330000060005555555022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000033333330000000005555555022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
