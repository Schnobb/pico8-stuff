pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--main
modes={
 vertex=0,
 wireframe=1,
 flat=2,
 shade=3,
 tri=4,
 textest=5
}

btns={
 left=0,
 right=1,
 up=2,
 down=3,
 o=4,
 x=5
}

function _init()
 pi=3.14159265359
 
 game={
  debug={},
  debugpts={},
  showdebug=true,
  showfps=true,
  
  tricols={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15},
  tri=1,
  tris=genrndtri(256),
  trigenlines=true,
  
  colored_edges={
   col={8,11,12},
   enabled=false
  },
  shading={0,1,2,8,9,10,7},
  drawnorm=true,
  normcol=12,
  
  maincam=cam(vec3(0,0,5),vec3(0,0,0)),
  meshes={mesh(mesh_cube,vec3(0,0,0),vec3(0,0,0), vec3(1,1,1))},
  lights={light(vec3(0,0,-10))},
  perspective={
   fov=0.78,
   near=1,
   far=100
  },
  
  mode=modes.vertex,
  modecount=countmodes(),
  
  transform_mesh=true,
  zbuffer={},
  
  textesttexture=texture(8,0,23,15),
  textestsize={64,64}
 }
end

function _update60()
 clear_db()
 game.zbuffer={}
 
 if game.transform_mesh then
  local m=game.meshes[1]
  m.rot[1]=(m.rot[1]+0.002)%360
  m.rot[2]=(m.rot[2]+0.001)%360
  local s=1+(sin(time()/20)*0.25)
  m.scale[1]=s
  m.scale[2]=s
  m.scale[3]=s
 end
 
 handleinput()
 
end

