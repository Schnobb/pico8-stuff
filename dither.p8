pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function _init()
	interp_list={
		{f=lerp,name="lerp"},
		{f=smoothstep,name="smoothstep"},
		{f=smootherstep,name="smootherstep"}
	}

	interp_idx=0
	interp=interp_list[interp_idx+1].f

	color_res=32
	bright_pat=nil
	init_colors(color_res)
end

function _update()
	local regen=false
	if btnp(⬅️) then
	 interp_idx=(interp_idx-1)%#interp_list
	 regen=true
	elseif btnp(➡️) then
	 interp_idx=(interp_idx+1)%#interp_list
	 regen=true
	end
	
	if btn(⬆️) then
	 color_res=mid(8,color_res+1,256)
	 regen=true
	elseif btn(⬇️) then
	 color_res=mid(8,color_res-1,256)
	 regen=true
	end
	
	if btnp(❎) then
	 bright_pat=gen_rnd_pat()
	 regen=true
	end
	
	interp=interp_list[interp_idx+1].f
	
	if regen then
	 init_colors(color_res,bright_pat)
	end
end

function _draw()
	cls()
	local maxy=16
	local h=128/maxy
	
	for y=0,maxy-1 do
	 for x=0,128 do
	  rectfill(x,y*h,x+1,y*h+h,hcolor(y%16,x/128))
	 end
	end
	
	color(7)
	local msg=interp_list[interp_idx+1].name
	msg=msg.." - ".."res: "..color_res
	print(msg)
end
-->8
--colors

function init_colors(res,bright)
 -- enable color fill patterns
 poke(0x5f34,1)
 
 -- res: resolution of brightness gradient, default 128
 res=res or 128
 
 bright=bright or {
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
 
 local hues={
  {0},
  {0,1},
  {0,1,2},
  {0,1,3},
  {0,1,2,4},
  {0,1,5},
  {0,1,5,6},
  {0,1,5,6,7},
  {0,1,2,8},
  {0,1,2,4,9},
  {0,1,2,4,9,10,7},
  {0,1,3,11,11,7},
  {0,1,13,12,7},
  {0,1,13},
  {0,1,8,14},
  {0,1,4,14,15}
 }
 
	colors={res=res}
	
	for i=0,#hues-1 do
 	local h=hues[i+1]
 	local hi=0
 	local hstep=res\(#h-1)
		colors[i]={}
			
		for j=0,res do
		 local b=interp(0,#bright,(j%hstep)/hstep)
		 if j%hstep==0 then 
		  hi=hi+1
		 end
		 
		 -- setting first bit of the color
		 -- this enables the fill pattern stuff
		 local cleft=bor(0x1000,h[hi])
		 local cright=h[min(hi+1,#h)]
		 
		 colors[i][j]=bor(cleft,shl(cright,4))
		 colors[i][j]+=bright[flr(b)+1]
		end
	end
end

function hcolor(base,light)
	local l=min(light,1)*colors.res
	return colors[base][flr(l)]
end
-->8
-- utils

function lerp(x1,x2,w)
 return (1-w)*x1+w*x2
end

function smoothstep(x1,x2,w)
	w=mid(w,0,1)
	w=(w*w*(3-2*w))
	return (x2-x1)*w+x1
end

function smootherstep(x1,x2,w)
	w=mid(w,0,1)
	w=w*w*w*(w*(w*6-15)+10)
	return (x2-x1)*w+x1
end

function round(x)
 if x-flr(x)>=0.5 then
  return ceil(x)
 else
  return flr(x)
 end
end
-->8
-- wip
function init_colors_wip(res)
 -- enable color fill patterns
 poke(0x5f34,1)
 
 -- res: resolution of brightness gradiant, default 128
 res=res or 128
 
 -- hues: 
 --  s: shade, pico-8 color
 --  l: lightness, by sampling color in paint
 local hues={
  {s={0},l=0},
  {s={0,1,1},l=53},
  {s={0,1,2,2},l=77},
  {s={0,1,3,3},l=64},
  {s={0,1,2,4,4},l=106},
  {s={0,1,5,5},l=82},
  {s={0,1,5,6,6},l=185},
  {s={0,1,5,6,7,7},l=229},
  {s={0,1,2,8,8},l=120},
  {s={0,1,2,4,9,9},l=120},
  {s={0,1,2,4,9,10},10,l=138},
  {s={0,1,3,11,11},l=107},
  {s={0,1,13,12,12},l=139},
  {s={0,1,13,13},l=129},
  {s={0,1,8,13,14,14},l=176},
  {s={0,1,4,9,14,15,15},l=200}
 }
 
	colors={res=res}
	
	for i=0,15 do
 	local hue=hues[i]
 	local s=hue.s
 	local si=1
 	local sstep=res\#s
		colors[i]={}
			
		for j=0,res do
		 --local cleft,cright,lleft,llright
		 if j>0 and j%sstep==0 then si+=1 end
		 
		 local cleft=s[si]
		 local cright=s[si+1]
		 colors[i][j]=bor(cleft,shl(cright,8))
		 
		end
	end
end

function next_rnd_pat(prev)
 while prev!=0xffff do
  local bit=flr(rnd(16))
  if band(2^bit,prev)==0 then
   return bor(2^bit,prev)
  end
 end
 
 return nil
end

function gen_rnd_pat()
 local pats={0}
 
 for i=1,16 do
  local n=next_rnd_pat(pats[i])
  add(pats,n)
 end
 
 for i=1,#pats do
 	pats[i]=band(0x0000.ffff,pats[i]>>16)
 end
 
 return pats
end
__gfx__
00000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000013b70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
