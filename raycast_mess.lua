-- 9,32,-0.707,-0.7078
-- 9,32,-0.6982,-0.7165
function raycast(px,py,fx,fy,deb)
 local nx,ny=flr(px),flr(py)
 local tx,ty=nx,ny
 local side=false
 local tile=0
 
 while is_inside(nx,ny,gs.bounds.p1,gs.bounds.p2) do
  -- find next multiple of 8 in both x and y
  if fx<0 then
   tx=(nx-(ceil(nx/8)-1)*8)%8+1 -- add 1 so it's actually in the previous tile
  else
   tx=(nx\8+1)*8-nx
  end
  
  if fy<0 then
   ty=(ny-(ceil(ny/8)-1)*8)%8+1 -- add 1 so it's actually in the previous tile
  else
   ty=(ny\8+1)*8-ny
  end
  
  --db(tx..","..ty)
  if deb then db("a: "..tx..","..ty) end
  
  -- check which point is closer, next x or next y?
  if abs(tx/fx)<abs(ty/fy) then
   -- next x is closer
   nx+=tx*sgn(fx)
   -- ratio of fy/fx is the same ratio as tx/ty
   ty=abs((tx*fy)/fx)
   ny+=ty*sgn(fy)
   side=true
  else
   -- next y is closer
   ny+=ty*sgn(fy)
   -- ratio of fy/fx is the same ratio as tx/ty
   tx=abs((ty*fx)/fy)
   nx+=tx*sgn(fx)
   side=false
  end
  
  --db_px(vec2(nx,ny))
  if deb then db("b: "..tx..","..ty..","..tostr(side)) end
  
  tile=colsn(nx,ny)
  if tile>0 then break end
 end
 
 return {
  p=vec2(nx,ny),
  tile=tile,
  side=side,
  d=len(nx-px,ny-py),
  col=cols[tile]
 }
end

function raycast(px,py,fx,fy,flag,pfx,pfy) 
 -- starting distance from tile side
 local sdx,sdy=0,0
 
 if fx<0 then
  sdx=(px%8)/8
 else
  sdx=(8-px%8)/8
 end
 
 if fy<0 then
  sdy=(py%8)/8
 else
  sdy=(8-py%8)/8
 end
 
 sdx*=abs(fx)
 sdy*=abs(fy)
 
 local nx,ny=px,py
 local tile=-1
 local sides=fx>fy
 
 while true do --is_inside(np,gs.bounds.p1,gs.bounds.p2) do
 	tile=colsn(nx,ny)
  if tile>0 then
   break
  end
 	
 	if abs(sdx)<abs(sdy) then
 	 sdx+=dx
 	 nx+=8*sgn(fx)
 	else
 	 sdy+=dy
 	 ny+=8*sgn(fy)
 	end
 end
 
 d=len(nx-px,ny-py)
 
 return {
  p=vec2(nx,ny),
  d=d,
  col=cols[tile],
  sides=sides
 }
end

function raycast_sdkfsd(px,py,fx,fy,flag,pfx,pfy)
 -- can be optimized later by
 -- jumping from tile to tile
 -- instead of pixel by pixel
 local dx,dy=fx,fy
 local nx,ny=px,py
 local step=max(abs(dx),abs(dy))
 local tile=-1
 
 dx/=step
 dy/=step
 
 dx*=8
 dy*=8
 
 local sides=dx>dy
 local tx,ty=0,0
 
 if fx<0 then
  tx=px-(nx\8)*8
 else
  tx=(nx\8+1)*8-px
 end
 
 if fy<0 then
  ty=py-(ny\8)*8
 else
  ty=(ny\8+1)*8-py
 end
 
 while true do --is_inside(np,gs.bounds.p1,gs.bounds.p2) do
  tile=colsn(nx,ny)
  
  if tile>0 then
   break
  end
  
  if tx<ty then
   tx+=dx
   sides=true
   nx+=1
  else
   ty+=dy
   sides=false
   ny+=1
  end
 end
 
 d=len(nx-px,ny-py)
 
 return {
  p=np,
  d=d,
  col=cols[tile],
  sides=sides
 }
end

function raycast_fucked(px,py,fx,fy,flag,pfx,pfy,debug)
 local dx,dy=abs(1/fx),abs(1/fy)
 
 if debug then db(debug..dx..","..dy) end
 
 local sx,sy=0,0
 local sdx,sdy=0,0
 --local np=vec2((p.x\8)*8,(p.y\8)*8)
 local nx,ny=px,py--(px\8)*8,(py\8)*8
 local ret={
  p=nil, -- collision point
  --ed=0, -- euclidian dist (fisheye)
  d=0, -- perpendicular dist (normalized)
  col=nil, -- {vert,horz} colors
  sides=false -- true: hit sides, false: hit top/bottom
 }
 local sides=false
 
 if fx<0 then
  sx=-8
  sdx=(px-nx)*dx
 else
  sx=8
  sdx=(nx+8-px)*dx
 end
 
 if fy<0 then
  sy=-8
  sdy=(py-ny)*dy
 else
  sy=8
  sdy=(ny+8-py)*dy
 end
 
 if fx==0 then sdx=dx end
 if fy==0 then sdy=dy end
 
 if debug then db(debug..sx..","..sdx..","..sy..","..sdy) end
 
 sides=sdx<sdy
 
