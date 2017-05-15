--common classes
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\class.lua")

dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Helper.lua")


function OnInit(path)
	helper= Helper()
	helper:Init()



end
--главная функция робота, которая гоняется в цикле
function main()

message('test time functions in class Helper')
message('getHRTime4: '..tostring(helper:getHRTime4()))
message('getHRTime3: '..tostring(helper:getHRTime3(10)))
message('getHRTime2: '..tostring(helper:getHRTime2()))
message('getHRTime:  '..tostring(helper:getHRTime()))
message('getMiliSeconds: '..tostring(helper:getMiliSeconds()))
message('getMiliSeconds_trans_id: '..tostring(helper:getMiliSeconds_trans_id()))


end