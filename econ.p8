pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- main
max_price_range = 0.5
max_stats = 15
max_starting_credits = 1000
seed = 478 -- flr(rnd(32767))

function _init()
 -- enable mouse
 poke(0x5f2d, 0x1)
 
 entity_type = {
  factory = 0
 }
 
 objective_type = {
  search = 0,
  pickup = 1,
  dock = 2,
  deliver = 3,
  undock = 4
 }
 
 modes_count = 2
 modes = {
  storage = 0,
  billboard = 1,
  normal = 2
 }
 
 init_prng(seed)
 init_wares()
 init_producers()
 init_billboard()
 init_transporters()
 
 mode = modes.normal
 
 dbg = {}
 debug_enabled = true
 
 focused_entity = nil
 focused_type = nil
end

function _update60() 
 handle_inputs()
 
 for producer in all(producers) do
  producer:update()
 end
 
 for transporter in all(transporters) do
  transporter:update()
 end
end

function _draw()
 color()
 cls(0)
 
 --print("seed " .. seed)
 --print(debug_mouse)
 
 print()
 
 if mode == modes.storage then
  _draw_storage()
 elseif mode == modes.billboard then
  _draw_billboard()
 elseif mode == modes.normal then
  _draw_normal()
 end
 
 draw_focused_object()
 
 draw_debug()
 draw_cursor()
end

function handle_inputs()
 if btnp(❎) then
  mode = (mode + 1) % modes_count
 end
 
 local mpos = mouse_lclick()
 if mpos then
  --debug_mouse = ""
  focused_entity = nil
  focused_type = nil
  
  -- clicked on a producer?
  for producer in all(producers) do
   if collides(mpos.x, mpos.y, producer.x, producer.y, 2) then
    focused_entity = producer
    focused_type = entity_type.factory
   end
  end
 end
end

function draw_focused_object()
 if not focused_entity or not focused_type then
  return
 end
 
 if focused_type == entity_type.factory then
  print_producer_info(focused_entity)
 end
end

function draw_cursor()
 local mpos = mouse_pos()
 spr(1, mpos.x-3, mpos.y-3)
end

function draw_debug()
 if debug_enabled then
  for m in all(dbg) do
   print(m)
  end
 end
end

function _draw_storage()
 for producer in all(producers) do
  color(3)
  print(producer.id)
  color(9)
  print_storage(producer.storage)
  print("")
 end
end

function _draw_billboard()
 color(10)
 print("buy orders:")
 for k,o in pairs(billboard.buy_orders) do
   color(3)
   print(o.dest.id)
   color(11)
   print(" " .. o.ware.id .. ": " .. o.qty .. " @ " .. flr(o.price) .. "cr")
 end
 
 color(10)
 print("")
 print("sell orders:")
 for k,o in pairs(billboard.sell_orders) do
   color(3)
   print(o.dest.id)
   color(11)
   print(" " .. o.ware.id .. ": " .. o.qty .. " @ " .. flr(o.price) .. "cr")
 end
end

function _draw_normal()
 for producer in all(producers) do
  circfill(producer.x, producer.y, 2, producer.col)
 end
end

-->8
-- objects

function producer(id, prod, max_storage, col, x, y)
 return {
  id = id,
  prod = prod or {},
  max_storage = max_storage,
  col = col or 3,
  x = x or flr(rnd(128)),
  y = y or flr(rnd(128)),
  
  storage = nil,
  
  -- methods
  update = function(self)
   -- init storage
   if self.storage == nil then
    self.storage = init_storage(self)
   end
   
   -- check inventory
   local needed_wares = {}
   local produced_wares = {}
   
   for k,s in pairs(self.storage) do
    if s.produced then
     add(produced_wares, {ware = s.ware, qty = s.qty})
    else
     add(needed_wares, {ware = s.ware, qty = max(0, s.cap - s.qty)})
    end
   end
   
   -- update orders
   for e in all(needed_wares) do
    self:buy_order(e.ware, e.qty)
   end
   
   for e in all(produced_wares) do
    self:sell_order(e.ware, e.qty)
   end
   
   -- produce wares
   for p in all(self.prod) do
    if p.tick < p.max_tick then
     p.tick += 1
    else    
     p.tick = 0
     
     local produce = true
     for prec in all(p.ware.prec) do
      if self.storage[prec.ware].qty < prec.qty then
       produce = false
       break
      end
     end
     
     if produce then
      for prec in all(p.ware.prec) do
       self.storage[prec.ware].qty -= prec.qty
      end
      
      --print(p.ware.id)
      local produced = flr(p.qty_mul * p.ware.prod_qty)
      local cap = self.storage[p.ware].cap
      self.storage[p.ware].qty += produced
      self.storage[p.ware].qty = min(cap, self.storage[p.ware].qty)
     end
    end
   end
  end,
  
  buy_order = function(self, ware, qty)
   local cargo = self.storage[ware]
   billboard:add_buy(order(ware, qty, self, cargo))
  end,
  
  sell_order = function(self, ware, qty)
   local cargo = self.storage[ware]
   billboard:add_sell(order(ware, qty, self, cargo))
  end,
  
  deliver = function(self, ware, qty)
   local cap = self.storage[ware].cap
   local current = self.storage[ware].qty
   self.storage[ware] = min(cap, qty + current)
  end
 }
