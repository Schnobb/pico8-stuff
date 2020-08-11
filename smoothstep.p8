pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function smoothstep(h1,h2,t)
	t=mid(t,0,1)
	t=(t*t*(3-2*t))
	return (h2-h1)*t+h1
end

function drawline(t,c)
 local h1=(sin(t/60)+1)*0.5
 local h2=(cos(t/60)+1)*0.5
 for _x=0,127 do
  local _x2=_x/128
  local _y=smoothstep(h1,h2,_x2)
  _y=(128-16)*_y + 8
  pset(_x,_y,c)
 end
end

function _init()
 frame=0
 dist=2
 linecol={8}
 beatcol={0,1,1,2,8,8,9,10,7,7}
 beat=0
 max_beat=6
 music(0)
end

function _update60()
 beat=max(0,beat-1)
 if frame%(16*2)==0 then
  beat=max_beat
 end
 frame+=1
end

function _draw()
 if beat>0 then
  cls(7)
 else
  cls(0)
 end
 
 local l=linecol
 
 if beat>0 then
  l=beatcol
 end
 
 for i=0,#l-1 do
  --print(linecol[i+1])
  drawline(frame-i*dist,l[i+1])
 end
end
__gfx__
0000000012889a770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0101000027600386003760034600326002d600296001f600196000d60001600026000260002600006000060000600006000060000600000000000000000000000000000000000000000000000000000000000000
01100000276531c6161d6161e616276531c6111d6111e611276531c6161d6161e616276531c6111d6111e611276531c6161d6161e616276531c6111d6111e611276531c6161d6161e616276531c6111d6111e611
011000000037300000000000000000373000000000000000003730000000000000000037300000000000000000373000000000000000003730000000000000000037300000000000000000373000000000000000
011000000c3510c3510c3510c3510c3510c3510c3510c3520c3520c3520c3520c3520c3520c3520c3520c351003010c3010c3010c3010c3010c3010c3010c3050c3000c3000c3000c3000c3000c3000c3000c300
__music__
01 01024344
00 01024344
00 01020344
02 01020344
