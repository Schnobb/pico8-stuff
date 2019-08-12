pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
local colors={0,1,2,8,9,10,7}
local ri=0
local sway_rand={}
local buffer={}
local wind=0.6

function _init()
 lowres = true
 buffer_size = 127
 
 if lowres then
	 poke(0x5f2c,3)
	 buffer_size = 63
	end
 
 --cooling_p=0.15
 --sway_p=0.5
 
 --rand_len=256
 --cool_rand={}
 --sway_rand={}
 
 --colors={0,2,8,9,10,7}
 --sway_rand={}
 --buffer={}
 -- random index
 --ri=0
 
 --for i=0,rand_len do
 --	cool_rand[i]=flr(rnd(1+cooling_p))
 --end
 
 for i=0,256 do
  sway_rand[i]=flr(rnd(1+wind))
 end
 
	-- x=0 is a hack to have a value for the random sway
 for y=0,buffer_size do
  buffer[y]={}
  for x=0,buffer_size do
   if y>=buffer_size then
	   buffer[y][x]=#colors
   else
    buffer[y][x]=1
   end
  end
 end
 
 cls()
 music(0)
end

function _update()
 for x=0,buffer_size do
 	for y=1,buffer_size do
 	 buffer[y-1][x-sway_rand[ri]]=buffer[y][x]-flr(rnd(1.25))
 	 ri+=1
 	 if (ri>256) ri=0
 	end
 end
end

function _draw()
 for x=0,buffer_size do
 	for y=0,buffer_size do
 	 pset(x,y,colors[buffer[y][x]])
 	end
 end
end
__gfx__
00000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001221000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700012882100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000028999200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000089aaa800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070009a77a900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aa777a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000a7777a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
012000000072000720007200072000720007200072000720007200072000720007200072000720007200072000720007200072000720007200072000720007200072000720007200072000720007200072000720
002000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001510015100152001520015200152001510015100151001510015100000000000
012000000042000420004200042000420004200042000420004200042000420004200042000420004200042000420004200042000420004200042000420004200042000420004200042000420004200042000420
012000000032000320003200032000320003200032000320003200032000320003200032000320003200032000320003200032000320003200032000320003200032000320003200032000320003200032000320
012000000052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520
012000000062000620006200062000620006200062000620006200062000620006200062000620006200062000620006200062000620006200062000620006200062000620006200062000620006200062000620
012000000072000720007200072000720007200072000720007200072000720007200072000720007200072000720007200072000720007200072000720007200072000720007200072000720007200072000000
__music__
01 00414344
00 00414344
00 00014344
00 41424344
00 42434344
00 42434344
00 43424344
00 43444344
00 44424344
00 44414344
00 44424344
00 45434344
00 46424344
00 46424344
00 46424344
00 46424344
00 46424344

