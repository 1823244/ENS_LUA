HelperGrid = class(function(acc)
end)

function HelperGrid:Init()
	self.orders = {}
	self.signals = {}
	self.db = nil
	self.logstoscreen = nil
end



--- Функции по раскраске строк/ячеек таблицы
function HelperGrid:Red(t_id, Line, Col)    -- Красный
   -- Если индекс столбца не указан, окрашивает всю строку
   if Col == nil then Col = QTABLE_NO_INDEX; end;
   SetColor(t_id, Line, Col, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0));
end;

function HelperGrid:Gray(Line, Col)   -- Серый
   -- Если индекс столбца не указан, окрашивает всю строку
   if Col == nil then Col = QTABLE_NO_INDEX; end;
   SetColor(t_id, Line, Col, RGB(200,200,200), RGB(0,0,0), RGB(200,200,200), RGB(0,0,0));
end;

function HelperGrid:Green(t_id, Line, Col)  -- Зеленый
   -- Если индекс столбца не указан, окрашивает всю строку
   if Col == nil then Col = QTABLE_NO_INDEX; end;
   SetColor(t_id, Line, Col, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0));
end;

function HelperGrid:createTableSignals()
	
	local signals = QTable.new()
	if not signals then
		message("error creation table Signals!", 3)
		return false
	else
		--message("table with id = " ..signals.t_id .. " created", 1)
	end

	signals:AddColumn("row",			QTABLE_INT_TYPE, 5) --номер строки в главной таблице. внешний ключ!!!
	signals:AddColumn("id",				QTABLE_INT_TYPE, 10)
	signals:AddColumn("dir",			QTABLE_CACHED_STRING_TYPE, 4)
	signals:AddColumn("account",		QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("depo",			QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("sec_code",	QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("class_code",	QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("date",			QTABLE_CACHED_STRING_TYPE, 10) --время свечи, на которой сформировался сигнал
	signals:AddColumn("time",			QTABLE_CACHED_STRING_TYPE, 10) --время свечи, на которой сформировался сигнал
	signals:AddColumn("price",			QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("MA",			QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("done",			QTABLE_STRING_TYPE, 10)
	
	signals:SetCaption("Signals")
	
	self.signals = signals

	
	signals:Show()
	
	return true
	
end

function HelperGrid:createTableOrders()
	
	local orders = QTable.new()
	if not orders then
		message("error creation table orders!", 3)
		return false
	else
		--message("table with id = " ..orders.t_id .. " created", 1)
	end
	
	orders:AddColumn("row",			QTABLE_INT_TYPE, 5) --номер строки в главной таблице. внешний ключ!!!
	orders:AddColumn("signal_id",		QTABLE_INT_TYPE, 10)
	orders:AddColumn("sig_dir",		QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("account",		QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("depo",			QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("sec_code",	QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("class_code",	QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("trans_id",		QTABLE_INT_TYPE, 10)
	orders:AddColumn("order",			QTABLE_INT_TYPE, 10)
	orders:AddColumn("trade",			QTABLE_INT_TYPE, 10)
	orders:AddColumn("qty",			QTABLE_INT_TYPE, 10) --количество из заявки
	orders:AddColumn("qty_fact",		QTABLE_INT_TYPE, 10) --количество из сделок
	
	
	
	orders:SetCaption("orders")
	
	self.orders = orders
	
	orders:Show()
	
	return true
	
end

--создает таблицу в базе SQLite. если таблица уже есть - она не пересоздается
function HelperGrid:create_sqlite_table_orders()
	local sql=[=[
          CREATE TABLE orders_
          (
		   rownum INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          
			row 		TEXT, --номер строки в главной таблице. внешний ключ!!!
			signal_id 	TEXT,
			sig_dir		TEXT,
			account		TEXT,
			depo		TEXT,
			sec_code	TEXT,
			class_code	TEXT,
			trans_id	TEXT,
			order_num	TEXT, --order нельзя! это похоже зарезервированное слово
			trade_num	TEXT,
			qty			TEXT,
			qty_fact	TEXT,
			reserve1	TEXT,--это запасные поля
			reserve2	TEXT,
			reserve3	TEXT,
			reserve4	TEXT,
			reserve5	TEXT,
			reserve6	TEXT,
			reserve7	TEXT,
			reserve8	TEXT,
			reserve9	TEXT,
			reserve0	TEXT
        
          );          
        ]=]
         
   self.db:exec(sql)
end

--создает таблицу в базе SQLite. если таблица уже есть - она не пересоздается
function HelperGrid:create_sqlite_table_signals()
	local sql=[=[
          CREATE TABLE signals
          (
		   rownum INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
		  
			row 		TEXT, --номер строки в главной таблице. внешний ключ!!!
			id 			TEXT,	--ID сигнала
			dir			TEXT,--направление сигнала
			account		TEXT,
			depo		TEXT,
			sec_code	TEXT,
			class_code	TEXT,
			date		TEXT,--дата и время закрывшейся свечи, которая дала сигнал
			time		TEXT,--дата и время закрывшейся свечи, которая дала сигнал
			price		TEXT,--значение цены на закрывшейся свече
			MA			TEXT,--значение скользящей на закрывшейся свече
			done		TEXT,--признак того, что сигнал полностью обработан
			reserve1	TEXT,--это запасные поля
			reserve2	TEXT,
			reserve3	TEXT,
			reserve4	TEXT,
			reserve5	TEXT,
			reserve6	TEXT,
			reserve7	TEXT,
			reserve8	TEXT,
			reserve9	TEXT,
			reserve0	TEXT
        
          );          
        ]=]
         
   self.db:exec(sql)
end

--добавляет строку в таблицу lua, а также вызывает функцию добавления строки в таблицу SQLite
function HelperGrid:addRowToOrders(row, trans_id, signal_id, signal_direction, qty, window) 
		
	local newR = self.orders:AddLine()
	
	self.orders:SetValue(newR, "row", 			row)
	self.orders:SetValue(newR, "trans_id", 		trans_id)
	self.orders:SetValue(newR, "signal_id", 	signal_id)
	self.orders:SetValue(newR, "sig_dir", 		signal_direction)
	self.orders:SetValue(newR, "qty", 			qty)	--количество в заявке, потом будем сравнивать с ним количество из колонки qty_fact
	self.orders:SetValue(newR, "sec_code", 		window:GetValueByColName(row, 'Ticker').image)
	self.orders:SetValue(newR, "class_code", 	window:GetValueByColName(row, 'Class').image)
	self.orders:SetValue(newR, "account", 		window:GetValueByColName(row, 'Account').image)
	self.orders:SetValue(newR, "depo", 			window:GetValueByColName(row, 'Depo').image)

	self:addRowToOrdersSQLite(row, trans_id, signal_id, signal_direction, qty, window) 
end

--добавляет строку в таблицу lua, а также вызывает функцию добавления строки в таблицу SQLite
function HelperGrid:addRowToSignals(row, trans_id, signal_id, signal_direction, window, candle_date, candle_time, price, MA, done) 
	
	local newR = self.signals:AddLine()
	
	self.signals:SetValue(newR, "row", row)
	self.signals:SetValue(newR, "id", 	signal_id)
	self.signals:SetValue(newR, "dir", 	signal_direction)
	
	self.signals:SetValue(newR, "account", 	window:GetValueByColName(row, 'Account').image)
	self.signals:SetValue(newR, "depo", 		window:GetValueByColName(row, 'Depo').image)

	self.signals:SetValue(newR, "sec_code", 	window:GetValueByColName(row, 'Ticker').image)
	self.signals:SetValue(newR, "class_code",window:GetValueByColName(row, 'Class').image)
	
	self.signals:SetValue(newR, "date", candle_date)
	self.signals:SetValue(newR, "time", 	candle_time) 
	self.signals:SetValue(newR, "price", price)
	--signals:SetValue(newR, "MA", 	EMA_TMP[#EMA_TMP-1])
	self.signals:SetValue(newR, "price", MA)
	self.signals:SetValue(newR, "done", done)
	
	self:addRowToSignalsSQLite(row, trans_id, signal_id, signal_direction, window, candle_date, candle_time, price, MA, done) 
	
end

--добавляет строку в таблицу lua, а также вызывает функцию добавления строки в таблицу SQLite
function HelperGrid:addRowToOrdersSQLite(row, trans_id, signal_id, signal_direction, qty, window) 

	local k = "'"
	
	local sql=[=[
	
		INSERT INTO orders (row,
			signal_id,
			sig_dir,
			account,
			depo,
			sec_code,
			class_code,
			trans_id,
			qty)
           VALUES(
		   ]=]
		   .. k..tostring(row)..k..','..
		    k..tostring(signal_id)..k..','..
		    k..tostring(signal_direction)..k..','..
		    k..tostring(window:GetValueByColName(row, 'Account').image)..k..','..
		    k..tostring(window:GetValueByColName(row, 'Depo').image)..k..','..
		    k..tostring(window:GetValueByColName(row, 'Ticker').image)..k..','..
		    k..tostring(window:GetValueByColName(row, 'Class').image)..k..','..
		    k..tostring(trans_id)..k..','..
		    k..tostring(qty)..k..
		   
		   [=[
		   )
		]=]
	
	--message(sql)
	
	--logstoscreen:add2(nil, nil, nil,nil,nil,nil,'sql: '..sql)
	
	self.db:exec(sql)
end

function HelperGrid:addRowToSignalsSQLite(row, trans_id, signal_id, signal_direction, window, candle_date, candle_time, price, MA, done) 
	
local k = "'"
	
	local sql=[=[
	
		INSERT INTO signals (row,
			id,
			dir,
			account,
			depo,
			sec_code,
			class_code,
			date,
			time,
			price,
			MA,
			done)
			
           VALUES(
		   ]=]
		   
			.. k..tostring(row)..k..','..
			k..tostring(signal_id)..k..','..
			k..tostring(signal_direction)..k..','..
	
		    k..tostring(window:GetValueByColName(row, 'Account').image)..k..','..
		    k..tostring(window:GetValueByColName(row, 'Depo').image)..k..','..
		    k..tostring(window:GetValueByColName(row, 'Ticker').image)..k..','..
		    k..tostring(window:GetValueByColName(row, 'Class').image)..k..','..
	
			k..tostring(candle_date)..k..','..
			k..tostring(candle_time)..k..','.. 
			k..tostring(price)..k..','..
			k..tostring(MA)..k..','..
			k..tostring(done)..k..
		   
		   [=[
		   )
		]=]
	
	--message(sql)
	
	--logstoscreen:add2(nil, nil, nil,nil,nil,nil,'sql: '..sql)
	
	self.db:exec(sql)
	
	--[[
	local newR = self.signals:AddLine()
	

	--]]
end






