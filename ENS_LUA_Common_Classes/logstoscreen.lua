--этот класс создает таблицу с логами и показывает ее в терминале
--также он дублирует логи в таблицу SQLite
helper = {}
helperGrid = {}

local window = {}
LogsToScreen = class(function(acc)
end)

--Parameters
--position - table, coordinates of window x, y, dx, dy. for function SetWindowPos
--extended - boolean - если Да, то создается расширенная таблица, с полями для счета и бумаги
function LogsToScreen:Init(position, extended)

	helper = Helper()
	helper:Init()
  
	helperGrid= HelperGrid()
	helperGrid:Init()
  
	--[[
	local columns = {}
	window = Window()
	if extended ~= nil then
		if extended == true then
			columns = {'Time_','robot_id','Account','Depo','Sec','Class','Message_'}
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
	--]]
 
	self.logs_window = nil
	self:createTableLogs()
 
 --[[ local strTime = os.date('%Y-%m-%d') .. ' ' .. tostring(helper:getHRTime2())
  helper:AppendInFile(settings.logFile, strTime ..'\n')
  helper:AppendInFile(settings.logFile, strTime ..' Robot started \n')
  helper:AppendInFile(settings.logFile, strTime ..'\n')
  --]]
end

function LogsToScreen:createTableLogs()
	
	local logs_window = QTable.new()
	if not logs_window then
		message("error creation table logs_window!", 3)
		return false
	else
		--message("table with id = " ..logs_window.t_id .. " created", 1)
	end
	
	
	logs_window:AddColumn("row",			QTABLE_INT_TYPE, 5) --номер строки в главной таблице. внешний ключ!!!
	logs_window:AddColumn("Time_",			QTABLE_STRING_TYPE, 20)
	logs_window:AddColumn("robot_id",		QTABLE_CACHED_STRING_TYPE, 1)
	logs_window:AddColumn("Account",		QTABLE_CACHED_STRING_TYPE, 1)
	logs_window:AddColumn("Depo",			QTABLE_CACHED_STRING_TYPE, 1)
	logs_window:AddColumn("Sec",			QTABLE_CACHED_STRING_TYPE, 10)
	logs_window:AddColumn("Class",			QTABLE_CACHED_STRING_TYPE, 1)
	logs_window:AddColumn("Message_",		QTABLE_STRING_TYPE, 200)
	
	
	logs_window:SetCaption("logs_window")
	
	self.logs_window = logs_window
	
	logs_window:Show()
	
	---[[
	if settings.log_position ~= nil then
		if settings.log_position.x ~= nil and settings.log_position.y ~= nil and settings.log_position.dx~=nil and settings.log_position.dy ~= nil then
			SetWindowPos(logs_window.t_id, settings.log_position.x, settings.log_position.y, settings.log_position.dx, settings.log_position.dy)
		end 
	end
	--]]
	
	self.logs_window = logs_window
	
	return true
	
end

function LogsToScreen:add(text)

	local timetolog = os.date('%Y-%m-%d') .. ' ' .. tostring(helper:getHRTime2())
	--message(text)
	window:AddRow({timetolog, text},"")
  --helper:AppendInFile(settings.logFile, os.date('%Y-%m-%d') .. ' ' .. tostring(helper:getHRTime2()) .. ' ' .. text ..'\n')
  
end

function LogsToScreen:CloseTable()

	--window:Close()
	DestroyTable(self.logs_window.t_id)
	
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
  
  --[[
	local rowNum = InsertRow(window.hID, -1)
		
	window:SetValueByColName(rowNum, 'Time_',timetolog)
	window:SetValueByColName(rowNum, 'robot_id', settings.robot_id)
	window:SetValueByColName(rowNum, 'Account', account)
	window:SetValueByColName(rowNum, 'Depo', depo)
	window:SetValueByColName(rowNum, 'Sec', sec)
	window:SetValueByColName(rowNum, 'Class', class)
	window:SetValueByColName(rowNum, 'Message_', text)
--]]

	local newR = self.logs_window:AddLine()
	
	self.logs_window:SetValue(newR, "row", 			row)
	self.logs_window:SetValue(newR, "Time_", 		timetolog)
	self.logs_window:SetValue(newR, "robot_id", 	settings.robot_id)
	
	self.logs_window:SetValue(newR, "Sec", 			sec)
	self.logs_window:SetValue(newR, "Class", 		class)
	self.logs_window:SetValue(newR, "Account", 		account)
	self.logs_window:SetValue(newR, "Depo", 		depo)
	
	self.logs_window:SetValue(newR, "Message_", 	text)
	
	
	
  --добавим запись в лог SQLite
	helperGrid:addRowToLogsSQLite(row, timetolog, account, depo, sec, class, text) 
  
end