end

function transporter(id, x, y, col, credits, max_cap, stats)
 return {
  id = id,
  x = x,
  y = y,
  col = col or 12,
  credits = credits or flr(rnd(max_starting_credits + 1)),
  max_cap = max_cap or 500,
  stats = stats or new_stats(),
  
  tick = 0,
  max_tick = 0,
  
  cargohold = cargo(nil, 0, max_cap or 500, false),
  obj = objective(objective_type.search),
  
  change_obj = function(self, obj)
   
  end,
  
  update = function(self)
   if self.obj.type == objective_type.search then
    self:_update_search()
   elseif self.obj.type == objective_type.pickup then
    self:_update_pickup()
   elseif self.obj.type == objective_type.deliver then
    self:_update_deliver()
   elseif self.obj.type == objective_type.undock then
    self:_update_undock()
   end
  end,
  
  _update_search = function(self)
   
  end,
  
  _update_pickup = function(self)
   
  end,
  
  _update_deliver = function(self)
   
  end,
  
  _update_undock = function(self)
   
  end
 }
end

function ware(id, price, prod_qty, prec)
 return {
  id = id,
  price = price,
  prod_qty = prod_qty,
  prec = prec or {},
 }
end

function prec(ware, qty)
 return {
  ware = ware,
  qty = qty
 }
end

function production(ware, qty_mul, time)
 -- time in seconds
 return {
  ware = ware,
  qty_mul = qty_mul,
  time = time,
  max_tick = time * 60,
  tick = 0
 }
end

function cargo(ware, qty, cap, produced)
 return {
  ware = ware,
  qty = qty,
  cap = cap,
  produced = produced
 }
end

function reservation(ware, qty, dest, transporter)
 return {
  ware = ware,
  qty = qty,
  dest = dest,
  transporter = transporter
 }
end

function order(ware, qty, dest, cargo)
 return {
  ware = ware,
  qty = qty,
  dest = dest,
  cargo = cargo,
  
  price = 0,
  reservations = {},
  
  update = function(self, qty)
   self.qty = max(0, qty - self:amt_reserved())
   self:refresh()
  end,
  
  refresh = function(self)
   self.price = self:_compute_price()
  end,
  
  reserve = function(self, qty, transporter)
   -- right now this makes sense for buy orders only... take into account sell orders too
   assert(qty <= self.qty, "could not reserve " .. qty .. " " .. self.ware.id .. " (" .. self.qty .. " needed)")
   add(self.reservations, reservation(self.ware, qty, self.dest, transporter))
   self.qty -= qty
  end,
  
  amt_reserved = function(self)
   local qty = 0
   for r in all(self.reservations) do
    qty += r.qty
   end
   return qty
  end,
  
  _compute_price = function(self)
   local price_mod = self:_get_price_mod(ware, qty)
   local price = price_mod * ware.price
  end,
  
  _get_price_mod = function(self, ware, qty)
   -- this only makes sense for sell orders... take into account buy orders
   -- right now this is a lerp, maybe try a smoothstep?
   return (1 - max_price_range) + (1 - qty / self.cargo.cap) * max_price_range * 2
  end
 }
end

function new_billboard()
 return {
  buy_orders = {},
  sell_orders = {},
  
  add_buy = function(self, new_order)
   self:_add_order(new_order, self.buy_orders)
  end,
  
  add_sell = function(self, new_order)
   self:_add_order(new_order, self.sell_orders)
  end,
  
  get_buys = function(self, prod_id)
   return self:_get_orders(prod_id, self.buy_orders)
  end,
  
  get_sells = function(self, prod_id)
   return self:_get_orders(prod_id, self.sell_orders)
  end,
  
  _add_order = function(self, new_order, list)
   local _order = nil
   for k,o in pairs(list) do
    if new_order.ware == o.ware and new_order.dest == o.dest then
     _order = o
     break
    end
   end
   
   if _order == nil then
    add(list, new_order)
    new_order:refresh()
   else
    _order:update(new_order.qty, new_order.price)
   end
  end,
  
  _get_orders = function(self, prod_id, list)
   local results = {}
   
   for o in all(list) do
    if o.dest.id == prod_id then
     add(results, o)
    end
   end
   
   return results
  end
 }
