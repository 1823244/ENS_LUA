--система Олейника
--закрытие часа выше 60-и периодной скользящей - покупка и дальнейшая работа от лонга
--закрытие часа ниже 60-и периодной скользящей - продажа и дальнейшая работа от шорта

local bit = require"bit"

--common classes
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\class.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Window.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Helper.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Trader.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Transactions.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Security.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\logs.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\SQLiteWork.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\logstoscreen.lua")
--common within one strategy
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Strategies\\StrategyOLE.lua")
--private for each robot
dofile (getScriptPath().."\\Classes\\SettingsOLE.lua")
--from examples arqa
dofile (getScriptPath() .. "\\quik_table_wrapper.lua")

--Это классы:
trader ={}
trans={}
helper={}
settings={}
strategy={}
security={}
window={}
sqlitework={}
logstoscreen={}
logs={}

local is_run = true	--флаг работы скрипта, пока истина - скрипт работает
local working = false	--флаг активности. чтобы не закрывая окно можно быть включить/выключить робота
local count_animation=0--переменна нужна для отображения анимации в окне робота,чтобы понимать,что он работает 
local math_abs = math.abs --локализация стандартной библиотеки
local math_ceil = math.ceil
local math_floor = math.floor
local signal_direction = ''			--направление сигнала buy/sell
local signals = {} --таблица обработанных сигналов.	
local orders = {} --таблица заявок
local trans_id = nil --здесь будет храниться номер транзакции, он будет помещен в таблицу orders
local signal_id = nil
--for debug
local test_signal_buy = false -- флаг, если истина, то функция сигнала вернет истину. для теста
local test_signal_sell = false -- флаг, если истина, то функция сигнала вернет истину. для теста

local current_state = 'waiting for a signal' --первое состояние, ждем сигнала
--more options:
--'processing signal' -- получили сигнал, обрабатываем, т.е. выставляем заявку
--'waiting for a response' --ждем ответа с биржи о результате выставления заявки. если придет сделка, то меняем состояние на 'waiting for a signal'

--свой расчет средней
local EMA_TMP={} --массив для хранения значений средней скользящей, посчитанной самостоятельно по свечам цены
--свечи хранятся слева направо, первая свеча имеет индекс 0, последняя #EMA_TMP
local lastCandleMA = nil -- последняя посчитанная свеча
--свой расчет средней конец

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


	logs=Logs()
	logs:Init()

	
	--класс работы с ценной бумагой
	security=Security()
	security:Init(settings.ClassCode,settings.SecCodeBox)

	strategy=Strategy()
	strategy:Init()


	transactions=Transactions()
	transactions:Init(settings.ClientBox,settings.DepoBox, settings.SecCodeBox,settings.ClassCode)

	sqlitework = SQLiteWork()
	sqlitework:Init()  
	
  	logstoscreen = LogsToScreen()
	local position = {x=300,y=10,dx=500,dy=400}
	logstoscreen:Init(position) 


  
  db = sqlite3.open(settings.dbpath)
  

end

--обработчик кнопки "buy по рынку"
function BuyMarket()
    if working  then
      trans:order(settings.SecCodeBox,settings.ClassCode,"B",settings.ClientBox,settings.DepoBox,tostring(security.last+100*security.minStepPrice),settings.LotSizeBox)
	end 
end

--обработчик кнопки "sell по рынку"
function SellMarket()
	if working then
		trans:order(settings.SecCodeBox,settings.ClassCode,"S",settings.ClientBox,settings.DepoBox,tostring(security.last-100*security.minStepPrice),settings.LotSizeBox)
	end
end

--это не метод квика, а просто функцию так назвали!
function OnStart()

	current_state = 'waiting for a signal'
	
	window:InsertValue("Позиция",tostring(trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox,settings.currency_CETS)))
	settings:Load(trader.Path)
	strategy.LotToTrade=tonumber(settings.LotSizeBox)

	
	--[[
	
		  local logfile = "c:\\TRAIDING\\ROBOTS\\DEMO\\ENS_MA_lua\\ARQA\\log.txt"
		  local file = io.open(logfile, "a")
		  if file ~= nil then
			file:write("----------------------------------------".."\n")
			file:write("sec code: "..tostring(settings.SecCodeBox).."\n")
			file:write("LotToTrade: "..tostring(strategy.LotToTrade).."\n")
			file:close()
		  end	
  --]]
	
	--logstoscreen:add('test log')
	--logstoscreen:add('test log 2')
	
