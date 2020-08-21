pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function _init()
 poke(0x5f34,1)
 init_color_ramp()
end

function _update60()
	
end

function _draw()
 cls()
 local maxy=16
	local h=128/maxy
	
	for y=0,maxy-1 do
	 for x=0,128 do
	  rectfill(x,y*h,x+1,y*h+h,hcolor(y,x/128))
	 end
	end
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

function hcolor(base,light)
	local l=light*128
	return color_ramp[base][flr(l)]
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
