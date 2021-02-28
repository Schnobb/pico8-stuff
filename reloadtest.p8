pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- unpack data & models
local cart_id,mem
local cart_progress=0
function mpeek()
	if mem==0x4300 then
		cart_progress=0
		cart_id+=1
		reload(0,0,0x4300,"vracing_"..cart_id..".p8")
		mem=0
	end
	local v=peek(mem)
	if mem%779==0 then
		cart_progress+=1
		rectfill(0,120,shl(cart_progress,4),127,cart_id%2==0 and 1 or 7)
		flip()
	end
	mem+=1
	return v
end

-- w: number of bytes (1 or 2)
function unpack_int(w)
  	w=w or 1
	local i=w==1 and mpeek() or bor(shl(mpeek(),8),mpeek())
	return i
end
-- unpack 1 or 2 bytes
function unpack_variant()
	local h=mpeek()
	-- above 127?
	if band(h,0x80)>0 then
		h=bor(shl(band(h,0x7f),8),mpeek())
	end
	return h
end
-- unpack a float from 1 byte
function unpack_float(scale)
	local f=shr(unpack_int()-128,5)
	return f*(scale or 1)
end
-- unpack a double from 2 bytes
function unpack_double(scale)
	local f=(unpack_int(2)-16384)/128
	return f*(scale or 1)
end
-- unpack an array of bytes
function unpack_array(fn)
	local n=unpack_variant()
	for i=1,n do
		fn(i)
	end
end
-- unpack a vector
function unpack_v(scale)
	return {unpack_double(scale),unpack_double(scale),unpack_double(scale)}
end

-- valid chars for model names
local itoa='_0123456789abcdefghijklmnopqrstuvwxyz'
function unpack_string()
	local s=""
	unpack_array(function()
		local c=unpack_int()
		s=s..sub(itoa,c,c)
	end)
	return s
end

function unpack_face(verts)
	local f={flags=unpack_int(),c=unpack_int(),session=0xffff}
	-- shadows
	if(f.c==0x50) f.c=0x0150
	f.c+=0x1000.a5a5

	f.ni=band(f.flags,2)>0 and 4 or 3
	-- vertex indices
	-- quad?
	-- using the face itself saves more than 500kb!
	for i=1,f.ni do
		-- direct reference to vertex
		f[i]=verts[unpack_variant()]
	end
	return f
end

function unpack_model(model,scale)
	-- vertices
	local verts={}
	unpack_array(function()
		add(verts,unpack_v(scale))
	end)

	-- faces
	unpack_array(function()
		local f=unpack_face(verts)
		-- inner faces?
		if band(f.flags,8)>0 then
			f.inner={}
			unpack_array(function()
				add(f.inner,unpack_face(verts))
			end)
		end
		-- collision planes?
		local borders=band(shr(f.flags,5),0x7)		
		if borders>0 then
			f.borders={}
			local bi=unpack_int()
			for i=0,borders-1 do
				-- vertex index
				local v0=band(shr(bi,i*4),0xf)
				local v1=(v0+1)%f.ni
				-- get border vectors
				v0,v1=f[v0+1],f[v1+1]
				-- make a 2d plane vector
				local bn=make_v(v1,v0)
				bn[2]=0
				bn=v_normz(bn)
				add(f.borders,{v=v0,n={bn[3],0,-bn[1]}})
			end
		end
		-- normal
		f.n=v_normz(v_cross(make_v(f[1],f[f.ni]),make_v(f[1],f[2])))
		-- viz check
		f.cp=v_dot(f.n,f[1])

		add(model.f,f)
	end)
	return verts
end
function unpack_models()
	-- cars are in first data cart
	reload(0,0,0x4300,"downloads\\vracing_0.p8")
	cart_id,mem=0,0
	-- for all models
	unpack_array(function()
		local model,name,scale={lods={},lod_dist={}},unpack_string(),1/unpack_int()
		scale=1/32
		unpack_array(function()
			local d=unpack_double()
			assert(d<127,"lod distance too large:"..d)
			-- store square distance
			add(model.lod_dist,d*d)
		end)
  
		-- level of details models
		unpack_array(function()
			local lod={f={},vgroups={}}
			local verts=unpack_model(lod,scale)
			-- unpack vertex groups (as sub model)
			unpack_array(function()				
				local name=unpack_string()
				local vgroup={offset=unpack_v(scale),f={}}
				-- faces
				unpack_array(function()
					local f=unpack_face(verts)
					-- normal
					f.n=unpack_v()
					-- viz check
					f.cp=v_dot(f.n,f[1])

					add(vgroup.f,f)
				end)				
				lod.vgroups[name]=vgroup
			end)
		
			add(model.lods,lod)
		end)

		-- index by name
		--print(tostring(model),7)
		all_models[name]=model
	end)
end

function make_v(a,b)
	return {
		b[1]-a[1],
		b[2]-a[2],
		b[3]-a[3]}
end

function _init()
 cls(0)
 color(7)
 all_models={}
 unpack_models()

 --print(#all_models) 
 
 print(tostring(all_models),7)
 printh(tostring(all_models),"@clip")
end
-->8
-- vector & tools
function lerp(a,b,t)
	return a*(1-t)+b*t
end

function v_clone(v)
	return pack(unpack(v))
end
function v_dot(a,b)
	return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]
end
function v_scale(v,scale)
	v[1]*=scale
	v[2]*=scale
	v[3]*=scale
end
function v_add(v,dv,scale)
	scale=scale or 1
	return {
		v[1]+scale*dv[1],
		v[2]+scale*dv[2],
		v[3]+scale*dv[3]}
