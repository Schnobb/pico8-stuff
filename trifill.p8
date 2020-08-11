pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- main

function _init()
 state={
  debug={},
  show_area=false,
  
  triangles=genrndtri(256),
  triindex=1
 }
end


function _update60()
 dbclear()
 
 if btnp(btns.left) then
  -- stupid tables that start at one...
  state.triindex=(((state.triindex-1)-1)%#state.triangles)+1
 elseif btnp(btns.right) then
  -- stupid tables that start at one...
  state.triindex=(((state.triindex-1)+1)%#state.triangles)+1
 end
 
 if state.show_area then
  local tri=state.triangles[state.triindex]
  db("area: "..area(tri.p1,tri.p2,tri.p3))
 end
end


function _draw()
 cls()
 
 local tri=state.triangles[state.triindex]
 tribary.tribary(tri)
 
 db("fps: "..min(flr(stat(8)/stat(1)),stat(8)))
 db("mem: "..ceil(stat(0)).."kb")
 db("cpu: "..ceil(stat(1)*100).."%")
 db("tri: "..state.triindex)
 dbtri(state.triangles[state.triindex])
 
 drawdebug(state.debug)
end
-->8
-- baryatric coords method

tribary={
 barycentric=function(tri,p)
  local v1,v2,v3=tri.p1,tri.p2,tri.p3
  local u=cross3(vec3(v3.x-v1.x,v2.x-v1.x,v1.x-p.x),vec3(v3.y-v1.y,v2.y-v1.y,v1.y-p.y))
  if abs(u.y)<1 then
   return vec3(-1,1,1)
  else
   return vec3(1-(u.x+u.y)/u.z,u.y/u.z,u.x/u.z)
  end
 end,
 
 bbox=function(tri)
  local v1,v2,v3=tri.p1,tri.p2,tri.p3
  local bmin,bmax={127,127},{0,0}
  local pts={v1:list(),v2:list(),v3:list()}
  
  for i=1,3 do
   for j=1,2 do
    bmin[j]=max(0,min(bmin[j],pts[i][j]))
    bmax[j]=min(128,max(bmax[j],pts[i][j]))
   end
  end
  
  return {
   bmin=vec2(bmin[1],bmin[2]),
   bmax=vec2(bmax[1],bmax[2])
  }
 end,
 
 tribary=function(tri)
  local box=tribary.bbox(tri)
  
  for x=box.bmin.x,box.bmax.x do
   for y=box.bmin.y,box.bmax.y do
    local p=vec2(x,y)
    local bary=tribary.barycentric(tri,p)
    if bary.x>=0 and bary.y>=0 and bary.z>=0 then
     pset(p.x,p.y,tri.col)
    end
   end
  end
 end
}
-->8

-->8

-->8

-->8

-->8
-- utils

btns={
 left=0,
 right=1,
 up=2,
 down=3,
 o=4,
 x=5
}


function genrndtri(count)
 local tris={}
 
 for i=1,count do
  local tri=triangle(
   vec2(flr(rnd(128)),flr(rnd(128))),
   vec2(flr(rnd(128)),flr(rnd(128))),
   vec2(flr(rnd(128)),flr(rnd(128))),
   flr(rnd(15))+1
  )
  add(tris,tri)
 end
 
 return tris
end


function triangle(p1,p2,p3,col)
 return {
  p1=p1,
  p2=p2,
  p3=p3,
  col=col
 }
end


function vec2(x,y)
 return {
  x=x,
  y=y,
  
  list=function()
   return {x,y}
  end
 }
end


function vec3(x,y,z)
 return {
  x=x,
  y=y,
  z=z,
  
  list=function()
   return {x,y,z}
  end
 }
end


function vec4(x,y,z,w)
 return {
  x=x,
  y=y,
  z=z,
  w=w,
  
  list=function()
   return {x,y,z,w}
  end
 }
end


function cross3(a,b)
 return vec3(
  a.y*b.z-a.z*b.y,
  a.z*b.x-a.x*b.z,
  a.x*b.y-a.y*b.x
 )
end


function printb(str,x,y,col,bordercol,usecur)
 local x1,y1=x,y
 if usecur then
  x1,y1=peek(0x5f26),peek(0x5f27)
 end
 
 rectfill(x1-1,y1-1,#(""..str)*4+x1-1,6+y1-1,bordercol or 0)
 if usecur then
  color(col)
  print(str)
  color()
 else
  print(str,x,y,col)
 end
end

function area(p1,p2,p3)
 return ((p2.x-p1.x)*(p3.y-p1.y) - (p3.x-p1.x)*(p2.y-p1.y))/2
end
-->8
-- debug

function db(str,col,bordercol)
 local tmp={
  str=str,
  col=col or 6,
  bordercol=bordercol or 0
 }
 
 add(state.debug,tmp)
 return tmp
end


function dbvec(vec,col)
 local str=""
 local v=vec:list()
 for i=1,#v do
  str=str..v[i]..","
 end
 str=sub(str,1,-2)
 db(str,col)
 return str
end


function dbtri(tri)
 dbvec(tri.p1,tri.col)
 dbvec(tri.p2,tri.col)
 dbvec(tri.p3,tri.col)
end


function dbclear()
 state.debug={}
end


function drawdebug(deb)
 cursor(0,0)
 for d in all(deb) do  
  printb(d.str,curx,cury,d.col,d.bordercol,true)
 end
end
