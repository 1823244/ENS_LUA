--common classes
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\class.lua")

local math_abs = math.abs

--������� ������� ������, ������� �������� � �����
function main()

message(tostring(math_abs(-4)))

end