pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function _init()
 cls(1)
 poke(0x5f34,1)
 
 f=0
 
 pi=3.14159
 grad={}
 color_ramp={}
 
 maxx=128
 maxy=128
 
 screenw=32
 screenh=32
 
 xres=flr(128/screenw)
 yres=flr(128/screenh)
 
 y_idx=0
 
 draw=true
 debug=false
 
 interp=smoothstep
 
 local seed=nil
 init_grad(seed)
 init_color_ramp()
end

function _update60()
 if not draw then
  draw=btnp(❎)
 end
 
 if btnp(🅾️) then 
  init_grad() 
  draw=true
 end
 
 if btn(⬆️) then
  --y_idx=max(0,y_idx-1)
  y_idx+=1
  draw=true
 elseif btn(⬇️) then
  --y_idx=min(maxy,y_idx+1)
  y_idx=max(0,y_idx-1)
  --y_idx-=1
  draw=true
 end
 
 f=sin(time())+1
 f/=2
end

function _draw()
 draw_cloud()
 --draw_graph()
end

function draw_cloud()
 if draw then
  cls()
	 for y=0,screenh do
	 	for x=0,screenw do
	 		
	 		local x0=(x/screenw)*1
	 		local y0=(y/screenh)*1
	 		local v=perlin(x0,y0)
	 		
	 		local x1=(x/screenw)*2
	 		local y1=y+y_idx
	 		
	 		y1=(y1/screenh)*2
	 		v*=perlin(x1,y1)
	 		
	 		local x2=x+y_idx
	 		local y2=(y/screenh)*4
	 		
	 		x2=(x2/screenw)*4
	 		v/=perlin(x2,y2)
	 		
	 		local c=col(10,min(127,v*127))

	 	 rectfill(x*xres,y*yres,x*xres+xres,y*yres+yres,c)
	 	 --pset(x,y,c)
			end
	 end
	 
	 draw=false
	 if debug then
	  color(7)
	  print(y_idx)
	 end
	end
end

function draw_graph()
 cls()
	for x=0,128 do
		local x0,y0=(x/1741)*maxx,y_idx
		local v=perlin(x0,y0)+1
		v/=2
		pset(x,128-flr(v*128),8)
	end
end
-->8
-- noise stuff
function init_grad(seed)
 grad={}
 if seed then srand(seed) end
 
 for y=0,maxy do
  grad[y]={}
 	for x=0,maxx do
 	 -- initiates a vector and 
 	 -- rotates it randomly in
 	 -- a 360 deg angle
 	 
 		local v=vec2(1,0)
 		v=rot2d(v,rnd(pi*2))
 	 v:norm()
 		grad[y][x]=v
 		--print(v.x..","..v.y)
		end
 end
end

function dot_grad(ix,iy,x,y)
 local dx,dy=x-ix,y-iy
 
 --print("grad:"..grad[iy][ix].x..","..grad[iy][ix].y)
 --print("d:"..dx..","..dy)
 --print(ix..","..iy)
 return dx*grad[iy][ix].x + dy*grad[iy][ix].y
end

function perlin(x,y)
 local x0,x1=flr(x),flr(x)+1
 local y0,y1=flr(y),flr(y)+1
 
 x0=x0%maxx
 y0=y0%maxy
 x1=x1%maxx
 y1=y1%maxy

 local sx,sy=x-x0,y-y0
 local n0,n1,ix0,ix1
 
 n0=dot_grad(x0,y0,x,y)
 n1=dot_grad(x1,y0,x,y)
 ix0=interp(n0,n1,sx)
 
 n0=dot_grad(x0,y1,x,y)
 n1=dot_grad(x1,y1,x,y)
 ix1=interp(n0,n1,sx)
 
 --print("asdf:"..n0..","..n1)
 
 return (interp(ix0,ix1,sy)+1)/2
end
-->8
-- util
-- linear algebra stuff
function vec2(x,y)
 return {
  x=x,
  y=y,
  norm=function(self)
   local l=len(self.x,self.y)
   self.x/=l
   self.y/=l
   return self
  end
 }
end

