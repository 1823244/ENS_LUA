--этот класс создает таблицу с логами и показывает ее в терминале
helper = {}
local window = {}
LogsToScreen = class(function(acc)
end)
function LogsToScreen:Init()

  helper = Helper()
  helper:Init()
  
  window = Window()
  window:Init('LOGS:: '..settings.TableCaption, {'Time_','Message_'})
  
 
 --[[ local strTime = os.date('%Y-%m-%d') .. ' ' .. tostring(helper:getHRTime2())
  helper:AppendInFile(settings.logFile, strTime ..'\n')
  helper:AppendInFile(settings.logFile, strTime ..' Robot started \n')
  helper:AppendInFile(settings.logFile, strTime ..'\n')
  --]]
end

function LogsToScreen:add(text)

	local timetolog = os.date('%Y-%m-%d') .. ' ' .. tostring(helper:getHRTime2())
	--message(text)
	window:AddRow({timetolog, text},"")
  --helper:AppendInFile(settings.logFile, os.date('%Y-%m-%d') .. ' ' .. tostring(helper:getHRTime2()) .. ' ' .. text ..'\n')
  
end

function LogsToScreen:CloseTable()

	window:Close()
	
end