end

function OnStop(s)

	--[[window:Close()
	logstoscreen:CloseTable()
	is_run = false
	--]]
	StopScript()
end 

function StopScript()
	window:Close()
	--[[if logstoscreen ~= nil then
		if logstoscreen.window ~= nil then
			logstoscreen.window:Close()
		end	
	end	--]]
	logstoscreen:CloseTable()
	is_run=false
	DestroyTable(signals.t_id)
	DestroyTable(orders.t_id)
end

--событие, возникающее после отправки заявки на сервер
function OnTransReply(trans_reply)
	if working == false then
		return
	end
	--message('OnTransReply '..helper:getMiliSeconds())
	logstoscreen:add('OnTransReply '..helper:getMiliSeconds())
	
	local s = orders:GetSize()
	logstoscreen:add('size of orders = '..tostring(s))
	for i = 1, s do
		
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trans_reply.trans_id) then
			orders:SetValue(i, 'order', trans_reply.order_num)
			logstoscreen:add('OnTransReply - trans_id '..tostring(orders:GetValue(i, 'trans_id').image))
			break
		end
	end
	
end 

--событие, возникающее после поступления сделки
function OnTrade(trade)
	if working == false then
		return
	end
	
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
		
	
	logstoscreen:add('onTrade '..helper:getMiliSeconds())
	
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
			--logstoscreen:add('OnTrade - trans_id '..tostring(orders:GetValue(i, 'trans_id').image))
			break
		end
	end
	
end

