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
  mines_laid=false
 }
 
 debug={
  reveal=true
 }
 
 init_tiles(16,16)
 --init_mines(gs.mine_cnt)
 init_ind_col()
end

function _update60()
 handle_inputs()
end

function _draw()
 cls()
 
 for x,c in pairs(gs.tiles) do
  for y,t in pairs(c) do
   local s
   local draw_ind=false
   
   if t.state == tile_state.revealed then
    if t.mine then
     s=4
    else
     s=3
     draw_ind=true
    end
   elseif t.state == tile_state.flagged then
				s=2
   else
    s=1
   end
   
   spr(s,x*8,y*8)
   
   if draw_ind then
    if t.mine_cnt!=nil and t.mine_cnt>0 then
     local col=gs.ind_col[t.mine_cnt]
     print(t.mine_cnt,x*8+3,y*8+2,col)
    end
   end
  end
 end
 
 draw_cursor(gs.cur_x, gs.cur_y)
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
 
 rect(x*8+1,y*8+1,x*8+8-1,y*8+8-1,col)
end

function handle_inputs()
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
 
 gs.cur_x=gs.cur_x%16
 gs.cur_y=gs.cur_y%16
 
 if btnp(❎) then
  if not gs.mines_laid then
   init_mines(gs.mine_cnt,gs.cur_x,gs.cur_y)
  end
  
  reveal_tile(gs.cur_x, gs.cur_y)
 end
 
 if btnp(🅾️) then
  flag_tile(gs.cur_x, gs.cur_y)
 end
end
-->8
-- inits

function init_tiles(max_x,max_y)
 for x=0,max_x do
  for y=0,max_y do
   if gs.tiles[x] == nil then
    gs.tiles[x]={}
   end
   
   gs.tiles[x][y]=new_tile()
  end
 end
end

function init_mines(cnt,cx,cy)
 for i=0,cnt do  
  while true do
   local x,y=flr(rnd(16)),flr(rnd(16))
   local skip=x==cx and y==cy
   
   if not skip and not gs.tiles[x][y].mine then
    gs.tiles[x][y].mine=true
    
    if debug.reveal then
     gs.tiles[x][y].state=tile_state.revealed
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
 
 if tile.state==tile_state.hidden then
  for i=-1,1 do
   for j=-1,1 do
    if x+i>=0 and x+i<16 and y+j>=0 and y+j<16 then
     if not(i==0 and j==0) then
      add(neighbors,{x+i,y+j})
     end
    end
   end
  end
  
  tile.state=tile_state.revealed
  
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
end

function flag_tile(x,y)
 local tile=gs.tiles[x][y]
 
 if tile.state==tile_state.hidden then
  tile.state=tile_state.flagged
 elseif tile.state==tile_state.flagged then
  tile.state=tile_state.hidden
 end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000033333330333333305555555022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700033333330333863305555555022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000033333330338863305555555022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000033333330388863305555555022585220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700033333330333363305555555025555520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000033333330333363305555555022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000033333330333333305555555022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
