--все инструменты должны торговаться в пределах одного торгового счета
--если есть необходимость запустить робота на двух счетах, то нужно запускать двух роботов
--имеется в виду, если есть ИИС и обычный
--хотя вообще это не строгое условие

--инструкция по настройке
--создать функцию, которая возвращает массив инструментов, образец - secListFutures()
--добавить инструменты в таблицу в функции main, см. по образцу
--создать графики цены всех новых инструментов. идентификатор графика формируется на основании тикера, см. образец
--готово.

--cheat sheet
--установка значения в ячейке таблицы
--window:SetValueByColName(row, 'LastPrice', tostring(security.last))
--получение значения из ячейки
--local acc = window:GetValueByColName(row, 'Account').image

local bit = require"bit"
local math_ceil = math.ceil
local math_floor = math.floor

--common classes
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\class.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\class.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Window.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Helper.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Trader.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Transactions.lua")
--dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Security.lua") --этот класс переопределен для данного робота
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\logs.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\logstoscreen.lua")

--common within one strategy
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Strategies\\StrategyOLE.lua")

--private for each robot
dofile (getScriptPath().."\\Classes\\SettingsGRID.lua")
dofile (getScriptPath().."\\Classes\\Security.lua")--этот класс переопределен для данного робота

dofile (getScriptPath() .. "\\quik_table_wrapper.lua")

--Это таблицы:
trader ={}
trans={}
helper={}
settings={}
strategy={}
security={}
window={}
logstoscreen={}

logs={}

local is_run = true	--флаг работы скрипта, пока истина - скрипт работает

local signals = {} --таблица обработанных сигналов.	
local orders = {} --таблица заявок

--эти таблицы нужны для того, чтобы не обрабатывать повторные колбэки на одни и те же сделки/заявки
local processed_trades = {} --таблица обработанных сделок
local processed_orders = {} --таблица обработанных заявок

function OnInit(path)
	trader = Trader()
	trader:Init(path)
	trans= Transactions()
	trans:Init()
	settings=Settings()
	settings:Init()
	settings:Load(trader.Path)
	helper= Helper()
	helper:Init()
	security=Security()
	security:Init()
	strategy=Strategy()
	strategy:Init()
	transactions=Transactions()
	transactions:Init()
	
  	logstoscreen = LogsToScreen()
	local position = {x=810,y=420,dx=700,dy=300}
	local extended = true--флаг расширенной таблицы лога
	logstoscreen:Init(position, extended) 	
end

--это не обработчик события, а просто функция покупки/продажи
function BuySell(row)

	local SecCodeBox= window:GetValueByColName(row, 'Ticker').image
	local ClassCode 	= window:GetValueByColName(row, 'Class').image
	local ClientBox 	= window:GetValueByColName(row, 'Account').image
	local DepoBox 	= window:GetValueByColName(row, 'Depo').image
	--идентификатор транзакции нужен обязательно, чтобы потом можно было понять, на какую транзакцию пришел ответ
	local trans_id 		= tonumber(window:GetValueByColName(row, 'trans_id').image)
	--
	local dir 			= window:GetValueByColName(row, 'sig_dir').image
	--количество для заявки берем из "переменной" - поля qty в главной таблице в строке из параметра row
	local qty 			= tonumber(window:GetValueByColName(row, 'qty').image)
	
	--получаем цену последней сделки, чтобы обладать актуальной информацией
	security.class = ClassCode
	security.code = SecCodeBox
	security:Update()
	
	local minStepPrice = tonumber(window:GetValueByColName(row, 'minStepPrice').image)
    
    if dir == 'buy' then
		transactions:orderWithId(SecCodeBox, ClassCode, "B", ClientBox, DepoBox, tostring(tonumber(security.last) + 150 * minStepPrice), qty, trans_id)
	elseif dir == 'sell' then
		transactions:orderWithId(SecCodeBox, ClassCode, "S", ClientBox, DepoBox, tostring(tonumber(security.last) - 150 * minStepPrice), qty, trans_id)
	end
	
	--очищаем, т.к. это временно значение
	window:SetValueByColName(row, 'qty', tostring(0))
	
end



--обработчик даблклика по ячейке Buy. т.е. просто покупка/продажа по рынку
function BuySell_no_trans_id(row, dir)

	local SecCodeBox 	= window:GetValueByColName(row, 'Ticker').image
	local ClassCode 	= window:GetValueByColName(row, 'Class').image
	local ClientBox 	= window:GetValueByColName(row, 'Account').image
	local DepoBox 		= window:GetValueByColName(row, 'Depo').image
	local qty 			= window:GetValueByColName(row, 'Lot').image
	
	security.class = ClassCode
	security.code = SecCodeBox
	security:Update()
	
	local minStepPrice = tonumber(window:GetValueByColName(row, 'minStepPrice').image)
    if dir == 'buy' then
		transactions:order(SecCodeBox, ClassCode, "B", ClientBox, DepoBox, tostring(tonumber(security.last) + 150 * minStepPrice), qty)
	elseif dir == 'sell' then
		transactions:order(SecCodeBox, ClassCode, "S", ClientBox, DepoBox, tostring(tonumber(security.last) - 150 * minStepPrice), qty)
	end
	
