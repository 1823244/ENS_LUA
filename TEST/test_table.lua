--common classes
dofile ("c:\\WORK\\lua\\ENS_LUA_Common_Classes\\class.lua")

dofile ("c:\\WORK\\lua\\ENS_LUA_Common_Classes\\Helper.lua")



--dofile ("c:\\WORK\\lua\\ENS_LUA_Common_Classes\\logs.lua")

function OnInit(path)
	helper= Helper()
	helper:Init()



end
--������� ������� ������, ������� �������� � �����
function main()

	t = {}
	t['321'] = 12
	
	--message(tostring(t['321']))
	message(tostring(t[0]))

end