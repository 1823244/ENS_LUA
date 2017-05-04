helper = {}
Logs = class(function(acc)
end)
function Logs:Init()

  helper = Helper()
  helper:Init()
  
  helper:AppendInFile(settings.logFile, os.date('%Y-%m-%d') .. ' ' .. tostring(helper:getHRTime2()) ..' Robot started \n')
  
end

function Logs:add(text)

  helper:AppendInFile(settings.logFile, os.date('%Y-%m-%d') .. ' ' .. tostring(helper:getHRTime2()) .. ' ' .. text ..'\n')
  
end