end


--колбэк
function OnStop(s)

	StopScript()
	
end 

--закрывает окна и выключает флаг работы скрипта
function StopScript()

	is_run = false
	window:Close()
	
	logstoscreen:CloseTable()
	DestroyTable(signals.t_id)
	DestroyTable(orders.t_id)	
	
end

--рефакторинг. запуск в работу одного инструмента
--[[
function StartRow(r, c)

	Red(window.hID, r, c)
	SetCell(window.hID, r, c, 'stop')
	window:SetValueByColName(r, 'current_state', 'waiting for a signal')
	
end
--]]

--рефакторинг. запуск в работу одного инструмента
function StartStopRow(row)

	local col = window:GetColNumberByName('StartStop')
	if window:GetValueByColName(row, 'StartStop').image == 'start' then
		Red(window.hID, row, col)
		SetCell(window.hID, row, col, 'stop')
		window:SetValueByColName(row, 'current_state', 'waiting for a signal')
	else
		Green(window.hID, row, col)
		SetCell(window.hID, row, col, 'start')
		window:SetValueByColName(row, 'current_state', '')
	end
end


--событие, возникающее после отправки заявки на сервер
function OnTransReply(trans_reply)

	--logstoscreen:add2(window, row, nil,nil,nil,nil,'OnTransReply '..helper:getMiliSeconds())

	--помещаем номер заявки в таблицу Orders, в строку с текущим trans_id
	local s = orders:GetSize()
	local rowNum=nil
	for i = 1, s do
		--здесь придется обойтись без строки в главной таблице - row, т.к. в контексте этой функции невозможно понять, по какой строке пришел колбэк
		--но это не будет проблемой, т.к. trans_id вполне однозначно определяет по какому инструменту ждем ответ
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trans_reply.trans_id) then
			orders:SetValue(i, 'order', trans_reply.order_num)
			--logstoscreen:add2(window, row, nil,nil,nil,nil,'OnTransReply - trans_id '..tostring(orders:GetValue(i, 'trans_id').image))
			rowNum=tonumber(orders:GetValue(i, 'row').image)
			break
		end
	end
	
	if trans_reply.status > 3 then
		logstoscreen:add2(window, row, nil,nil,nil,nil,'error ticker '..window:GetValueByColName(rowNum, 'Ticker').image .. ': '..tostring(trans_reply.status))
		message('error ticker '..window:GetValueByColName(rowNum, 'Ticker').image .. ': '..tostring(trans_reply.status))
		
		--выключаем инструмент, по которому пришла ошибка
		if rowNum~=nil then
			window:SetValueByColName(rowNum, 'StartStop', 'start')--turn off
			window:SetValueByColName(rowNum, 'current_state', '')--turn off
		end
	end
	
end 

function OnTrade(trade)

	--если сделка уже есть в таблице обработанных, то еще раз не надо ее обрабатывать
	local found = false
	for i = 1, #processed_trades do
		if tostring(processed_trades[i]) == tostring(trade.trade_num) then
			found = true
			break
		end
	end
	if found == true then
		return
	else
		processed_trades[#processed_trades+1] = trade.trade_num
	end
		
	
	--logstoscreen:add2(window, row, nil,nil,nil,nil,'onTrade '..helper:getMiliSeconds())
	
	--добавим количество из сделки в колонку qty_fact главной таблицы
	local s = orders:GetSize()
	for i = 1, s do
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trade.trans_id) 
			and tostring(orders:GetValue(i, 'order').image) == tostring(trade.order_num) then
			orders:SetValue(i, 'trade', trade.trade_num)
			local qty_fact = orders:GetValue(i, 'qty_fact').image
			if qty_fact == nil or qty_fact == '' then
				qty_fact = 0
			else
				qty_fact = tonumber(qty_fact)
			end
			orders:SetValue(i, 'qty_fact', qty_fact + tonumber(trade.qty))
			--logstoscreen:add2(window, row, nil,nil,nil,nil,'OnTrade - trans_id '..tostring(orders:GetValue(i, 'trans_id').image))
			break
		end
	end
	
end