end

function objective(type, dest, qty)
 return {
  type = type,
  dest = dest,
  qty = qty
 }
end

function new_stats(business, pilot)
 return {
  business = business or flr(rnd(max_stats + 1)),
  pilot = pilot or flr(rnd(max_stats + 1))
 }
end

-->8
-- inits

function init_prng(_seed)
 seed = _seed
 srand(seed)
end

function init_wares()
 wares = {}
 
 -- todo: update qty for precursors
 -- base resources
 wares.cell = ware("cell", 2, 100)
 wares.ore = ware("ore", 10, 100)
 wares.silicon = ware("silicon", 13, 100)
 wares.helium = ware("helium", 6, 100)
 wares.methane = ware("methane", 7, 100)
 wares.hydrogen = ware("hydrogen", 5, 100)
 
 -- refined wares
 wares.metal = ware("metal", 18, 100, {prec(wares.cell, 100), prec(wares.ore, 100)})
 wares.graphene = ware("graphene", 20, 100, {prec(wares.cell, 100), prec(wares.methane, 100)})
 
 -- advanced wares
 wares.hullparts = ware("hull parts", 50, 100, {prec(wares.cell, 100), prec(wares.metal, 100), prec(wares.graphene, 100)})
end

function init_producers()
 producers = {}
 
 add(producers, producer("solar farm i", {production(wares.cell, 1, 1)}, 8000))
 add(producers, producer("solar farm ii", {production(wares.cell, 1.5, 2)}, 4000))
 
 add(producers, producer("ore mine i", {production(wares.ore, 1, 2)}, 10000, 4))
 add(producers, producer("methane extract i", {production(wares.methane, 1, 2)}, 12000, 2))
 
 add(producers, producer("ore refinery i", {production(wares.metal, 1, 2)}, 15000, 13))
 add(producers, producer("graphene refinery i", {production(wares.graphene, 1, 2)}, 5000, 7))
 
 add(producers, producer("hull parts factory i", {production(wares.hullparts, 1, 2)}, 20000, 9))
end

function init_transporters()
 transporters = {}
 
 add(transporters, transporter())
end

function init_storage(producer)
 local my_wares = {}
 local ware_count = 0
 local storage = {}
 
 for prod in all(producer.prod) do
  if not contains(my_wares, prod.ware) then
   add(my_wares, {ware = prod.ware, produced = true})
   ware_count += 1
   for prec in all(prod.ware.prec) do
    if not contains(my_wares, prec.ware) then
     add(my_wares, {ware = prec.ware, produced = false})
     ware_count += 1
    end
   end
  end
 end
 
 local cap = producer.max_storage \ ware_count
 for w in all(my_wares) do
  storage[w.ware] = cargo(w.ware, 0, cap, w.produced)
 end
 
 return storage
end

function init_billboard()
 billboard = new_billboard()
end

-->8
-- utils
function contains(table, elem)
 for v in all(table) do
  if v == elem then
   return true
  end
 end
 
 return false
end

function print_storage(storage)
 for w,c in pairs(storage) do
  print(w.id .. ": " .. c.qty .. "/" .. c.cap)
 end
end

function print_orders(orders)
 for o in all(orders) do
  print(o.ware.id .. ": " .. o.qty .. " @ " .. flr(o.price) .. "cr")
 end
end

function debug(msg)
 add(dbg, msg)
end

function vec2(x, y)
 return {
  x = x,
  y = y
 }
end

function mouse_lclick()
 if stat(34) & 0x1 > 0 then
  return mouse_pos()
 end
 
 return nil
end

function mouse_pos()
 return vec2(stat(32), stat(33))
end

function collides(x, y, cx, cy, rad)
 return x <= cx + rad and x >= cx - rad and y <= cy + rad and y >= cy - rad
end

function print_producer_info(producer)
 -- name
 color(producer.col)
 print(producer.id)
 
 -- storage
 color(6)
 print_storage(producer.storage)
 print("")
 
 -- buy orders
 local buy_orders = billboard:get_buys(producer.id)
 if #buy_orders > 0 then
  color(3)
  print("buy orders:")
  color(11)
  print_orders(buy_orders)
  print("")
 end
 
 -- sell orders
 local sell_orders = billboard:get_sells(producer.id)
 if #sell_orders > 0 then
  color(9)
  print("sell orders:")
  color(10)
  print_orders(sell_orders)
 end
end

function draw_text_background(ocurx, ocury, col)
 local curx, cury = peek(0x5f26), peek(0x5f27)
 rectfill(ocurx*4, ocury*6, curx*4, cury*6, col)
end

__gfx__
00000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000770707700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