function OnOrder(order)
	if working == false then
		return
	end
	
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
	
	logstoscreen:add('onOrder '..helper:getMiliSeconds())

	
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
	
	x=GetCell(window.hID, par1, par2) 

	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="Buy по рынку" then
			message("Buy",1)
			BuyMarket()
		elseif (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="Sell по рынку" then
			message("Sell",1)
			SellMarket()
		elseif (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="Старт" then
			OnStart()
			--message("Старт",1)
			window:SetValueWithColor("Старт","Остановка","Red")
			working=true
		elseif (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="TEST BUY" then
			--message("TEST",1)
			TestBuy()
			--window:SetValueWithColor("Старт","Остановка","Red")
			--working=true
		elseif (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="TEST SELL" then
			--message("TEST",1)
			TestSell()
			--window:SetValueWithColor("Старт","Остановка","Red")
			--working=true
		elseif (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="TEST EMA" then
			--message("TEST",1)
			EMA(60)
			--window:SetValueWithColor("Старт","Остановка","Red")
			--working=true
		elseif (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="Остановка" then
			--message("Остановка",1)
			window:SetValueWithColor("Остановка","Старт","Green")
			working=false
		end
	end
	
	--крестик в окне
	if (msg==QTABLE_CLOSE)  then
		StopScript()
	end

	--кнопка на клавиатуре
	if msg==QTABLE_VKEY then
		if par2 == 27 then-- esc
			StopScript()
		end
	end	

end 

--главная функция робота, которая гоняется в цикле
function main()
	
	--strategy.db = db
	
	--создаем таблицу сигналов в базе
	--sqlitework.db = db
	--sqlitework:createTableSignals()
	--создаем таблицу позиций в базе
	--sqlitework:createTablePositions()
	
	--sqlitework:createTableOrders()
	
	--в этой таблице есть поля: rownum | trans_id | signal_id | order_num | robot_id
	--в нее пишем сначала из модуля strategy
	--а затем добавляем order_num из события OnOrder()
	--sqlitework:createTableTransId()

	
	
	--создаем окно робота с таблицей и добавляем в эту таблицу строки
	local position = {x=10,y=10,dx=285,dy=400}
	
	--создаем главное окно робота
	create_window(position)
	
	SetTableNotificationCallback (window.hID, f_cb)

	
	strategy.logstoscreen = logstoscreen  --это класс 
	
	strategy.secCode = sec --ENS для отладки --зачем вообще это нужно?
	
	
	
	
---------------------------------------------------------------------------	
	if createTableSignals() == false then
		return
	end

	SetWindowPos(signals.t_id, 810, 10, 600, 200)

---------------------------------------------------------------------------	
	if createTableOrders() == false then
		return
	end
	
	SetWindowPos(orders.t_id, 810, 220, 600, 200)
	
	--задержка 100 миллисекунд между итерациями 
	local i=0
	while is_run do
		i=i+1
		animation()
		
		if i >= 10 then
			main_loop()
			i=0
		end
		sleep(100)
		
	end

end

function createTableSignals()
	
	signals = QTable.new()
	if not signals then
		message("error creation table Signals!", 3)
		return false
	else
		--message("table with id = " ..signals.t_id .. " created", 1)
	end

	signals:AddColumn("id", QTABLE_INT_TYPE, 10)
	signals:AddColumn("dir", QTABLE_STRING_TYPE, 4)
	signals:AddColumn("account", QTABLE_STRING_TYPE, 10)
	signals:AddColumn("depo", QTABLE_STRING_TYPE, 10)
	signals:AddColumn("sec_code", QTABLE_STRING_TYPE, 10)
	signals:AddColumn("class_code", QTABLE_STRING_TYPE, 10)
	signals:AddColumn("date", QTABLE_CACHED_STRING_TYPE, 10) --время свечи, на которой сформировался сигнал
	signals:AddColumn("time", QTABLE_CACHED_STRING_TYPE, 10) --время свечи, на которой сформировался сигнал
	signals:AddColumn("price", QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("MA", QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("done", QTABLE_STRING_TYPE, 10)
	
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
	
	orders:AddColumn("signal_id", QTABLE_INT_TYPE, 10)
	orders:AddColumn("account", QTABLE_STRING_TYPE, 10)
	orders:AddColumn("depo", QTABLE_STRING_TYPE, 10)
	orders:AddColumn("sec_code", QTABLE_STRING_TYPE, 10)
	orders:AddColumn("class_code", QTABLE_STRING_TYPE, 10)
	orders:AddColumn("trans_id", QTABLE_INT_TYPE, 10)
	orders:AddColumn("order", QTABLE_INT_TYPE, 10)
	orders:AddColumn("trade", QTABLE_INT_TYPE, 10)
	
	orders:AddColumn("qty", QTABLE_INT_TYPE, 10) --количество из заявки
	orders:AddColumn("qty_fact", QTABLE_INT_TYPE, 10) --количество из сделок
	
	orders:SetCaption("orders")
	orders:Show()
	
	return true
	
end

function create_window(position)

	
	--создаем окно робота с таблицей и добавляем в эту таблицу строки
	window = Window()									--функция Window() расположена в файле Window.luac и создает класс
	
	--{'A','B'} - это массив с именами колонок
	--справка: http://smart-lab.ru/blog/291666.php
	--Чтобы создать массив, достаточно перечислить в фигурных скобках значения его элементов:
	--t = {«красный», «зеленый», «синий»}
	--Это выражение эквивалентно следующему коду:
	--t = {[1]=«красный», [2]=«зеленый», [3]=«синий»}	
	
	--window:Init("ENS MovingAverages", {'A','B'})	--вызываем метод init класса window
	window:Init(settings.TableCaption, {'A','B'}, position)	--вызываем метод init класса window
	window:AddRow({"Код","Цена"},"")
	window:AddRow({settings.SecCodeBox,"0"},"Grey")
	
	window:AddRow({"Lot to trade",""},"")
	window:AddRow({settings.LotSizeBox,"0"},"Grey")
	
	
	window:AddRow({"Позиция",""},"")
	window:AddRow({"",""},"Grey")
	
	window:AddRow({"MA (60)","Close"},"")
	window:AddRow({"",""},"Grey")
	
	window:AddRow({"MA pred (60)","PredClose"},"")
	window:AddRow({"",""},"Grey")

	window:AddRow({"Сигнал",""},"")
	window:AddRow({"",""},"Grey")
	
	window:AddRow({"",""},"")
	window:AddRow({"Buy по рынку",""},"Green")
	window:AddRow({"Sell по рынку",""},"Red")
	window:AddRow({"",""},"")
	window:AddRow({"Старт",""},"Green")
	
	window:AddRow({"TEST BUY",""},"Grey")
	window:AddRow({"TEST SELL",""},"Grey")
	window:AddRow({"TEST EMA",""},"Grey")
	

end

--+-----------------------------------------------
--|			ОСНОВНОЙ АЛГОРИТМ
--+-----------------------------------------------

--эта функция должна вызываться из обрамляющего цикла в функции main()
function main_loop()

	if isConnected() == 0 then
		window:InsertValue("Сигнал", "Not connected")
		return
	end
	
	security:Update()	--обновляет цену последней сделки в таблице security (свойство Last,Close)

	window:InsertValue("Цена",tostring(security.last)) --помещаем цену в окно робота. просто для визуального наблюдения		

	--источник комментов [1] - это http://robostroy.ru/community/article.aspx?id=796
	--[1]Сначала мы получаем количество свечей. здесь: на графике цены
	NumCandles = getNumCandles(settings.IdPriceCombo)	

	if NumCandles==0 then
		return 0
	end

	--СУУ_ЕНС тут запрашиваем 2 предпоследних свечи. последняя не нужна, т.к. она еще не сформирована
	tPrice,n,s = getCandlesByIndex(settings.IdPriceCombo,0,NumCandles-3, 2)		
	strategy:SetSeries(tPrice)

	--далее пошли запрашивать цены с графика moving averages
	--tPrice,n,s = getCandlesByIndex(settings.IdMA,0,NumCandles-3, 2)		
	--strategy.Ma1Series=tPrice	--этого поля (Ma1Series) нет в Init, оно создается здесь

	--главное начинается здесь

	--strategy:CalcLevels() --получим значения цены и средней скользящей
	
	EMA(settings.MAPeriod)--рассчитываем среднюю скользящую (экспоненциальную)

	
	--обновляем данные в визуальной таблице робота
	window:InsertValue("Позиция",tostring(trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox,settings.currency_CETS)))
	
	--window:InsertValue("MA (60)",tostring(strategy.Ma1))
	window:InsertValue("MA (60)",tostring(EMA_TMP[#EMA_TMP-1]))
	window:InsertValue("Close",tostring(strategy.PriceSeries[1].close))
	
	--window:InsertValue("MA pred (60)",tostring(strategy.Ma1Pred))
	window:InsertValue("MA pred (60)",tostring(EMA_TMP[#EMA_TMP-2]))
	window:InsertValue("PredClose",tostring(strategy.PriceSeries[0].close))
	
	
	if working==false  then
		return
	end
		
		
	-------------------------------------------------------------------
	--			ОСНОВНОЙ АЛГОРИТМ
	-------------------------------------------------------------------
	
	if current_state == 'waiting for a signal' then
		--ожидаем новые сигналы 
		wait_for_signal()
		
	elseif current_state == 'processing signal' then
		--в этом состоянии робот шлет заявки на сервер, пока не наберет позицию или не кончится время или количество попыток
		processSignal()
		
	elseif current_state == 'waiting for a response' then
		--заявку отправили, ждем пока придет ответ, перед отправкой новой
		wait_for_response()
		
	end

end

--обработать сигнал
function processSignal()
	
	logstoscreen:add('processing signal: '..signal_direction)
	
	--нужно посмотреть, на сколько лотов/контрактов нужно открыть позицию - это в настройках робота
	local planQuantity = tonumber(settings.LotSizeBox)
	if signal_direction == 'sell' then
		planQuantity = -1*planQuantity --сделаем отрицательным
	end
	logstoscreen:add('plan quantity: ' .. tostring(planQuantity))
	
	--посмотреть, сколько уже лотов/контрактов есть в позиции (с отбором по этому роботу)
	local factQuantity = trader:GetCurrentPosition(settings.SecCodeBox, settings.ClientBox, settings.currency_CETS)
	logstoscreen:add('fact quantity: ' .. tostring(factQuantity))
	
	if settings.rejim == 'revers' then
		--все разрешено
		
	elseif settings.rejim == 'long' then
		--нельзя в шорт. длинную позицию продаем в ноль
		if signal_direction == 'sell' and factQuantity>=0 then
			planQuantity = 0
		end
		
	elseif settings.rejim == 'short' then
		--нельзя в лонг. короткую позицию откупаем в ноль
		if signal_direction == 'buy' and factQuantity<=0 then
			planQuantity = 0
		end
	end
	
	--если эти значения отличаются, то добираем позу
	if (signal_direction == 'buy' and factQuantity < planQuantity )
		or (signal_direction == 'sell' and factQuantity > planQuantity)
		then
		
		--послать заявку
		
		trans_id = helper:getMiliSeconds_trans_id() --глобальная для скрипта переменная
		
		local qty = planQuantity - factQuantity
		
		if qty == 0 then
			logstoscreen:add('ОШИБКА! qty = 0')
			--переходим к ожиданию нового сигнала
			current_state = 'waiting for a signal'
			return
		end
		
		logstoscreen:add('qty: ' .. tostring(qty))
		
		if signal_direction == 'sell' then --приведем к положительному
			qty = -1*qty
		end
		
		
		--!!!!!!!!!!!!для отладки. хочу проверить как будет отрабатывать ожидание добора позиции 
		--qty = 5
		
		local row = orders:AddLine()
		orders:SetValue(row, "trans_id", trans_id)
		orders:SetValue(row, "signal_id", signal_id)
		orders:SetValue(row, "qty", qty)
		
		if signal_direction == 'buy' then
			Buy(qty, trans_id)
		elseif signal_direction == 'sell' then
			Sell(qty, trans_id)
		end
		
		--включаем флаг, признак того, что робот ждет ответа на выставленную заявку
		--флаг выключится в функции OnTrade()
		--we_are_waiting_result = true
		current_state = 'waiting for a response'

	else
		logstoscreen:add('вся позиция уже набрана, заявка не отправлена!')
		
		current_state = 'waiting for a signal'
		
		--обновим состояние сигнала в таблице сигналов
		local rows=0
		local cols=0
		rows,cols = signals:GetSize()
		for j = 1 , rows do --в таких таблицах нумерация начинается с единицы
			if tostring(signal_id) == tostring(signals:GetValue(j, "id").image) then
			
				signals:SetValue(j, "done", true) 
				break
			end
		end		
		
		signal_id = nil
		trans_id = nil
	end
	
end

--ждать ответа на отправленную заявку
function wait_for_response()
	logstoscreen:add('we are waiting the result of sending order')

	local s = orders:GetSize()
	for i = 1, s do
		
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trans_id) then
			
			if orders:GetValue(i, 'trade')~=nil and( orders:GetValue(i, 'trade').image~='0' or orders:GetValue(i, 'trade').image~='') then
				--если в таблице orders появился номер сделки, это значит что заявка обработалась.
				
				--а вот и не факт. нужно сравнить количество в заявке и в сделке. если заявка полностью удовлетворена, то только тогда это значит, что она обработалась
				--хотя для объемов в 10 лотов наверное любой фьючерс будет ликвидным...
				
				--пока не будут завязываться на это. просто выведу в лог
				local qty_fact = orders:GetValue(i, 'qty_fact').image
				if qty_fact == nil or qty_fact == '' then
					qty_fact = 0
				else
					qty_fact = tonumber(qty_fact)
				end
			
				if tonumber(orders:GetValue(i, 'qty').image) == qty_fact then
					
					logstoscreen:add('order '..orders:GetValue(i, 'order').image..': qty = qty_fact - order is processed')
					
				end
				
				logstoscreen:add('order '..orders:GetValue(i, 'order').image..' processed')
				
				current_state = 'processing signal'
				
			
			end
		end
	end
		
end

--ждать новые сигналы
function wait_for_signal()

	--нужно только так, сначала поместить сигналы в переменные, потом работать с переменными
	--это надо, чтобы работал тест сигналов - когда включается тестовый флаг, функция сигнала возвращает истину, а перед этим выключает флаг
	--т.е. более одного раза вызвать функцию сигнала в режиме теста не получится
	local signal_buy =  signal_buy()
	local signal_sell =  signal_sell()
	
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
	if find_signal(candle_date, candle_time) == true then
		return
	end
		
	--logstoscreen:add('we have got a signal: ')
	
	if signal_buy == true then 
		--закрытие свечи выше средней - покупка
		signal_direction = 'buy'
	elseif signal_sell == true	then 
		--закрытие часовика ниже средней - продажа
		signal_direction = 'sell'
	end
	
	--сигнала в таблице нет, добавляем новый
	
	signal_id = helper:getMiliSeconds_trans_id()
	
	local row = signals:AddLine()
	signals:SetValue(row, "id", 	signal_id)
	signals:SetValue(row, "dir", 	signal_direction)
	signals:SetValue(row, "date", candle_date)
	signals:SetValue(row, "time", 	candle_time) 
	signals:SetValue(row, "price", strategy.PriceSeries[1].close)
	signals:SetValue(row, "MA", 	EMA_TMP[#EMA_TMP-1])
	signals:SetValue(row, "done", false)
	
	--переходим в режим обработки сигнала. функция обработки сработает на следующей итерации
	current_state = 'processing signal'

end

--[[ищет сигнал в таблице сигналов. вызывается при поступлении нового сигнала.
сигнал будет поступать все следующее время после формирования, согласно выбранному таймфрейму графика цены
т.е. когда он поступил в момент формирования новой свечи, он еще будет поступать всю следующую свечу--]]
function find_signal(candle_date, candle_time)
	local rows=0
	local cols=0
	rows,cols = signals:GetSize()
	for i = 1 , rows do --в таких таблицах нумерация начинается с единицы
		if signals:GetValue(i, "date").image == candle_date and
			signals:GetValue(i, "time").image == candle_time then
			--уже есть сигнал, повторно обрабатывать не надо
			--logstoscreen:add('the signal is already processed: '..tostring(signals:GetValue(i, "id").image))
			return true
		end
	end
	return false
end
--+-----------------------------------------------
--|			ОСНОВНОЙ АЛГОРИТМ - КОНЕЦ
--+-----------------------------------------------


function animation()
	  
	if working==false then
		return false
	end
	
	local symb = ''
	
	if count_animation == 0 then
		symb = "-"
	elseif count_animation == 1 then
		symb = "\\"
	elseif count_animation == 2 then
		symb = "|"
	elseif count_animation == 3 then
		symb = "/"
	end
	count_animation=count_animation+1
	if count_animation>3 then
		count_animation = 0
	end
	window:InsertValue("Сигнал", symb)
end




function signal_buy()

--  Ma1 = Ma1Series[1].close						--предыдущая свеча
--  Ma1Pred = Ma1Series[0].close 	--ENS		--предпредыдущая свеча

	--для тестов
	if working == true then
		if test_signal_buy == true then
			test_signal_buy = false
			return true
		end
	end
	
	--[[
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
end

function signal_sell()

--  Ma1 = Ma1Series[1].close						--предыдущая свеча
--  Ma1Pred = Ma1Series[0].close 	--ENS		--предпредыдущая свеча


	--для тестов
	if working == true then
		if test_signal_sell == true then
			test_signal_sell = false
			return true
		end
	end
	
	if EMA_TMP[#EMA_TMP-1]  ~= 0 		--предыдущая свеча
	and EMA_TMP[#EMA_TMP-2]  ~= 0 		--предпредыдущая свеча
--	if strategy.Ma1 ~= 0 
--	and strategy.Ma1Pred  ~= 0 
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
	and strategy.PriceSeries[0].close > EMA_TMP[#EMA_TMP-2] --предпредыдущий бар выше средней
	and strategy.PriceSeries[1].close < EMA_TMP[#EMA_TMP-1] --предыдущий бар ниже средней
--	and strategy.PriceSeries[0].close > strategy.Ma1Pred --предпредыдущий бар выше средней
--	and strategy.PriceSeries[1].close < strategy.Ma1 --предыдущий бар ниже средней
	then
		return true
	else
		return false
	end

end



--
function Buy(LotToTrade, trans_id)
	logstoscreen:add("Buy " .. settings.SecCodeBox)
	--transactions:order(settings.SecCodeBox, settings.ClassCode, "B", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) + 60 * security.minStepPrice), LotToTrade)
	transactions:orderWithId(settings.SecCodeBox, settings.ClassCode, "B", settings.ClientBox, tostring(settings.DepoBox), tostring(tonumber(security.last) + 150 * security.minStepPrice), LotToTrade, trans_id)
	logstoscreen:add("transaction was sent "..helper:getMiliSeconds())
end

--вызывается из этого же файла. Strategy:DoBisness()
function Sell(LotToTrade, trans_id)
	logstoscreen:add("Sell " .. settings.SecCodeBox)
	--transactions:order        (settings.SecCodeBox, settings.ClassCode, "S", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) - 60 * security.minStepPrice), LotToTrade)
	transactions:orderWithId(settings.SecCodeBox, settings.ClassCode, "S", settings.ClientBox, tostring(settings.DepoBox), tostring(tonumber(security.last) - 150 * security.minStepPrice), LotToTrade, trans_id)
	logstoscreen:add("transaction was sent "..helper:getMiliSeconds())
end




--запускает тест стратегии. только добавляет сигнал, а остальное сделает DoBusiness
function TestBuy()

	--включаем флаг. выключим его потом в функции signal_buy()
	test_signal_buy = true
	
end

--запускает тест стратегии. только добавляет сигнал, а остальное сделает DoBusiness
function TestSell()

	--включаем флаг. выключим его потом в функции signal_sell()
	test_signal_sell = true
	
end


--свой расчет средней скользящей (чтобы терминал меньше занимал памяти, не будем добавлять на графики цен индикатор ЕМА, а посчитаем его сами)

--N - период средней (количество свечей)
--lastCandle - последняя рассчитанная свеча (чтобы не считать все с нуля на каждом вызове)
function EMA(N)

	--[1]Сначала мы получаем количество свечей. здесь: на графике цены
	local NumCandles = getNumCandles(settings.IdPriceCombo)	

--[[
В справке к Квику есть формула: 
EMAi = (EMAi-1 * (n-1) + 2*Pi) / (n+1), 
где Pi - значение цены в текущем периоде, 
EMAi - значение EMA текущего периода, 
EMAi-1 - значение EMA предыдущего периода 
Начальное значение равно параметру, по которому рассчитывается индикатор: EMA0=P0 – при расчете по цене 
--]]
	local tPrice = {}
	local n = 0
	local s = ''
	tPrice,n,s = getCandlesByIndex(settings.IdPriceCombo,0,0,NumCandles)		
	
	--пример работы со свечами
	--tPrice[number].datetime.hour
	--PriceSeries[0].close
	
	local answ = 0
	
	local idp = 11 --точность округлений (знаков после точки)
	local start = 0
	if lastCandleMA == nil then
		start = 0
	else
		start = lastCandleMA
	end
	for i = start, n-1 do
	
		fEMA(i, N, tPrice, idp)
		
	end
	
	lastCandleMA = n-1
	
end

--[[Exponential Moving Average (EMA)
EMAi = (EMAi-1*(n-1)+2*Pi) / (n+1)
]]
--ds - DataSource - таблица свечек
--idp - точность округления
function fEMA(Index, Period, ds, idp) 
	
	--logstoscreen:add('candle '..tostring(Index)..' close = '..tostring(ds[Index].close))
	local Out = 0
	if Index == 0 then
		EMA_TMP[Index]=round(ds[Index].close,idp)
		--logstoscreen:add('index = 0 and EMA = '..tostring(EMA_TMP[Index]))
	else
		local prev_ema = EMA_TMP[(Index-1)]
		local candle = ds[Index]
		EMA_TMP[Index]=round((prev_ema*(Period-1)+2*candle.close) / (Period+1),idp)
	end

	if Index >= Period-1 then -- минус 1 - потому что идем от нуля
		Out = EMA_TMP[Index]
		--logstoscreen:add('Index '..tostring(Index)..' EMA = '..tostring(EMA_TMP[Index]))
	end

	return round(Out,idp)
	
end

------------------------------------------------------------------
--Вспомогательные функции для EMA
------------------------------------------------------------------
function round(num, idp)
if idp and num then
   local mult = 10^(idp or 0)
   if num >= 0 then return math_floor(num * mult + 0.5) / mult
   else return math_ceil(num * mult - 0.5) / mult end
else return num end
end