function OnOrder(order)
	
	--если заявка уже есть в таблице обработанных, то еще раз не надо ее обрабатывать
	local found = false
	for i = 1, #processed_orders do
		if tostring(processed_orders[i]) == tostring(order.order_num) then
			found = true
			break
		end
	end
	if found == true then
		return
	else
		processed_orders[#processed_orders+1] = order.order_num
	end
	
	--logstoscreen:add2(window, row, nil,nil,nil,nil,'onOrder '..helper:getMiliSeconds())

	
end

local f_cb = function( t_id,  msg,  par1, par2)
	
--f_cb – функция обратного вызова для обработки событий в таблице. вызывается из main()
--(или, другими словами, обработчик клика по таблице робота)
--параметры:
--	t_id - хэндл таблицы, полученный функцией AllocTable()
--	msg - тип события, происшедшего в таблице
--	par1 и par2 – значения параметров определяются типом сообщения msg, 
--	
	--QLUA GetCell
	--Функция возвращает таблицу, содержащую данные из ячейки в строке с ключом «key», кодом колонки «code» в таблице «t_id». 
	--Формат вызова: 
	--TABLE GetCell(NUMBER t_id, NUMBER key, NUMBER code)
	--Параметры таблицы: 
	--image – строковое представление значения в ячейке, 
	--value – числовое значение ячейки.
	--Если входные параметры были заданы ошибочно, то возвращается «nil».
	
	local x=GetCell(window.hID, par1, par2) 

	--события
	--QTABLE_LBUTTONDBLCLK – двойное нажатие левой кнопки мыши, при этом par1 содержит номер строки, par2 – номер колонки, 
	
	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('StartStop') then
			--message("Start",1)
			if x["image"]=="start" then
				--StartRow(par1, par2)
				StartStopRow(par1)
				
			else
				--Stop but not closed
				StartStopRow(par1)
				--[[
				Green(window.hID, par1, par2)
				SetCell(window.hID, par1, par2, 'start')
				window:SetValueByColName(par1, 'current_state', nil)
				--]]
			end
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('BuyMarket') then
			--message('buy')
			BuySell_no_trans_id(par1, 'buy')
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('SellMarket') then
			--message('buy')
			BuySell_no_trans_id(par1, 'sell')
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('test_buy') then
			--message('buy')
			window:SetValueByColName(par1, 'test_buy', 'true')
			
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('test_sell') then
			--message('buy')
			window:SetValueByColName(par1, 'test_sell', 'true')
			
		end
	end


	if (msg==QTABLE_CLOSE)  then
		--window:Close()
		--is_run = false
		--working = false
		StopScript()
	end

	--закрытие окна робота кнопкой ESC
	if msg==QTABLE_VKEY then
		--message(par2)
		if par2 == 27 then-- esc
			--window:Close()
			--is_run=false
			--working = false
			StopScript()
		end
	end	

end 

--читает из настроек таблицу инструментов и добавляет строки с ними в главную таблицу
function AddRowsToMainWindow()

	local List = settings:instruments_list() --Это двумерный массив (таблица)
	
	--добавляем строки с инструментами в таблицу робота
	for row=1, #List do
		
		rowNum = InsertRow(window.hID, -1)
		
		window:SetValueByColName(rowNum, 'Account', List[row][7])
		window:SetValueByColName(rowNum, 'Depo', List[row][8])
		window:SetValueByColName(rowNum, 'Name', List[row][1]) 
		window:SetValueByColName(rowNum, 'Ticker', List[row][3]) --код бумаги
		window:SetValueByColName(rowNum, 'Class', List[row][6]) --класс бумаги
		window:SetValueByColName(rowNum, 'Lot', List[row][4]) --размер лота для торговли
		--здесь наоборот надо, если в настройках start, то нужно запустить робота, а в поле StartStop поместить действие stop
		window:SetValueByColName(rowNum, 'StartStop', List[row][9])
		--[[
		if List[row][9] == 'start' then
			window:SetValueByColName(rowNum, 'StartStop', 'stop')
		else
			window:SetValueByColName(rowNum, 'StartStop', 'start')
		end
		--]]
		window:SetValueByColName(rowNum, 'BuyMarket', 'Buy')
		window:SetValueByColName(rowNum, 'SellMarket', 'Sell')
		
		window:SetValueByColName(rowNum, 'MA60name',  List[row][1] ..'_grid_MA60')
		window:SetValueByColName(rowNum, 'PriceName', List[row][1]..'_grid_price')
		
		window:SetValueByColName(rowNum, 'rejim', List[row][5])
		
		--чтобы получить номер колонки используем функцию GetColNumberByName()
		Green(window.hID, rowNum, window:GetColNumberByName('StartStop')) 
		Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
		
		local minStepPrice = getParamEx(List[row][6], List[row][3], "SEC_PRICE_STEP").param_value + 0
		window:SetValueByColName(rowNum, 'minStepPrice', tostring(minStepPrice))
		
	end  

end

--главная функция робота, которая гоняется в цикле
function main()

	if settings.invert_deals == true then
		message('включено инвертирование сделок!!! все позиции в этом режиме по-умолчанию выключены!',3)
		logstoscreen:add2(window, nil, nil,nil,nil,nil,'включено инвертирование сделок!!! все позиции выключены!')
	end
	--создаем окно робота с таблицей и добавляем в эту таблицу строки
	window = Window()									--функция Window() расположена в файле Window.luac и создает класс
	
	--{'A','B'} - это массив с именами колонок
	--справка: http://smart-lab.ru/blog/291666.php
	--Чтобы создать массив, достаточно перечислить в фигурных скобках значения его элементов:
	--t = {«красный», «зеленый», «синий»}
	--Это выражение эквивалентно следующему коду:
	--t = {[1]=«красный», [2]=«зеленый», [3]=«синий»}	
	
	--ENS класс window содержит поле columns, чтобы потом можно было найти  номер колонки по имени
	--колонки 'MA60name','PriceName' содержат идентификаторы графиков. для каждой бумаги - свой идентификатор
	--формат идентификатора: кодИнструмента_grid_MA60, кодИнструмента_grid_price
	--колонки 'MA60Pred','MA60' содержат значения средней скользящей для предпредыдущего и предыдущего бара соответственно
	--колонки 'PricePred','Price' содержат значения цены для предпредыдущего и предыдущего бара соответственно
	--колонки 'BuyMarket','SellMarket' - это "кнопки", т.е. колонки, по которым нужно даблкликнуть, чтобы купить/продать по рынку количество контрактов из колонки Lot
	--'StartStop' - "кнопка", управляющая включением робота для конкретного инструмента. если робот выключен, то он все равно показывает
	--значения последней цены, предпредыдущей и предыдущей цены и средней скользящей
	
	--rejim: long / short / revers
	--sig_dir - signal direction
	--trans_id - число, идентификатор пользовательской транзакции, отправленной программно. по нему фильтруем сделки и заявки при наборе позиции
	--current_state - текущее состояние по инструменту
	--signal_id - идентификатор сигнала
	--savedPosition - число - сюда сохраняем позицию перед отправкой транзакции, а потом в функции ожидания ответа проверяем, поменялось ли это количество
	local position = {x=50,y=105,dx=1300,dy=400}
	window:Init(settings.TableCaption, {'current_state','Account','Depo','Name','Ticker','Class', 'Lot', 'Position','sig_dir','LastPrice','BuyMarket','SellMarket','StartStop','MA60Pred','MA60','PricePred','Price','PriceName','MA60name','minStepPrice','rejim','trans_id','signal_id','test_buy','test_sell','qty','savedPosition'}, position)
	
	--создаем вспомогательные таблицы
---------------------------------------------------------------------------	
	if createTableSignals() == false then
		return
	end

	SetWindowPos(signals.t_id, 810, 10, 700, 200)

---------------------------------------------------------------------------	
	if createTableOrders() == false then
		return
	end	
	
	SetWindowPos(orders.t_id, 810, 210, 700, 200)
	
		
	
	--НАСТРОЙКИ ПОКА ЗАДАЮТСЯ ЗДЕСЬ!!!!
	
	--фьючерсы  (индексы, валюты, комоды)
	
	AddRowsToMainWindow()

	
	--обработчик событий главной таблицы
	SetTableNotificationCallback (window.hID, f_cb)

	--запускаем все согласно настроек	
	local col = window:GetColNumberByName('StartStop')
	for row=1, GetTableSize(window.hID) do
		if settings.invert_deals == true then
			window:SetValueByColName(row, 'StartStop', 'stop')
		end
		StartStopRow(row)
		--[[
		if window:GetValueByColName(row, 'StartStop').image == 'start' then
			StartRow(row, col)
		else
			window:SetValueByColName(row, 'StartStop', 'start')
		end
		--]]
	end
	

	
	--задержка 100 миллисекунд между итерациями 
	while is_run do
	
		for row=1, GetTableSize(window.hID) do
			main_loop(row)
		end
		
		sleep(1000)
	end

end

--- Функции по раскраске строк/ячеек таблицы
function Red(t_id, Line, Col)    -- Красный
   -- Если индекс столбца не указан, окрашивает всю строку
   if Col == nil then Col = QTABLE_NO_INDEX; end;
   SetColor(t_id, Line, Col, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0));