-- while is_inside(np,gs.bounds.p1,gs.bounds.p2) do
 while true do
  --local tile=collides(np,flag)
  --if tile>0 and false then
  --if false then
  -- -- collided
  -- ret.p=np
  -- --ret.ed=sqrt((p.x-np.x)^2+(p.y-np.y)^2)
   
  -- if ret.sides then
  --  ret.d=(np.y-p.y+(1-sy)/2)/face.y
  -- else
  --  ret.d=(np.x-p.x+(1-sx)/2)/face.x
  -- end
   
  -- ret.d/=8
  -- ret.col=cols[tile]
  -- return ret
  --end
  
  local tile=colsn(nx,ny)
  if tile>0 then
   local d=0
   local simple_dist=gs.simple_dist
   
   if simple_dist then
	   if sides then
	    d=(ny-py+(1-sy)/2)/fy
	   else
	    d=(nx-px+(1-sx)/2)/fx
	   end
   else
   	local ed=len(nx-px,ny-py) -- euclidian distance
    local cfx,cfy=rot(pfx,pfy,pi/2) -- get camera plane by rotating pl.face 90deg ccw
   	local tr=d_between_vec(cfx,cfy,fx,fy) -- angle between cam plane and ray direction
    
    if debug then db(debug..ed..","..cfx..","..cfy..","..tr) end
    
    -- if tr>pi/2 we found the obtuse angle, we need the acute one
    if tr>90 then
     tr=180-tr
    end
    
    if debug then db(debug..tr) end
   	
    -- get distance between point and cam plane
    -- we have hypotenuse, right angle, and angle between ray and cam plane
   	d=ceil(abs(ed*sin2(deg2rad(tr))))
    
    if debug then db(debug..d) end
   end
   
   return {
    p=vec2(nx,ny),
    d=d,
    col=cols[tile],
    sides=sides
   }
  end
  
  if sdx<sdy then
   sdx+=dx
   nx+=sx
   sides=false
  else
   sdy+=dy
   ny+=sy
   sides=true
  end
 end
 
 ret.p=vec2(nx,ny)
 ret.d=1/0 --maxint
 ret.col=cols[0]
 ret.sides=sides
 return ret
end

function raycast_old(p,face,flag)
 -- can be optimized later by
 -- jumping from tile to tile
 -- instead of pixel by pixel
 local dx,dy=face.x,face.y
 local np=vec2(p.x,p.y)
 local step=max(abs(dx),abs(dy))
 
 dx/=step
 dy/=step
 
 local sides=dx>dy
 local tx,ty=dx,dy
 
 while is_inside(np,gs.bounds.p1,gs.bounds.p2) do
  local tile=collides(np,flag)
  
  if tile>0 then
   return np,cols[tile],sides
  end
  
  if tx<ty then
   tx+=dx
   sides=true
   np.x+=1
  else
   ty+=dy
   sides=false
   np.y+=1
  end
 end
 
 return np
end

function dda2(p,face,flag)
 local dx=(1/face.x)
 local dy=(1/face.y)
 
 print(dx,7)
 print(dy,7)
 
 -- starting distance from tile side
 local sdx,sdy=0,0
 
 if face.x<0 then
  sdx=(p.x%8)/8
 else
  sdx=(8-p.x%8)/8
 end
 
 if face.y<0 then
  sdy=(p.y%8)/8
 else
  sdy=(8-p.y%8)/8
 end
 
 sdx*=abs(dx)
 sdy*=abs(dy)
 
 print(sdx,7)
 print(sdy,7)
 
 local np=vec2(p.x,p.y)
 
 while is_inside(np,gs.bounds.p1,gs.bounds.p2) do
 	if collides(np,flag) then
 	 return np,(sdx<sdy)
 	end
 	
 	if abs(sdx)<abs(sdy) then
 	 sdx+=dx
 	 np.x+=8*sgn(face.x)
 	else
 	 sdy+=dy
 	 np.y+=8*sgn(face.y)
 	end
 	
 	db_px(vec2(np.x,np.y))
 end
 
 return np
end

function dda3(p,face,flag)
 local dx,dy=face.x,face.y
 local np=vec2(p.x,p.y)
 local step=max(abs(dx),abs(dy))
 
 --db(step)
 
 dx/=step
 dy/=step
 
 dx*=8
 dy*=8
 
 if face.x<0 then
  np.x=flr(np.x+(8-(np.x%8)-1)*-face.x)
 else
  np.x=ceil(np.x+(np.x%8)*-face.x)
 end
 
 if face.y<0 then
  np.y=flr(np.y+(8-(np.y%8)-1)*-face.y)
 else
  np.y=ceil(np.y+(np.y%8)*-face.y)
 end
 
 np.x=flr(np.x)
 np.y=flr(np.y)
 --db(np.x..","..np.y)
 
 while is_inside(np,gs.bounds.p1,gs.bounds.p2) do
  if collides(np,flag) then
   return np
  end
  
  --db_px(vec2(np.x,np.y))
  np.x+=dx
  np.y+=dy
 end
 
 return np
end