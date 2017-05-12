helper = {}
Logs = class(function(acc)
end)
function Logs:Init()

  helper = Helper()
  helper:Init()
  
  local strTime = os.date('%Y-%m-%d') .. ' ' .. tostring(helper:getHRTime2())
  helper:AppendInFile(settings.logFile, strTime ..'\n')
  helper:AppendInFile(settings.logFile, strTime ..' Robot started \n')
  helper:AppendInFile(settings.logFile, strTime ..'\n')
  
end

function Logs:add(text)

  helper:AppendInFile(settings.logFile, os.date('%Y-%m-%d') .. ' ' .. tostring(helper:getHRTime2()) .. ' ' .. text ..'\n')
  
end