end
-- safe vector length
function v_len(v)
	local x,y,z=v[1],v[2],v[3]
	local d=max(max(abs(x),abs(y)),abs(z))
	if(d<0.001) return 0
	x/=d
	y/=d
	z/=d
	return d*sqrt(x*x+y*y+z*z)
end
function v_normz(v)
	local x,y,z=v[1],v[2],v[3]
	local d=x*x+y*y+z*z
	if d>0.001 then
		d=sqrt(d)
		return {x/d,y/d,z/d}
	end
	return v
end

function v_lerp(a,b,t)
	return {
		lerp(a[1],b[1],t),
		lerp(a[2],b[2],t),
		lerp(a[3],b[3],t)
	}
end
function v_cross(a,b)
	local ax,ay,az=a[1],a[2],a[3]
	local bx,by,bz=b[1],b[2],b[3]
	return {ay*bz-az*by,az*bx-ax*bz,ax*by-ay*bx}
end

function v2_cross(a,b)
	return a[1]*b[3]-a[3]*b[1]
end

-- x/z orthogonal vector
function v2_ortho(a,scale)
	return {-scale*a[3],0,scale*a[1]}
end

local v_up={0,1,0}

-- quaternion
function make_q(v,angle)
	angle/=2
	-- fix pico sin
	local s=-sin(angle)
	return {v[1]*s,
	        v[2]*s,
	        v[3]*s,
	        cos(angle)}
end

function m_from_q(q)
	local x,y,z,w=unpack(q)
	local x2,y2,z2=x+x,y+y,z+z
	local xx,xy,xz=x*x2,x*y2,x*z2
	local yy,yz,zz=y*y2,y*z2,z*z2
	local wx,wy,wz=w*x2,w*y2,w*z2

	return {
		1-(yy+zz),xy+wz,xz-wy,0,
		xy-wz,1-(xx+zz),yz+wx,0,
		xz+wy,yz-wx,1-(xx+yy),0,
		0,0,0,1}
end

-- matrix functions
function m_x_v(m,v)
	local x,y,z=v[1],v[2],v[3]
	return {m[1]*x+m[5]*y+m[9]*z+m[13],m[2]*x+m[6]*y+m[10]*z+m[14],m[3]*x+m[7]*y+m[11]*z+m[15]}
end
-- optimized 4x4 matrix mulitply
function m_x_m(a,b)
	local a11,a21,a31,_,a12,a22,a32,_,a13,a23,a33,_,a14,a24,a34=unpack(a)
	local b11,b21,b31,_,b12,b22,b32,_,b13,b23,b33,_,b14,b24,b34=unpack(b)

	return {
			a11*b11+a12*b21+a13*b31,a21*b11+a22*b21+a23*b31,a31*b11+a32*b21+a33*b31,0,
			a11*b12+a12*b22+a13*b32,a21*b12+a22*b22+a23*b32,a31*b12+a32*b22+a33*b32,0,
			a11*b13+a12*b23+a13*b33,a21*b13+a22*b23+a23*b33,a31*b13+a32*b23+a33*b33,0,
			a11*b14+a12*b24+a13*b34+a14,a21*b14+a22*b24+a23*b34+a24,a31*b14+a32*b24+a33*b34+a34,1
		}
end
function m_clone(m)
	return pack(unpack(m))
end

function make_m_from_euler(x,y,z)
		local a,b = cos(x),-sin(x)
		local c,d = cos(y),-sin(y)
		local e,f = cos(z),-sin(z)
  
  -- yxz order
  local ce,cf,de,df=c*e,c*f,d*e,d*f
	 return {
	  ce+df*b,a*f,cf*b-de,0,
	  de*b-cf,a*e,df+ce*b,0,
	  a*d,-b,a*c,0,
	  0,0,0,1}
end
function make_m_from_v_angle(up,angle)
	local fwd={-sin(angle),0,cos(angle)}
	local right=v_normz(v_cross(up,fwd))
	fwd=v_cross(right,up)
	return {
		right[1],right[2],right[3],0,
		up[1],up[2],up[3],0,
		fwd[1],fwd[2],fwd[3],0,
		0,0,0,1
	}
end
-- inline matrix vector multiply invert
-- inc. position
function m_inv_x_v(m,v)
	local x,y,z=v[1]-m[13],v[2]-m[14],v[3]-m[15]
	return {m[1]*x+m[2]*y+m[3]*z,m[5]*x+m[6]*y+m[7]*z,m[9]*x+m[10]*y+m[11]*z}
end

function m_set_pos(m,v)
	m[13]=v[1]
	m[14]=v[2]
	m[15]=v[3]
end
-- returns basis vectors from matrix
function m_right(m)
	return {m[1],m[2],m[3]}
end
function m_up(m)
	return {m[5],m[6],m[7]}
end
function m_fwd(m)
	return {m[9],m[10],m[11]}
end
-->8
-- converts anything to string, even nested tables
function tostring(any,quotestr)
    if type(any)=="function" then 
        return "function" 
    end
    if any==nil then 
        return "nil" 
    end
    if type(any)=="string" then
     if quotestr then
        return "\""..any.."\""
     else
      return any
     end
    end
    if type(any)=="boolean" then
        if any then return "true" end
        return "false"
    end
    if type(any)=="table" then
        local str = "{"
        for k,v in pairs(any) do
         if type(k)=="number" then
          str=str..tostring(v,true)..","
         else
          str=str..tostring(k,true)..": "..tostring(v,true)..","
         end
        end
        str=sub(str,1,#str-1)
        return str.."}"
    end
    if type(any)=="number" then
        return ""..any
    end
    return "unkown" -- should never show
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
