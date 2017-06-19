--этот класс создает таблицу с логами и показывает ее в терминале
helper = {}
local window = {}
LogsToScreen = class(function(acc)
end)

--Parameters
--position - table, coordinates of window x, y, dx, dy. for function SetWindowPos
--extended - boolean - если Да, то создается расширенная таблица, с полями для счета и бумаги
function LogsToScreen:Init(position, extended)

	helper = Helper()
	helper:Init()
  
	local columns = {}
	window = Window()
	if extended ~= nil then
		if extended == true then
			columns = {'Time_','Account','Depo','Sec','Class','Message_'}
		else
			columns = {'Time_','Message_'}
		end
	else
		columns = {'Time_','Message_'}
	end
	if position ~= nil then
		window:Init('LOGS:: '..settings.TableCaption, columns, position)
	else
		window:Init('LOGS:: '..settings.TableCaption, columns)
	end
 
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

--выводит информацию в расширенный лог
--window - класс с главной таблицей
--row - число, номер строки в главной таблице
function LogsToScreen:add2(main_window, row, account, depo, sec, class, text)

	local timetolog = os.date('%Y-%m-%d') .. ' ' .. tostring(helper:getHRTime2())
	
  --helper:AppendInFile(settings.logFile, os.date('%Y-%m-%d') .. ' ' .. tostring(helper:getHRTime2()) .. ' ' .. text ..'\n')

	if main_window~=nil and row~=nil then
		sec 	= main_window:GetValueByColName(row, 'Ticker').image
		class 	= main_window:GetValueByColName(row, 'Class').image
		account = main_window:GetValueByColName(row, 'Account').image
		depo 	= main_window:GetValueByColName(row, 'Depo').image
	end
  
	local rowNum = InsertRow(window.hID, -1)
		
	window:SetValueByColName(rowNum, 'Time_',timetolog)
	window:SetValueByColName(rowNum, 'Account', account)
	window:SetValueByColName(rowNum, 'Depo', depo)
	window:SetValueByColName(rowNum, 'Sec', sec)
	window:SetValueByColName(rowNum, 'Class', class)
	window:SetValueByColName(rowNum, 'Message_', text)

  
end