function len(x,y)
 return sqrt(x^2+y^2)
end

function rot2d(vec,r)
 return vec2(
  vec.x*cosr(r)-vec.y*sinr(r),
  vec.x*sinr(r)+vec.y*cosr(r)
 )
end

function rot(x,y,r)
 return x*cosr(r)-y*sinr(r),x*sinr(r)+y*cosr(r)
end

function rad2deg(r)
 return r*180/pi
end

function deg2rad(d)
 return d*pi/180
end

function sinr(r)
 return sin(r/(2*pi))
end

function cosr(r)
 return cos(r/(2*pi))
end

function tanr(r)
 return sinr(r)/cosr(r)
end

-- maths stuff
function decimal(x)
 return x-flr(x)
end

function lerp(x1,x2,w)
 return (1-w)*x1+w*x2
end

function smoothstep(h1,h2,t)
	t=mid(t,0,1)
	t=(t*t*(3-2*t))
	return (h2-h1)*t+h1
end
-->8
-- color stuff
-- stolen from commancher
function init_color_ramp()
 -- color_ramp[x][y]
 -- x: base color (0-15)
 -- y: brightness (0-127)
 
 local gray_patterns={
  0b0.1000000000000000,
  0b0.1000000000100000,
  0b0.1000000010100000,
  0b0.1010000010100000,
  0b0.1010010010100000,
  0b0.1010010010100001,
  0b0.1010010010100101,
  0b0.1010010110100101,
  0b0.1110010110100101,
  0b0.1110010110110101,
  0b0.1110010111110101,
  0b0.1111010111110101,
  0b0.1111010111110111,
  0b0.1111110111110111,
  0b0.1111110111111111,
  0b0.1111111111111111
 }
 local pico_palette={
  {0,0,0},
  {.11,.17,.33},
  {.49,.15,.33},
  {0,.53,.32},
  {.67,.32,.21},
  {.37,.34,.31},
  {.76,.76,.78},
  {1,.95,.91},
  {1,0,.3},
  {1,.64,0},
  {1,.93,.15},
  {0,.89,.21},
  {.16,.68,1},
  {.51,.46,.61},
  {1,.47,.66},
  {1,.80,.67}
 }
 local shade_list={
  {0,1,1},
  {0,1,1},
  {0,1,2,2},
  {0,1,3,11,7,7},
  {0,1,2,4,9,7,7},
  {0,1,5,6,7,7},
  {0,1,5,13,6,7,7},
  {0,1,5,13,6,7,7},
  {0,1,2,8,14,14},
  {0,1,2,4,9,7,7},
  {0,1,2,4,9,10,7,7},
  {0,1,3,11,7,7},
  {0,1,12,12},
  {0,1,13,6,7,7},
  {0,1,13,6,7,7},
  {0,1,8,14,7,7},
  {0,1,14,15,7,7}
 }
 
	color_ramp={}
	for i=1, #pico_palette do
		pico_palette[i][4]=(pico_palette[i][1]+pico_palette[i][2]+pico_palette[i][3])/3
	end
	--shade_list={0,1,2,4,9,15,15}
	for c=0,15 do
			color_ramp[c]={}
		for n=0,127 do
			local target_shade = n/128
			local i=1
			local rr=pico_palette[shade_list[c+1][i]+1][4]
			while(rr<=target_shade and i<#shade_list[c+1])do
				i+=1
				rr=pico_palette[shade_list[c+1][i]+1][4]
			end
			local right_color=shade_list[c+1][i]
			local left_color=shade_list[c+1][i-1]
			local lr=pico_palette[left_color+1][4]
			local span=rr-lr
			local delta=target_shade-lr
			local bright= delta/span
			local colo = bor(0x1000,shl(right_color,4))
			colo = bor(colo,left_color)
			color_ramp[c][n] = bor(colo,gray_patterns[flr(bright*16)])
		end
	end
end

function col(base,bright)
 return color_ramp[base][flr(bright)]
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
7a7a7aaaaaaaa9a999999994949494949494944494449494949499949999a9a9aaaaaaaa7aaa7aaaaaaaaaa9a999999494944444422222222222222222222222
a7aaaaaa9a9a9a99994949494944444444444444444444444944494999499a999a9aaaaaaaaaaaaaaa9a9a9a9999494944442424222222121212121212122212
7a7a7a7aaaaaa9a999999499949494949494949494949494949494949999a9a9aaaaaaaaaaaaaaaaaaaaa9aaa9a9999994944444224222222222222222222222
a7a7aaaa9aaa99994999494944494444444444444444444444494949499999999a9aaaaaaaaaaaaaaaaa9a9a9999494944442424222212221222121212222222
7aaaaaaaa9a999999994949494949444944444444444944494449494949499949999a999a999a999a99999999994949494444442422222222222222222224242
aaaaaa9a9a9999994949494444444444444444444444444444444444494449499949999999999999999999494949494444442424222222122212221222122222
aa7aaaaaa9a9999994999494949444944444444444444444449494949494999999999999a9a9a9a9999999999499949444444242224222222222222222224242
aaaa9aaa9a9a99994949494944444444444444444444444444444444444949499999999999999999999999994949444944442424222222221222122222222222
aaa9a9a9a99999999494949494449444444444444444444444444444944494949494949499949994999494949494944444444242422222222222422242224442
9a9a9a99999949494944444444444444442444244424442444244444444444444944494949494949494949444444444444242422222222122212222222222424
aaaaa9a999a999999494949444944444444444444444444444444444444494949494949494949499949494949494449444444242224222222222222222424242
9a9a9a9a999949494949444444444444444424442444244444444444444444444449494949494949494949494444444424442424222222222222222222222424
a9a9a999999999949494944494444444444444444444444244424444444444444444944494449444944494449444444444424242422242224222422242424444
9a999999994949494944444444444424442424242424242424242424442444244444444444444444444444444444442424242422222222222222222224222424
a9a999a9999994949494949444444444444444444444424442444444444444444444449494949494949444944444444442444242224222222222224242424444
99999999499949494444444444444444244424242424242424242424244444444444444444444444444444444444244424242222222222222222222224242424
99999999999494949494944444444444444444444442444244424442444244424442444444444444444444444444444244424242422242224222424244424444
99999949494949444444444444444424442424242424242424242424242424242424242444244424442444242424242424242422222222222222242224244444
99999999949994949494449444444444444444444244424442424242424242444242444444444444444444444444424442424242224222422242424242444444
99999999494944494444444444444444244424242424242424242424242424242424242424442444444424442424242424242222222222222222222224244444
99999994949494949444944444444444444444444442444244424242424242424242424242424442444244424442444242424242424242424242444244449444
49494949494944444444444444244424242424242424242424242422242224222222242224222424242424242424242424222422222222222422242444244444
99999999949494944494444444444444444444444244424242424242424242424242424242424242424442444242424242424242424242424242424244444494
49994949494944444444444444442444242424242424242424242424242422222222222224242424242424242424242424242222222222222222242424444444
99949994949494449444444444444444444444444444444244424242424242424222422242424242424242424242444242424242424242424442444444449494
49494949494444444444444444444424442424242424242424242422242222222222222222222422242224222422242424222422242224222424242444444444
94999494949494944444444444444444444444444444424442424242424242422222224242424242424242424242424242424242424242424242444444449494
49494949444944444444444444444444244424242424242424242424222222222222222222222222242424242424242424242424222224242424242444444444
94949494949494449444944444444444444444444444444444424442424242422222422242224242424242424242444244424442444244424444444494449494
49444944444444444444444444444444442444244424242424242424242222222212222222222222242224222422242424242424242424242424442444444944
94949494949444944444444444444444444444444444444442444242424242422222222222424242424242424242424242424242424242424444444444949494
49494449444444444444444444444444444444442444242424242424242422222222222222222222222224242424242424242424242424242424444444444444
94949494949494449444944494449444944494444444444444444444444242424222422242224242424242424442444244424444444444444444944494949494
44444444444444444444444444444444444444444444444444242424242424222222222222222222242224222424242424242424242424244424444444444944
94949494949444944444444444944494444444444444444444444444424242422222222222424242424242424242424442444444444444444444444494949494
44444444444444444444444444444444444444444444444424442424242422222222222222222222222224242424242424242424242424244444444444444949
94449494949494449444944494949494949494949494944494444444444444424222422242424242424244424442444444444444444444449444944494949494
44444444444444444444444444444444444444444444444444444444442424242222222222222422242224242424242444244424442444444444444449444949
94949494949444944494949494949494949494949494949444944444444442422242224242424242424242424244444444444444444444444444949494949494
44444444444444444444444444444444444444444444444444444444244424242222222222222222242424242424242444444444444444444444444444444949
94449494949494449494949494949494949494949494949494949494944444444242424242424442444244444444444494449444944494449494949494949994
44444444444444444444494449444949494949494949494449444444444444242422242224222424242424244424444444444444444444444444444449444949
44949494949494949494949494949494949494949494949494949494449444444242424242424242424444444444444444949494949494949494949494949494
44444444444444444444444444494949494949494949494944494444444424442222222224242424242424242444444444444444444444444444444444494949
94449444949494449494949499949994999999999999999999999994949494444444444444444444444494449444949494949494949494949494949494949994
44444444444444444444494449494949494949494949494949494949494944442424442444244424444444444444444449444944494449444944494449494949
44449494949494949494949494999999999999999999999999999499949494944444444444444444444444449494949494949494949494949494949494949494
44444444444444444444494949494949494949994999499949494949494944442424244424444444444444444444444444494949494944494449494949494949
4442444444444444944494949994999999999999a999a999a9999999999999949494949494949494949494949994999499999999999999949994999494949494
24244424444444444444494449494949994999999999999999999999994949494444444444444944494449494949494999499949494949494949494949494949
42444444444444449494949494999999999999999999999999999999999994949494949494949494949494949499999999999999999994999499949494949494
24244444444444444444444949494949999999999999999999999999499949494444444444444444444949494949494949999999499949494949494949494949
422244424444444494449494999499999999a999a9a9a9a9a9a9a9a9a9a999999994999499949994999999999999a999a9a9a9a9a99999999999999499949494
22222424242444244444494449494949999999999a999a999a999a9999999949494949494949494949499949999999999a999a99999999994949494949494944
224242424444444444449494949999999999a9a9a9a9a9a9a9a9a9a9a9a999999494949994999999999999999999a9a9a9a9a9a9a9a999999999949994949494
222224242424244444444444494949999999999999999999999a99999999999949494949494949494999999999999999999a999a999999994949494949494949
22224222424244424444949499949999a999a9a9a9a9aaa9aaa9aaa9aaa9a9a9999999999999a999a999a9a9a9a9aaa9aaaaaaaaa9a9a9a99999999999949494
1212222224222424442444444949994999999a999a999a9a9a9a9a9a9a9a9999994999499999999999999a999a999a9aaa9aaa9a9a9a99999999494949494944
222222424242424244449494949999999999a9a9a9a9a9aaaaaaaaaaa9aaa9a99999999999999999a9a9a9a9a9a9aaaaaaaaaaaaa9a9a9a99999999994949494
12222222242424244444444449494999999999999a9a9a9a9a9a9a9a9a9a99994999999999999999999999999a9a9a9a9aaa9aaa9a9a99999999494949494449
22212222422242424444944494949999a999a9a9a9a9aaa9aaa9aaaaaaa9a9a99999a999a999a999a9a9a9a9a9a9aaa9aaaaaaaaaaa9a9a99999999499949494
1212221222222422242444444949494999999a999a9a9a9a9a9a9a9a9a9a9a9999999999999999999a999a999a9a9a9aaa9aaa9a9a9a99999999494949494944
212222222242424244449494949499999999a9a9a9a9aaaaaaaaaaaaaaaaa9a99999999999a9a9a9a9a9a9a9a9a9aaaaaaaaaaaaa9a9a9a99999999994949494
12121222222222222424444449494949999999999a9a9a9a9a9a9a9a9a9a999a99999999999999999999999a9a9a9a9aaaaaaaaa9a9a99999999494949494449
212122212222422244429444949499949999a9a9a9a9aaa9aaa9aaaaaaa9a9a9a999a999a999a999a9a9a9a9a9a9aaa9aaaaaaaaa9a9a9999999999494949494
12111212221222222424444449444949999999999a999a9a9a9a9a9a9a9a9a99999999999999999999999a999a999a9a9a9a9a9a9a9999999949494949494944
212122222222224242444494949499999999a9a9a9a9a9aaaaaaaaaaaaaaa9a99999999999a9a9a9a9a9a9a9a9a9a9aaaaaaaaaaa9a9a9a99999999994949494
12121212222222222424444449494949999999999a9a9a9a9a9a9a9a9a9a9a9a9999999999999999999999999a9a9a9a9aaa9aaa9a9a99999999494949494444
212122212222422242429444949499949999a999a9a9aaa9aaa9aaa9aaa9a9a99999999999999999a999a999a9a9a9a9aaa9aaa9a9a9a9999999999494949494
12111212121222222422444449444949999999999a999a9a9a9a9a9a9a9a9a9999999999999999999999999999999a999a9a9a9a9a9999999949494949494944
212121212222222242424444949494999999a9a9a9a9a9a9aaaaaaaaa9aaa9a99999999999999999999999a9a9a9a9a9a9a9a9aaa9a999999999949994949494
1111121212222222242444444449494999999999999a9a9a9a9a9a9a9a9a99999999999999999999999999999999999a9a9a9a9a999999994999494949494449
211121212222222242424444949499949999a999a9a9a9a9a9a9a9a9a9a9a99999999999999999999999999999999999a999a9a9a99999999999999499949494
11111212121222122422444449444949994999999a999a999a9a9a9a9a9999999949994949494949494999499949999999999999999999494949494949494944
21212121222222224242444494949499999999a9a9a9a9a9a9a9a9a9a9a9a9a999999999999999999999999999999999a9a9a9a9999999999999949994949494
111112121212222224244444444449499999999999999a9a9a9a9a9a9a9a99999999499949994999499949999999999999999999999999994949494949494949
2111212122212222424244449494999499999999a999a9a9a9a9a9a9a99999999994999499949494949494949994999499949999999999949994999499949494
111112111212221224224444444449499949999999999a999a999a99999999494949494949494949494949494949494949494949494949494949494949494949
1121212122222222424244449494949999999999a9a9a9a9a9a9a9a9a9a999999999949994949494949494949494949999999999999999999499949994949494
11111212121222222424444444444949499999999999999999999999999999994949494949494949494949494949494949494949494949494949494949494949
2111212122212222424244449494999499999999a999a999a9999999999999949494949494949444944494449444944494949494949494949994999499949994
11111211121222122422444444444949494999999999999999999999994949494944494444444444444444444444444444444944494449494949494949494949
1121212122222222424244449494949499999999999999a999999999999994999494949494949494449444944494949494949494949494949494949994999499
11111212121222222424444444444949494999999999999999999999499949494949444444444444444444444444444444444444494949494949494949494949
21112121222142224442944494949994999499999999999999999994999494949444444444444444444244424442444244424444944494949494999499999999
11111211121222222424444444444949494949499949994999494949494949444444444444242424242424242424242424242424444444444944494949499949
11112121222222224242444494949494999999999999999999999999949494944494444444444444424442424242424242444444444494949494949999999999
11111212121222222424444444444949494949999999999949994949494944444444444424442424242424242424242424242424444444444949494949494999
21112121222242424444944494949494999499949994999499949494949494444444444444424242424242224222422242424242444494449494949499999999
11111212121222222424444444444944494949494949494949494949494444444424242424242422222222222222222222222422242444444444494949499999
21212121222242424444444494949494949494999499949994999494949494944444444442424242424222422242224242424242444444449494949499999999
11111212122222222424444444444949494949494949494949494949444444444444242424242222222222222222222222222222242444444444494949499999
21212222422244424444944494949494949494949494949494949494949494444444444242424242422242222222222242224222444244449444949499949999
12111212222224244424444444444944494449444949494449444944444444444424242424222222222222222212221222222222242444244444494449499949
21212222224242424444444494949494949494949494949494949494949444444444424442424242222222222222222222222242424244449494949494999999
11121212222224242444444444444444494949494949494949494444444444442444242424242222222222222222222222222222242444444444444949499999
22214222424244444444944494949494949494949494949494949494944444444444444242424222222222222222222222222222424244429444949499949999
12122222242244244444444444444444494449444944494444444444444444442424242422222222221222121212121222122212242224244444444449499949
21222222424244444444449494949494949494949494949494949494449444444444424242422242222222222222222222222222424242444444949494949999
12122222242424444444444444444444444444444444444444444444444444442424242422222222222212221222122212222222222224244444444449494999
22224242444494449444944494449494949494949494949494949444944444444444424242424222222222222222222222222222422242424444949494949999
22122422442444444444444444444444444444444444444444444444444444442424242222222222221212121212121212122212222224224424444449494949
22224242444444444494949494949494949494949494949494949494449444444444424242422222222222222222222222222222224242424444949494949999
22222424444444444444444444444444444444444444444444444444444444442424242422222222122212221212121212121222222224244444444449494999
44424444949494949494949494949494944494449444944494449444944444444444424242222222222222222221222122212222222242424444944494949999
24244444444444444444444444444444444444444444444444444444444444442424242222222212121212121212121212121212221222222424444449444949
42424444949494949494949494949494949494949494949494949494449444444444424222422222222222222222212222222222222242424444449494949999
24244444444444444444444444444444444444444444444444444444444444442424242422222222122212121212121212121212222222222424444444494949
94449494949494949494949494949494944494449444944494449444944494444444424242222222222222212221222122212221222242224442444494949994
44444944494949494944494444444444444444444444444444444444444444444424242222222212121212121212121212121212121222222424444449444949
44949494949494949494949494949494949494949494449494949494949444444444424222422222222222222121212121212122222222224242444494949499
44444449494949494449444444444444444444444444444444444444444444442444242422222222121212121212121212121212122222222424444444444949
99949999999999999994949494949494944494449444944494449444949494444444444242222222222222212121212121212221222122224242444494949994
49494949994949494949494449444444444444444444444444444444444444444424242422222212121212121212121212121212121222122422442444444949
94999999999999999494949494949494949494944494949494949494949444944444424222422222222221222121212121212121222222224242444494949499
49494999499949494949494944444444444444444444444444444444444444444444242422221222121212121212121212121212121222222222244444444949
a999a9a9a9a999999999999494949494949494449444944494949494949494949444444242422222222222212121212121212121222122224222444294449994
99999a99999999994949494949444444444444444444444444444444494444444444242422222212121212121212121112111211121212122222242444444949
a9a9a9a9a9a999999999949494949494949494949494949494949494949494944444424442422222222221212121212121212121212222222242424494949494
99999999999999994949494944494444444444444444444444444444444944444444242422221222121212121212121211121212121212222222242444444949
aaaaaaaaaaa9a9a99999999494949494949494949494949494949494999494949444444442422222222122212121212121212121212122214222444294449494
aa9aaa9a9a9a9a999949494949494944444444444444444444444944494949444444442424222212121212121211121112111211121212122222242444444944
aaaaaaaaaaaaa9a99999949994949494949494949494949494949494949494949494444442422222222221212121212121212121212122222222424244449494
aaaa9aaa9a9a99999999494949494444444444444444444444444449494944494444244422222222121212121212111211111112121212122222242444444949
7aaa7aaaaaaaa9a99999999494949494949494949494949494949494999999949494944444444242422222222221222122212221222222224242444494449994
aaaaaaaaaa9a9a999999494949444944444444444444444449444949494949494944444424242422222212121212121212121212121222122422442444444949
7a7aaa7aaaaaa9a99999949994949494949494949494949494949494999994999494449444444242222222222222212221212122222222224242444494949494
aaaaaaaa9aaa9a9a9999494949494444444444444444444444444949494949494449444424242222222212221212121212121212121222222222244444444949

