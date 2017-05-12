--common classes
dofile ("c:\\WORK\\lua\\ENS_LUA_Common_Classes\\class.lua")

dofile ("c:\\WORK\\lua\\ENS_LUA_Common_Classes\\Helper.lua")



--dofile ("c:\\WORK\\lua\\ENS_LUA_Common_Classes\\logs.lua")

function OnInit(path)
	helper= Helper()
	helper:Init()



end
--главная функция робота, которая гоняется в цикле
function main()

message('test time functions in class Helper')
message(tostring(helper:getHRTime4()))
message(tostring(helper:getHRTime3(10)))
message(tostring(helper:getHRTime2()))
message(tostring(helper:getHRTime()))

end