end;

function Gray(Line, Col)   -- Серый
   -- Если индекс столбца не указан, окрашивает всю строку
   if Col == nil then Col = QTABLE_NO_INDEX; end;
   SetColor(t_id, Line, Col, RGB(200,200,200), RGB(0,0,0), RGB(200,200,200), RGB(0,0,0));
end;

function Green(t_id, Line, Col)  -- Зеленый
   -- Если индекс столбца не указан, окрашивает всю строку
   if Col == nil then Col = QTABLE_NO_INDEX; end;
   SetColor(t_id, Line, Col, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0));
end;

function createTableSignals()
	
	signals = QTable.new()
	if not signals then
		message("error creation table Signals!", 3)
		return false
	else
		--message("table with id = " ..signals.t_id .. " created", 1)
	end

	signals:AddColumn("row", 		QTABLE_INT_TYPE, 5) --номер строки в главной таблице. внешний ключ!!!
	signals:AddColumn("id", 		QTABLE_INT_TYPE, 10)
	signals:AddColumn("dir", 		QTABLE_CACHED_STRING_TYPE, 4)
	signals:AddColumn("account", QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("depo", 	QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("sec_code", QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("class_code", QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("date", 	QTABLE_CACHED_STRING_TYPE, 10) --время свечи, на которой сформировался сигнал
	signals:AddColumn("time", 		QTABLE_CACHED_STRING_TYPE, 10) --время свечи, на которой сформировался сигнал
	signals:AddColumn("price", 	QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("MA",		QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("done", 	QTABLE_STRING_TYPE, 10)
	
	signals:SetCaption("Signals")
	signals:Show()
	
	return true
	
end

function createTableOrders()
	
	orders = QTable.new()
	if not orders then
		message("error creation table orders!", 3)
		return false
	else
		--message("table with id = " ..orders.t_id .. " created", 1)
	end
	
	orders:AddColumn("row", 			QTABLE_INT_TYPE, 5) --номер строки в главной таблице. внешний ключ!!!
	orders:AddColumn("signal_id", 	QTABLE_INT_TYPE, 10)
	orders:AddColumn("sig_dir", 		QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("account", 	QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("depo", 			QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("sec_code", 	QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("class_code", QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("trans_id", 	QTABLE_INT_TYPE, 10)
	orders:AddColumn("order", 		QTABLE_INT_TYPE, 10)
	orders:AddColumn("trade", 		QTABLE_INT_TYPE, 10)
	orders:AddColumn("qty", 			QTABLE_INT_TYPE, 10) --количество из заявки
	orders:AddColumn("qty_fact", 	QTABLE_INT_TYPE, 10) --количество из сделок
	
	orders:SetCaption("orders")
	orders:Show()
	
	return true
	
end

--+-----------------------------------------------
--|			ОСНОВНОЙ АЛГОРИТМ
--+-----------------------------------------------

--эта функция должна вызываться из обрамляющего цикла в функции main()
function main_loop(row)

	if isConnected() == 0 then
		--window:InsertValue("Сигнал", "Not connected")
		return
	end
	
	local sec = window:GetValueByColName(row, 'Ticker').image
	local class = window:GetValueByColName(row, 'Class').image
	
	security.code = sec
	security.class = class	
	security:Update()	--обновляет цену последней сделки в таблице security (свойство Last,Close)

	--помещаем цену в окно робота. просто для визуального наблюдения		
	window:SetValueByColName(row, 'LastPrice', tostring(security.last))

	local IdPriceCombo = window:GetValueByColName(row, 'PriceName').image   --идентификатор графика цены выбранной бумаги (таблица)
	
	--источник комментов [1] - это http://robostroy.ru/community/article.aspx?id=796
	--[1]Сначала мы получаем количество свечей. здесь: на графике цены
	NumCandles = getNumCandles(IdPriceCombo)	

	if NumCandles==0 then
		return 0
	end

	--СУУ_ЕНС тут запрашиваем 2 предпоследних свечи. последняя не нужна, т.к. она еще не сформирована
	local tPrice,n,s = getCandlesByIndex(IdPriceCombo,0,NumCandles-3, 2)		
	strategy:SetSeries(tPrice)

	local IdMA = window:GetValueByColName(row, 'MA60name').image
	
	--далее пошли запрашивать цены с графика moving averages
	local tMA,n,s = getCandlesByIndex(IdMA,0,NumCandles-3, 2)		
	strategy.Ma1Series=tMA	--этого поля (Ma1Series) нет в Init, оно создается здесь

	--главное начинается здесь

	strategy:CalcLevels() --получим значения цены и средней скользящей
	
	--message(IdPriceCombo)
	
	--пока отключено, проще с графика брать, а это надо еще тестировать
	--EMA(60, IdPriceCombo)--рассчитываем среднюю скользящую (экспоненциальную)

	
	
	local acc = window:GetValueByColName(row, 'Account').image
	--заглушка. для валют надо получить позицию из таблицы денежной позиции, потом надо доделать
	local currency_CETS='USD'

	--обновляем данные о позиции в визуальной таблице робота
	window:SetValueByColName(row, 'Position', tostring(trader:GetCurrentPosition(sec, acc, class, currency_CETS)))
	
	--window:SetValueByColName(row, 'MA60Pred', tostring(EMA_TMP[#EMA_TMP-2]))
	--window:SetValueByColName(row, 'MA60', tostring(EMA_TMP[#EMA_TMP-1]))

	window:SetValueByColName(row, 'MA60Pred', tostring(strategy.Ma1Pred))
	window:SetValueByColName(row, 'MA60', tostring(strategy.Ma1))
	
	window:SetValueByColName(row, 'PricePred', strategy.PriceSeries[0].close)
	window:SetValueByColName(row, 'Price', strategy.PriceSeries[1].close)
	
	local working = window:GetValueByColName(row, 'StartStop').image 
	
	if working=='start'  then --инструмент выключен. когда включен, там будет Stop
		return
	end
		
		
	-------------------------------------------------------------------
	--			ОСНОВНОЙ АЛГОРИТМ
	-------------------------------------------------------------------
	local current_state = window:GetValueByColName(row, 'current_state').image
	
	if current_state == 'waiting for a signal' then
		--ожидаем новые сигналы 
		wait_for_signal(row)
		
	elseif current_state == 'processing signal' then
		--в этом состоянии робот шлет заявки на сервер, пока не наберет позицию или не кончится время или количество попыток
		processSignal(row)
		
	elseif current_state == 'waiting for a response' then
		--заявку отправили, ждем пока придет ответ, перед отправкой новой
		wait_for_response(row)
		
	end

end

--обработать сигнал
function processSignal(row)
	
	--нужно посмотреть, на сколько лотов/контрактов нужно открыть позицию - это в настройках каждой строки с инструментом
	
	local planQuantity = tonumber(window:GetValueByColName(row, 'Lot').image)
	
	local signal_direction = window:GetValueByColName(row, 'sig_dir').image
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'processing signal: '..signal_direction)
	
	if signal_direction == 'sell' then
		planQuantity = -1*planQuantity --сделаем отрицательным
	end
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'plan quantity: ' .. tostring(planQuantity))
	
	--посмотреть, сколько уже лотов/контрактов есть в позиции (валюту для СЭЛТ пока оставим пустой, главное - сделать базовый функционал)
	local factQuantity = trader:GetCurrentPosition(window:GetValueByColName(row, 'Ticker').image, window:GetValueByColName(row, 'Account').image, window:GetValueByColName(row, 'Class').image)
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'fact quantity: ' .. tostring(factQuantity))
	
	if window:GetValueByColName(row, 'rejim').image == 'revers' then
		--все разрешено
		
	elseif window:GetValueByColName(row, 'rejim').image == 'long' then
		--нельзя в шорт. длинную позицию продаем в ноль
		if signal_direction == 'sell' and factQuantity>=0 then
			planQuantity = 0
		end
		
	elseif window:GetValueByColName(row, 'rejim').image == 'short' then
		--нельзя в лонг. короткую позицию откупаем в ноль
		if signal_direction == 'buy' and factQuantity<=0 then
			planQuantity = 0
		end
	end
	
	local signal_id = window:GetValueByColName(row, 'signal_id').image
	
	--если эти значения отличаются, то добираем позу
	if (signal_direction == 'buy' and factQuantity < planQuantity )
		or (signal_direction == 'sell' and factQuantity > planQuantity)
		then
		
		--послать заявку
		local trans_id = helper:getMiliSeconds_trans_id()
		
		window:SetValueByColName(row, 'trans_id', tostring(trans_id))
		
		local qty = planQuantity - factQuantity
		
		if qty == 0 then
			logstoscreen:add2(window, row, nil,nil,nil,nil,'ОШИБКА! qty = 0')
			--переходим к ожиданию нового сигнала
			 
			window:SetValueByColName(row, 'current_state', 'waiting for a signal')
			window:SetValueByColName(row, 'sig_dir', '')
			return
		end
		
		
		
		if signal_direction == 'sell' then --приведем к положительному
			qty = -1*qty
		end
		
		
		logstoscreen:add2(window, row, nil,nil,nil,nil,'qty: ' .. tostring(qty))
		
		
		--!!!!!!!!!!!!для отладки. хочу проверить как будет отрабатывать ожидание добора позиции 
		--qty = 5
		
		
		window:SetValueByColName(row, 'qty', tostring(qty))
		
		--для визуального контроля пишем информацию о заявке во вспомогательную таблицу
		local newR = orders:AddLine()
		orders:SetValue(newR, "row", 			row)
		orders:SetValue(newR, "trans_id", 		trans_id)
		orders:SetValue(newR, "signal_id", 		signal_id)
		orders:SetValue(newR, "sig_dir", 		signal_direction)
		orders:SetValue(newR, "qty", 			qty)	--количество в заявке, потом будем сравнивать с ним количество из колонки qty_fact
		orders:SetValue(newR, "sec_code", 	window:GetValueByColName(row, 'Ticker').image)
		orders:SetValue(newR, "class_code", 	window:GetValueByColName(row, 'Class').image)
		orders:SetValue(newR, "account", 		window:GetValueByColName(row, 'Account').image)
		orders:SetValue(newR, "depo", 			window:GetValueByColName(row, 'Depo').image)
		
		--сохраним "старую" позицию
		window:SetValueByColName(row, 'savedPosition', tostring(factQuantity))
		
		--универсальная функция покупки/продажи
		BuySell(row)
		
		--после отправки транзакции на биржу меняем состояние робота на то, в котором он ждет ответа на выставленную заявку
		window:SetValueByColName(row, 'current_state', 'waiting for a response')

	else
		--logstoscreen:add2(window, row, nil,nil,nil,nil,'вся позиция уже набрана, заявка не отправлена!')
		
		window:SetValueByColName(row, 'current_state', 'waiting for a signal')
		
		--обновим состояние сигнала в таблице сигналов
		local rows=0
		local cols=0
		rows,cols = signals:GetSize()
		for j = 1 , rows do --в таких таблицах нумерация начинается с единицы
			if tostring(signal_id) == tostring(signals:GetValue(j, "id").image) 
				and row == tonumber(signals:GetValue(j, "row").image)
				then
			
				signals:SetValue(j, "done", true) 
				break
			end
		end		
		
		window:SetValueByColName(row, 'trans_id', nil)
		window:SetValueByColName(row, 'signal_id', nil)
	end
	
end

--ждать ответа на отправленную заявку
function wait_for_response(row)
	--logstoscreen:add2(window, row, nil,nil,nil,nil,'we are waiting the result of sending order')

	---[[
	
	local s = orders:GetSize()
	for i = 1, s do
		
		local trans_id = window:GetValueByColName(row, 'trans_id').image
		
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trans_id)
			and tonumber(orders:GetValue(i, 'row').image) == row then
			
			if orders:GetValue(i, 'trade')~=nil and ( orders:GetValue(i, 'trade').image~='0' and orders:GetValue(i, 'trade').image~='' and orders:GetValue(i, 'trade').image~='nil') then
				--если в таблице orders появился номер сделки, это значит что заявка обработалась.
				
				--а вот и не факт. нужно сравнить количество в заявке и в сделке. если заявка полностью удовлетворена, то только тогда это значит, что она обработалась
				--хотя для объемов в 10 лотов наверное любой фьючерс будет ликвидным...
				
				--чтобы гарантированно получить число, приходится писать вот такие обводные конструкции
				local qty_fact = orders:GetValue(i, 'qty_fact').image
				if qty_fact == nil or qty_fact == '' then
					qty_fact = 0
				else
					qty_fact = tonumber(qty_fact)
				end
			
				--чтобы гарантированно получить число, приходится писать вот такие обводные конструкции
				local qty = orders:GetValue(i, 'qty').image
				if qty == nil or qty == '' then
					qty = 0
				else
					qty = tonumber(qty)
				end
				
				--сравниваем количество, которое отправили в заявке (qty) и количество, которое пришло в ответ в сделках (qty_fact)
				if qty_fact >= qty then
					
					logstoscreen:add2(window, row, nil,nil,nil,nil,'order '..orders:GetValue(i, 'order').image..': qty_fact >= qty. Order is processed!')
					
				end

				--проверяем позицию. это нужно делать независимо от обновления таблицы orders
				--пока позиция не изменилась относительно сохраненного перед отправкой транзакции количество - состояние робота не меняем
				
				local curPosition = trader:GetCurrentPosition(window:GetValueByColName(row, 'Ticker').image, window:GetValueByColName(row, 'Account').image, window:GetValueByColName(row, 'Class').image)
				local savedPosition = tonumber(window:GetValueByColName(row, 'savedPosition').image)
				
				--доделать. нужно добавить счетчик безопасного выполнения, чтобы в бесконечный цикл не уйти
				if curPosition ~= savedPosition then
					
					--переключаем состояние робота по данному инструменту - снова переходим к обработке сигнала, т.к. проверка позиции делается там
					window:SetValueByColName(row, 'current_state', 'processing signal')
					window:SetValueByColName(row, 'savedPosition', tostring(curPosition))--хотя это можно не делать, все равно в processSignal() обновится
					
				end
				
			end
		end
	end
	--]]
		
end

--ждать новые сигналы
function wait_for_signal(row)

	--нужно только так, сначала поместить сигналы в переменные, потом работать с переменными
	--это надо, чтобы работал тест сигналов - когда включается тестовый флаг, функция сигнала возвращает истину, а перед этим выключает флаг
	--т.е. более одного раза вызвать функцию сигнала в режиме теста не получится
	local signal_buy =  signal_buy(row)
	local signal_sell =  signal_sell(row)
	
	if signal_buy == false and signal_sell == false then
		return
	end
		
	--если есть сигнал, нужно проверить, а может мы его уже обработали.-
	--таймфрейм тут планируется 1 час, поэтому главный цикл будет видеть сигнал
	--еще целый час после обработки
	local dt=strategy.PriceSeries[1].datetime--предыдущая свеча
	local candle_date = dt.year..'-'..dt.month..'-'..dt.day
	local candle_time = dt.hour..':'..dt.min..':'..dt.sec

	--проверка наличия сигнала, чтобы не обрабатывать повторно
	if find_signal(row, candle_date, candle_time) == true then
		--logstoscreen:add2(window, row, nil,nil,nil,nil,'signal '..candle_date..' '..candle_time..' is already processed')
		return
	end
		
	--logstoscreen:add2(window, row, nil,nil,nil,nil,'we have got a signal: ')
	
	local sig_dir = nil
	if signal_buy == true then 
		--закрытие свечи выше средней - покупка
		if settings.invert_deals == false then
			sig_dir='buy'
		else
			sig_dir='sell'
		end
		
	elseif signal_sell == true	then 
		--закрытие часовика ниже средней - продажа
		if settings.invert_deals == false then
			sig_dir='sell'
		else
			sig_dir='buy'
		end
		
	end
	
	window:SetValueByColName(row, 'sig_dir', sig_dir)
	
	--сигнала в таблице нет, добавляем новый
	local signal_id = helper:getMiliSeconds_trans_id()
	window:SetValueByColName(row, 'signal_id', tostring(signal_id))
	
	local newR = signals:AddLine()
	signals:SetValue(newR, "row", row)
	signals:SetValue(newR, "id", 	signal_id)
	signals:SetValue(newR, "dir", 	sig_dir)
	
	signals:SetValue(newR, "account", 	window:GetValueByColName(row, 'Account').image)
	signals:SetValue(newR, "depo", 	window:GetValueByColName(row, 'Depo').image)

	signals:SetValue(newR, "sec_code", 	window:GetValueByColName(row, 'Ticker').image)
	signals:SetValue(newR, "class_code", 	window:GetValueByColName(row, 'Class').image)
	
	signals:SetValue(newR, "date", candle_date)
	signals:SetValue(newR, "time", 	candle_time) 
	signals:SetValue(newR, "price", strategy.PriceSeries[1].close)
	--signals:SetValue(newR, "MA", 	EMA_TMP[#EMA_TMP-1])
	signals:SetValue(newR, "price", strategy.Ma1)
	signals:SetValue(newR, "done", false)
	
	--переходим в режим обработки сигнала. функция обработки сработает на следующей итерации
	window:SetValueByColName(row, 'current_state', 'processing signal')
	
end

--[[ищет сигнал в таблице сигналов. вызывается при поступлении нового сигнала.
сигнал будет поступать все следующее время после формирования, согласно выбранному таймфрейму графика цены
т.е. когда он поступил в момент формирования новой свечи, он еще будет поступать всю эту свечу.
Есть один баг. Если робота перезапустить во время жизни свечи, на которой возник сигнал, то он опять увидит этот сигнал
и попробует вставить в позицию. Если позиция уже была сформирована до перезапуска, то ничего страшного, 
сработает проверка plan-fact и не позволит увеличить позу.

--]]
function find_signal(row, candle_date, candle_time)
	local rows=0
	local cols=0
	rows,cols = signals:GetSize()
	for i = 1 , rows do --в таких таблицах нумерация начинается с единицы
		if tonumber(signals:GetValue(i, "row").image) == row and
			signals:GetValue(i, "date").image == candle_date and
			signals:GetValue(i, "time").image == candle_time then
			--уже есть сигнал, повторно обрабатывать не надо
			--logstoscreen:add2(window, row, nil,nil,nil,nil,'the signal is already processed: '..tostring(signals:GetValue(i, "id").image))
			return true
		end
	end
	return false
end

--+-----------------------------------------------
--|			ОСНОВНОЙ АЛГОРИТМ - КОНЕЦ
--+-----------------------------------------------


function signal_buy(row)

--  Ma1 = Ma1Series[1].close						--предыдущая свеча
--  Ma1Pred = Ma1Series[0].close 	--ENS		--предпредыдущая свеча

	--для тестов
    
	if window:GetValueByColName(row, 'test_buy').image == 'true' then
		window:SetValueByColName(row, 'test_buy', 'false')
		return true
	end
		
	---[[
	if strategy.Ma1 ~= 0 
	and strategy.Ma1Pred  ~= 0 
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
	and strategy.PriceSeries[0].close < strategy.Ma1Pred --предпредыдущий бар ниже средней
	and strategy.PriceSeries[1].close > strategy.Ma1 --предыдущий бар выше средней
	then
		return true
	else
		return false
	end
	--]]
	
	--[[
	if EMA_TMP[#EMA_TMP-1]  ~= 0 		--предыдущая свеча
	and EMA_TMP[#EMA_TMP-2]  ~= 0 		--предпредыдущая свеча
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
	and strategy.PriceSeries[0].close < EMA_TMP[#EMA_TMP-2] --предпредыдущий бар ниже средней
	and strategy.PriceSeries[1].close > EMA_TMP[#EMA_TMP-1] --предыдущий бар выше средней
	then
		return true
	else
		return false
	end
--]]	
end

function signal_sell(row)

--  Ma1 = Ma1Series[1].close						--предыдущая свеча
--  Ma1Pred = Ma1Series[0].close 	--ENS		--предпредыдущая свеча


	--для тестов
	
	if window:GetValueByColName(row, 'test_sell').image == 'true' then
		window:SetValueByColName(row, 'test_sell', 'false')
		return true
	end
	
	if strategy.Ma1 ~= 0 
	and strategy.Ma1Pred  ~= 0 
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
--	and strategy.PriceSeries[0].close > EMA_TMP[#EMA_TMP-2] --предпредыдущий бар выше средней
--	and strategy.PriceSeries[1].close < EMA_TMP[#EMA_TMP-1] --предыдущий бар ниже средней
	and strategy.PriceSeries[0].close > strategy.Ma1Pred --предпредыдущий бар выше средней
	and strategy.PriceSeries[1].close < strategy.Ma1 --предыдущий бар ниже средней
	then
		return true
	else
		return false
	end

end