function _draw()
 cls()
 render(game.maincam,game.meshes)
 drawdebug()
 local msg="press z and x to change mode"
 printb(msg,64-flr(#msg*4/2),120,5)
end

function render(_cam,_meshes)
 local mcam=matrix.lookat(_cam.pos,_cam.target)
 local mproj=matrix.persp(game.perspective.fov,game.perspective.near,game.perspective.far)
 
 for mesh_i=1,#_meshes do
  local m=_meshes[mesh_i]
  local mworld=matmult(matmult(matrix.scale(m.scale),matrix.rotation(m.rot)),matrix.trans(m.pos))
  local mortho=matmult(mworld,mcam)
  local mtran=matmult(mortho,mproj)
  
  local mat=mtran
  
  if game.mode==modes.vertex then
   for v in all(m.verts) do
    local point=project(v,mat)
    --db(point[1]..","..point[2])
    pset2(point,10)
   end
   
  elseif game.mode==modes.wireframe then
   for f in all(m.faces) do
    local a=project(m.verts[f[1]],mat)
    local b=project(m.verts[f[2]],mat)
    local c=project(m.verts[f[3]],mat)
    
    if game.colored_edges.enabled then
     line2(a,b,game.colored_edges.col[1])
     line2(b,c,game.colored_edges.col[2])
     line2(c,a,game.colored_edges.col[3])
    else
     line2(a,b,10)
     line2(b,c,10)
     line2(c,a,10)
    end
   end
   
  elseif game.mode==modes.flat then
   local sorted=getsortedfaces(m,mat)   
   for sf in all(sorted) do
    local i,f=sf.i,sf.face
    local a,b,c=sf.a,sf.b,sf.c
    local col=game.tricols[i%#game.tricols+1]
    
    trifill(a,b,c,col)
   end
   
  elseif game.mode==modes.shade then
   local sorted=getsortedfaces(m,mat)
   
   for sf in all(sorted) do
    local i,f=sf.i,sf.face
    local a,b,c=sf.a,sf.b,sf.c
    
    local aw=transform(m.verts[f[1]],mworld)
    local bw=transform(m.verts[f[2]],mworld)
    local cw=transform(m.verts[f[3]],mworld)
    local center=vecaddvec(vecaddvec(aw,bw),cw)
    center=vecdiv(center,3)
    
    local norm=transform(sf.normal,mworld)
    local lightpos=transform(game.lights[1].pos,matrix.ident())
    
    local l=vecsubvec(lightpos,center)
    norm=normalize(norm)
    l=normalize(l)
    local lightintens=max(0,dot(norm,l))
    
    trifill(a,b,c,nil,lightintens)
    
    if game.drawnorm then
     local cent2=transform(center,mcam)
     cent2=project(cent2,mproj)
     local norm2=transform(vecaddvec(norm,center),mcam)
     norm2=project(norm2,mproj)
     line2(cent2,norm2,game.normcol)
    end
   end
   
  elseif game.mode==modes.tri then
   local tri=game.tris[game.tri]
   trifill(tri[1],tri[2],tri[3],tri[4])
   
   if game.trigenlines then
    line2(tri[1],tri[2],10)
    line2(tri[2],tri[3],10)
    line2(tri[3],tri[1],10)
   end
   
  elseif game.mode==modes.textest then
   local xsize,ysize=game.textestsize[1],game.textestsize[2]
   local x1,y1=flr(64-xsize/2),flr(64-ysize/2)
   local x2,y2=x1+xsize,y1+ysize
   
   --rect(x,y,x+xsize,y+ysize,10)
   for x=x1,x2 do
    for y=y1,y2 do
     local u,v=(x-x1)/(x2-x1),(y-y1)/(y2-y1)
     pset(x,y,gettex(game.textesttexture,u,v))
    end
   end
  end
 end
end

function getsortedfaces(m,mat)
 local sorted={}
  --sorting faces to draw triangles in avg z order (max z first)
 for i,f in pairs(m.faces) do
  local a=project(m.verts[f[1]],mat)
  local b=project(m.verts[f[2]],mat)
  local c=project(m.verts[f[3]],mat)
  
  add(sorted,{
   z=(a[3]+b[3]+c[3])/3,
   face=f,
   a=a,
   b=b,
   c=c,
   normal=m.normals[i],
   i=i
  })
 end
 
 local comparez=function(a,b)
  return a.z>b.z
 end
 
 sort(sorted,comparez)
 return sorted
end

function handleinput()
 if btnp(btns.x) then
  game.mode=(game.mode+1)%game.modecount
 elseif btnp(btns.o) then
  game.mode=(game.mode-1)%game.modecount
 end
 
 if game.mode==modes.tri then
  if btnp(btns.up) then
   -- stupid tables that start at one...
   game.tri=(((game.tri-1)+1)%#game.tris)+1
  elseif btnp(btns.down) then
   -- stupid tables that start at one...
   game.tri=(((game.tri-1)-1)%#game.tris)+1
  end
  
  if btnp(btns.right) or btnp(btns.left) then
   game.trigenlines=not game.trigenlines
  end
  
 elseif game.mode==modes.textest then
  if btn(btns.up) then
   game.textestsize[2]=mid(8,game.textestsize[2]+1,128)
  elseif btn(btns.down) then
   game.textestsize[2]=mid(8,game.textestsize[2]-1,128)
  end
  
  if btn(btns.left) then
   game.textestsize[1]=mid(8,game.textestsize[1]-1,128)
  elseif btn(btns.right) then
   game.textestsize[1]=mid(8,game.textestsize[1]+1,128)
  end
  
 else
  if btn(btns.left) then
   rotcam(game.maincam,1)
  elseif btn(btns.right) then
   rotcam(game.maincam,-1)
  end
  if btn(btns.up) then
   zoomcam(game.maincam,0.95)
  elseif btn(btns.down) then
   zoomcam(game.maincam,1.05)
  end
 end
end

function drawdebug()
 if not game.showdebug then return end

 if game.showfps then
  db("mode: "..game.mode)
  db("fps: "..min(flr(stat(8)/stat(1)),stat(8)))
  db("mem: "..ceil(stat(0)).."kb")
  db("cpu: "..ceil(stat(1)*100).."%")
 end
 
 for p in all(game.debugpts) do
  printb(p.str,p.x,p.y,p.col)
 end
 
 cursor(0,0)
 for d in all(game.debug) do
  local curx,cury=peek(0x5f26),peek(0x5f27)
  printb(d.str,curx,cury,d.col,true)
 end
end
-->8
--objects

function vec2(x,y)
 return {x,y}
end

function vec3(x,y,z)
 return {x,y,z}
end

function cam(_pos,_target)
 return {
  pos=_pos,
  target=_target
 }
end

function mesh(_data,_pos,_rot,_scale)
 return {
  verts=_data.vertices,
  faces=_data.faces,
  normals=_data.normals,
  texture=_data.texture,
  pos=_pos,
  rot=_rot,
  scale=_scale
 }
end

function light(_pos)
 return {
  pos=_pos
 }
end

function texture(x1,y1,x2,y2)
 return {
  x1=x1,
  y1=y1,
  x2=x2,
  y2=y2
 }
end
-->8
--utils

function round(x)
 return flr(x+0.5)
end

function gettex(t,u,v)
 --local x,y=flr(u*game.texsize[1]),flr(v*game.texsize[2])
 local x,y=interp(t.x1,t.x2,u),interp(t.y1,t.y2,v)
 return sget(round(x),round(y))
end

function sort (arr, comp)
 if not comp then
  comp = function (a, b)
   return a < b
  end
 end
 local function partition (a, lo, hi)
   pivot = a[hi]
   i = lo - 1
   for j = lo, hi - 1 do
   if comp(a[j], pivot) then
   i = i + 1
   a[i], a[j] = a[j], a[i]
   end
   end
   a[i + 1], a[hi] = a[hi], a[i + 1]
   return i + 1
  end
 local function quicksort (a, lo, hi)
  if lo < hi then
   p = partition(a, lo, hi)
   quicksort(a, lo, p - 1)
   return quicksort(a, p + 1, hi)
  end
 end
 return quicksort(arr, 1, #arr)
end


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

function genrndtri(count)
 local tris={{vec2(76,76),vec2(51,76),vec2(60,120),6}}
 
 for i=1,count-1 do
  local tri={
   vec2(flr(rnd(128)),flr(rnd(128))),
   vec2(flr(rnd(128)),flr(rnd(128))),
   vec2(flr(rnd(128)),flr(rnd(128))),
   flr(rnd(15))+1
  }
  add(tris,tri)
 end
 
 return tris
end

function countmodes()
 local count=0
 for i in pairs(modes) do
  count+=1
 end
 return count
end

function ang2rad(a)
 return pi/180*a
end

function rad2ang(r)
 return 180/pi*r
end

function zoomcam(_cam,s)
 local p2=vec3(_cam.pos[1]*s,_cam.pos[2]*s,_cam.pos[3]*s)
 if len(p2)>=1 then
  _cam.pos=p2
 end
 return _cam.pos
end

function rotcam(_cam,a)
 local x,z,ox,oz=_cam.pos[1],_cam.pos[3],_cam.target[1],_cam.target[3]
 local t=ang2rad(a)
 --x
 local x2=cos(t)*(x-ox)-sin(t)*(z-oz)+ox
 --z
 local z2=sin(t)*(x-ox)+cos(t)*(z-oz)+oz
 
 _cam.pos[1],_cam.pos[3]=x2,z2
 return _cam.pos
end

function interp(a,b,grad)
 return a+(b-a)*mid(0,grad,1)
end

function scanline(y,pa,pb,pc,pd,c,l)
 local g1,g2
 local computez=pa[3]
 
 if pa[2]!=pb[2] then
  g1=(y-pa[2])/(pb[2]-pa[2])
 else
  g1=1
 end
 
 if pc[2]!=pd[2] then
  g2=(y-pc[2])/(pd[2]-pc[2])
 else
  g2=1
 end
 
 local sx=ceil(interp(pa[1],pb[1],g1))
 local ex=flr(interp(pc[1],pd[1],g2))
 
 if sx>ex then
  sx,ex=ex,sx
 end 
 
 local z1,z1
 
 if computez then
  z1=interp(pa[3],pb[3],g1)
  z2=interp(pc[3],pd[3],g2)
 end
 
 for x=sx,ex do
  if computez then
   local g=(x-sx)/(ex-sx)
   local z=interp(z1,z2,g)
   local col=c
   
   if l then
    local sh=game.shading
    local ind=ceil((#sh-1)*mid(0,l,1))+1
    col=sh[ind]
   end
   
   psetz(x,y,z,col)
  else
   pset(x,y,c)
  end
 end
end

function trifill(p1,p2,p3,col,l)
 -- sort by y
 if p1[2]>p2[2] then
  p1,p2=p2,p1
 end
 if p2[2]>p3[2] then
  p2,p3=p3,p2
 end
 if p1[2]>p2[2] then
  p1,p2=p2,p1
 end
 
 -- calc slopes
 local dp1p2,dp1p3
 
 if p2[2]-p1[2]>0 then
  dp1p2=(p2[1]-p1[1])/(p2[2]-p1[2])
 else
  dp1p2=0
 end
 
 if p3[2]-p1[2]>0 then
  dp1p3=(p3[1]-p1[1])/(p3[2]-p1[2])
 else
  dp1p3=0
 end
 
 for y=p1[2],p3[2] do
  if y<p2[2] then
   if dp1p2>dp1p3 then
    scanline(y,p1,p3,p1,p2,col,l)
   else
    scanline(y,p1,p2,p1,p3,col,l)
   end
  else
   if dp1p2>dp1p3 then
    scanline(y,p1,p3,p2,p3,col,l)
   else
    scanline(y,p2,p3,p1,p3,col,l)
   end
  end
 end
end

function getzbuffer(x,y)
 local i=y*128+x+1
 return game.zbuffer[i]
end

function setzbuffer(x,y,z)
 local i=y*128+x+1
 game.zbuffer[i]=z
end

function psetz(x,y,z,col)
 if x<0 or x>128 or y<0 or y>128 then return end
 
 local zbuf=getzbuffer(x,y)
 if not zbuf or z<zbuf then
  setzbuffer(x,y,z)
  pset(x,y,col)
 end
end

function pset2(vec,col)
 pset(vec[1],vec[2],col)
end

function line2(v1,v2,col)
 line(v1[1],v1[2],v2[1],v2[2],col)
end

function dot(a,b)
 local res=0
 for i=1,#a do
  res+=a[i]*b[i]
 end
 return res
end

function matmult(a,b)
 local res=matrix.empty()
 
 for i=1,#a do
  for j=1,#b[1] do
   for k=1,#b do
    res[i][j]+=a[i][k]*b[k][j]
   end
  end
 end
 
 return res
end

function vecsubvec(v1,v2)
 local tmp={}
 for i=1,#v1 do
  add(tmp,v1[i]-v2[i])
 end
 return tmp
end

function vecaddvec(v1,v2)
 local tmp={}
 for i=1,#v1 do
  add(tmp,v1[i]+v2[i])
 end
 return tmp
end

function vecdiv(v,s)
 local tmp={}
 for i=1,#v do
  add(tmp,v[i]/s)
 end
 return tmp
end

function vecmult(v,s)
 local tmp={}
 for i=1,#v do
  add(tmp,v[i]*s)
 end
 return tmp
end

function cot(x)
 return cos(x)/sin(x)
end

function tan(x)
 return sin(x)/cos(x)
end

function cross3(a,b)
 return vec3(
  a[2]*b[3]-a[3]*b[2],
  a[3]*b[1]-a[1]*b[3],
  a[1]*b[2]-a[2]*b[1]
 )
end

function len(_vec)
 return sqrt(_vec[1]*_vec[1]+_vec[2]*_vec[2]+_vec[3]*_vec[3])
end

function normalize(_vec)
 local l=len(_vec)
 return vec3(_vec[1]/l,_vec[2]/l,_vec[3]/l)
end

function transform(c,t)
 local x,y,z,w
 
 -- this is an unrolled matrix mult coord * t_mat
 x=t[1][1]*c[1]+t[2][1]*c[2]+t[3][1]*c[3]+t[4][1]
 y=t[1][2]*c[1]+t[2][2]*c[2]+t[3][2]*c[3]+t[4][2]
 z=t[1][3]*c[1]+t[2][3]*c[2]+t[3][3]*c[3]+t[4][3]
 w=t[1][4]*c[1]+t[2][4]*c[2]+t[3][4]*c[3]+t[4][4]
 
 return vec3(x/w,y/w,z/w)
end

function project(_coord,_tmat)
 local point=transform(_coord,_tmat)
 local x=flr((point[1]+1)/2*128)
 local y=flr((-point[2]+1)/2*128)
 --print(z)
 return vec3(x,y,point[3])
end

--debug stuff
function dbpts(str,x,y,c)
 add(game.debugpts,{
  str=str,
  x=x,
  y=y,
  col=c or 6
 })
end

function dbvec(v,c)
 local buffer=""
 
 for i in all(v) do
  buffer=buffer..i..","
 end
 
 db(sub(buffer,1,-2),c)
end

function dbmat(a,c)
 db(matstr(a),c)
end

function db(str,c)
 local d= {str=str,col=c}
 add(game.debug,d)
end

function clear_db()
 game.debug={}
 game.debugpts={}
end

function matstr(a)
 local tmp=""
 for y=1,4 do
  for x=1,4 do
   tmp=tmp..a[y][x]..","
  end
  tmp=sub(tmp,1,-2).."\n"
 end
 return sub(tmp,1,-2)
end
-->8
--matrices

matrix={
 empty=function()
  return {{0,0,0,0},{0,0,0,0},{0,0,0,0},{0,0,0,0}}
 end,
 
 ident=function()
  return {{1,0,0,0},{0,1,0,0},{0,0,1,0},{0,0,0,1}}
 end,
 
 rotation=function(rot)
  local xcos,xsin=cos(rot[1]),sin(rot[1])
  local ycos,ysin=cos(rot[2]),sin(rot[2])
  local zcos,zsin=cos(rot[3]),sin(rot[3])
  
  local xrm={{1,0,0,0},{0,xcos,-xsin,0},{0,xsin,xcos,0},{0,0,0,1}}
  local yrm={{ycos,0,ysin,0},{0,1,0,0},{-ysin,0,ycos,0},{0,0,0,1}}
  local zrm={{zcos,-zsin,0,0},{zsin,zcos,0,0},{0,0,1,0},{0,0,0,1}}
  
  return matmult(matmult(xrm,yrm),zrm)
 end,
 
 trans=function(vec)
  return {{1,0,0,vec[1]},{0,1,0,vec[2]},{0,0,1,vec[3]},{0,0,0,1}}
 end,
 
 scale=function(vec)
  return {{vec[1],0,0,0},{0,vec[2],0,0},{0,0,vec[3],0},{0,0,0,1}}
 end,

 lookat=function(p,t,worldup)
  worldup=worldup or vec3(0,1,0)
  local f=normalize(vec3(p[1]-t[1],p[2]-t[2],p[3]-t[3]))
  local r=normalize(cross3(worldup,f))
  local u=cross3(f,r)
  
  local w=vec3(dot(r,p),dot(u,p),dot(f,p))
  
  return {{r[1],r[2],r[3],0},{u[1],u[2],u[3],0},{f[1],f[2],f[3],0},{w[1],w[2],w[3],1}}
 end,
 
 persp=function(fov,near,far)
  local h=cot(fov/2)
  local w=h/1
  local a=far/(far-near)
  local b=-near*far/(far-near)
  
  return {{w,0,0,0},{0,h,0,0},{0,0,a,b},{0,0,1,0}}
 end,
 
 persp2=function(fov,near,far)
  local s=1/tan(fov*0.5*pi/180)
  local a=-far/(far-near)
  local b=-far*near/(far-near)
  
  return {{s,0,0,0},{0,s,0,0},{0,0,a,-1},{0,0,b,0}}
 end,
 
 init=function(row,col)
  -- might not work correctly...
  local mat={}
  for y=1,col do
   mat[y]={}
   for x=1,row do
    mat[y][x]=0
   end
  end
  return mat
 end,
 
 test=function()
  return {{1,2,3,4},{5,6,7,8},{9,0,1,2},{3,4,5,6}}
 end,
 
 testres=function()
  return {{50,30,40,50},{122,78,104,130},{24,26,38,50},{86,54,72,90}}
 end
}
-->8
--mesh data

mesh_cube={
 vertices={
  --top
  vec3(-1,1,-1),
  vec3(1,1,-1),
  vec3(1,1,1),
  vec3(-1,1,1),
  
  --bottom
  vec3(-1,-1,-1),
  vec3(1,-1,-1),
  vec3(1,-1,1),
  vec3(-1,-1,1)
 },
 faces={
  --top
  vec3(1,2,3),
  vec3(1,4,3),
  
  --front
  vec3(2,1,6),
  vec3(1,5,6),
  
  --back
  vec3(3,4,7),
  vec3(4,7,8),
  
  --left
  vec3(1,4,8),
  vec3(5,1,8),
  
  --right
  vec3(2,3,7),
  vec3(6,2,7),
  
  --bottom
  vec3(7,5,6),
  vec3(8,7,5)
 },
 normals={
    --top
  vec3(0,1,0),
  vec3(0,1,0),
  
  --front
  vec3(0,0,-1),
  vec3(0,0,-1),
  
  --back
  vec3(0,0,1),
  vec3(0,0,1),
  
  --left
  vec3(-1,0,0),
  vec3(-1,0,0),
  
  --right
  vec3(1,0,0),
  vec3(1,0,0),
  
  --bottom
  vec3(0,-1,0),
  vec3(0,-1,0)
 },
 texture=texture(8,0,23,15)
}
__gfx__
00000000666566566566566600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000665556555565556600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700655155555555155600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000551155566555115500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000655518666681555600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007006655566cc665556600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555566cccc66555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000065566cc77cc6655600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000065566cc77cc6655600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555566cccc66555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000006655566cc665556600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000655518666681555600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000551155566555115500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000655155555555155600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000665556555565556600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666566566566566600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
