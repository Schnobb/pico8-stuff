pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--main

function _init()
 game = {
  debug = {},
  debug_enabled = true,
  
  gravity = 0.3,
  friction = 0.85,
  
  width = 128,
  height = 128,
  
  back = 1,
  
  bbox=bbox(0,0,128,128)
 }
 
 btns={
  left=0,
  right=1,
  up=2,
  down=3,
  o=4,
  x=5
 }
 
 local _pos = pts(
  game.width/2 - 16,
  game.height/2
 )
 player = create_player(_pos)
end

function _update60()
 _clear_debug()
 handle_inputs()
 player:update()
 
 if game.debug_enabled then
 	db("state: "..player.state)
 	db("vel: "..player.vel:str())
 	db("jump recov: "..player.jump_recover)
 end
end

function _draw()
 cls(game.back)
 map(0, 0, 0, 0, 16, 16)
 player:draw()
 _draw_debug()
end

function handle_inputs()
 if btn(btns.left) then
  player:move(-1, 0)
 end
 
 if btn(btns.right) then
  player:move(1, 0)
 end
 
 if btn(btns.up) then
  player:jump()
 elseif player.state == player_states.jumping then
  player.jump_tick=0
 end
end

function _draw_debug()
 cursor(0,0)
 for d in all(game.debug) do
  local curx,cury=peek(0x5f26),peek(0x5f27)
  printb(d.str,curx,cury,d.col,true)
 end
end

function _clear_debug()
 game.debug = {}
end
-->8
--player
  
function create_player(_pos)
 return {
  pos = pts(
   _pos.x,
   _pos.y
  ),
  
  bbox={
  	x=2,
  	y=0,
  	w=4,
  	h=8
  },
  
  w = 8,
  h = 8,
  tile = 1,
  
  vel = pts(0,0),
  max_vel = pts(1.2,3),
  accel = pts(1,2),
  
  jump_tick = 0,
  max_jump_tick = 20,
  jump_recover = 0,
  max_jump_recover = 10,
  jump_sound = sounds.player_jump,
  
  state = player_states.normal,
  
  draw = function(self)
   spr(self.tile, self.pos.x, self.pos.y)
  end,
  
  move = function(self, _x, _y)
   local _vx,_vy = self.vel.x,self.vel.y
   _vx += _x * self.accel.x
   _vy += _y * self.accel.y
   
   self.vel = pts(
   	min(self.max_vel.x, abs(_vx)) * sgn(_vx),
    min(self.max_vel.y, abs(_vy)) * sgn(_vy)
   )
  end,
  
  jump = function(self)
   if self.state != player_states.falling then   
    if self.state != player_states.jumping and self.jump_recover < 1 then
     self.jump_recover = self.max_jump_recover
     self.state = player_states.jumping
     self.jump_tick = self.max_jump_tick
     sfx(self.jump_sound)
    end
    
 			--self:move(0, -self.jump_tick/self.max_jump_tick)
 			self.vel.y=-self.accel.y
   end
  end,
  
  update = function(self)   
   if abs(self.vel.x) < 0.1 then
    self.vel.x = 0
   end
   
   if abs(self.vel.y) < 0.1 then
    self.vel.y = 0
   end
   
   local _next_pos,_col_data = _get_next_pos(self)
   
   db("coll: ".._col_data:str())
   if not _col_data.down then
    self.vel.y += game.gravity
   end
   
   self.pos = _next_pos
   
   self.jump_tick = max(0, self.jump_tick - 1)
   
   if _col_data.down then
    self.jump_recover = max(0, self.jump_recover - 1)
    self.state = player_states.normal
   elseif self.state != player_states.jumping or self.jump_tick < 1 then
    self.state = player_states.falling
   end
   
   self.vel.x *= game.friction
   self.vel.y *= game.friction
  end
 }
end

function _get_next_pos(pl)
 local _pos = pts(
 	pl.pos.x + pl.vel.x,
 	pl.pos.y + pl.vel.y
 )
 
 local _bbox=bbox(
  _pos.x+pl.bbox.x,
  _pos.y+pl.bbox.y,
  pl.bbox.w,
  pl.bbox.h
 )
 
 local _col_data=_world_bounds(_bbox)
 _col_data:combine(_map_collisions(_bbox))
 
 _pos=pts(_bbox.pos.x-pl.bbox.x,_bbox.pos.y-pl.bbox.y)
 return _pos,_col_data
end

function _world_bounds(_bbox)
 local _col_data=_bbox:collides(game.bbox):reverse()
 if _col_data:collides() then
  if _col_data.top then
   _bbox.pos.y=game.bbox.pos.y
  end
  
  if _col_data.down then
   _bbox.pos.y=game.bbox.pos.y+game.bbox.size.y-_bbox.size.y
  end
  
  if _col_data.left then
   _bbox.pos.x=game.bbox.pos.x
  end
  
  if _col_data.right then
   _bbox.pos.x=game.bbox.pos.x+game.bbox.size.x-_bbox.size.x
  end
 end
 
 return _col_data
end

function _map_collisions(_bbox)
 local _col_data=col_data(false,false,false,false)
 
 
 
 return _col_data
end

function _check_map_collisions(_pos, pl)
 local _to_check = raycast(pl.pos, _pos)
 local _latest_valid_pos = pl.pos

 for _i=1,#_to_check do
  local _valid=true
  local _c=_to_check[_i]
  local _ps={
   pts(_c.x, _c.y),
   pts(_c.x+pl.w,_c.y),
   pts(_c.x,_c.y+pl.h),
   pts(_c.x+pl.w,_c.y+pl.h)
  }
  
  for _p in all(_ps) do
   local _mc = px2map(_p)
   local _tile = mget(_mc.x, _mc.y)
  
   if fget(_tile, flags.collision) then
    db(_mc:str())
    _valid=false
    break
   end
  end
  
  if _valid then
   _latest_valid_pos=_c
   db(_c:str())
  else
   break
   db(_c:str())
  end
 end
 
 return _latest_valid_pos
end
-->8
--utils
function printb(str,x,y,c,usecur)
 rectfill(x-1,y-1,#(""..str)*4+x-1,6+y-1,0)
 local col=c or 6
 if usecur then
  color(col)
  print(str)
  color()
 else
  print(str,x,y,col)
 end
end

function db(str,c)
 local d= {str=str,col=c}
 add(game.debug,d)
end

function pts(_x, _y)
 return {
  x=_x,
  y=_y,
  
  str = function(self)
   return "["..self.x..","..self.y.."]"
  end
 }
end

function bbox(_x,_y,_w,_h)
 return {
  pos = pts(_x,_y),
  size = pts(_w,_h),
  
  collides = function(self,_bbox)
   local _res = col_data(false,false,false,false)
   
			if self.pos.x > _bbox.pos.x and self.pos.x < _bbox.pos.x + _bbox.size.x then
			 _res.left=true
			end
			
			if self.pos.x + self.size.x > _bbox.pos.x and self.pos.x + self.size.x < _bbox.pos.x + _bbox.size.x then
			 _res.right=true
			end
			
			if self.pos.y > _bbox.pos.y and self.pos.y < _bbox.pos.y + _bbox.size.y then
			 _res.top=true
			end
			
			if self.pos.y + self.size.y > _bbox.pos.y and self.pos.y + self.size.y < _bbox.pos.y + _bbox.size.y then
			 _res.down=true
			end
			
			return _res
  end
 }
end

function col_data(_t,_d,_l,_r)
 return {
  top=_t,
  down=_d,
  left=_l,
  right=_r,
  
  collides=function(self)
   return self.top or self.down or self.left or self.right
  end,
  
  reverse=function(self)
   self.top=not self.top
   self.down=not self.down
   self.left=not self.left
   self.right=not self.right
   return self
  end,
  
  combine=function(self,_col_data)
   self.top=self.top or _col_data.top
   self.down=self.down or _col_data.down
   self.left=self.left or _col_data.left
   self.right=self.right or _col_data.right
  end,
  
  str=function(self)
   local top=self.top and "1" or "0"
   local down=self.down and "1" or "0"
   local left=self.left and "1" or "0"
   local right=self.right and "1" or "0"
   return "["..top..","..down..","..left..","..right.."]"
  end
 }
end

function map2px(_pos)
 return pts(
 	_pos.x * 8, 
 	_pos.y * 8
 )
end

function px2map(_pos)
 return pts(
 	flr(_pos.x / 8),
 	flr(_pos.y / 8)
 )
end

function raycast(_pos1, _pos2)
 -- returns a list of points
 -- between _pos1 and _pos2
 local _res = {}
 
 local _dx,_dy = _pos2.x - _pos1.x, _pos2.y - _pos1.y
 local _step = max(abs(_dx), abs(_dy))
 
 _dx /= _step
 _dy /= _step
 
 local _pos,_i = pts(_pos1.x,_pos1.y),1
 
 while(_i<=_step) do
  add(_res,pts(_pos.x,_pos.y))
  _pos.x += _dx
  _pos.y += _dy
  _i += 1
 end
 
 add(_res,pts(_pos2.x,_pos2.y))
 
 return _res
end
-->8
-- data

player_states = {
 normal = "normal",
 jumping = "jumping",
 falling = "falling"
}

sounds = {
 player_jump = 0
}

flags = {
 collision = 0
}
__gfx__
00000000000bb0005655556500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000b33b006666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000bbbb005666666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000bb0005666666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000bbbb005666666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000bb0005666666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000bbbb006666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003003005655556500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000020300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000019050180501805017050170501705017050180501a0501b0501f0502205024050280502b0502d050290502605000000000000000000000000000000000000000000000000000000000000000000
