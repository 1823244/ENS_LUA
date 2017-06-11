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
local new_signal = false --это глобальный флаг состояние. когда Истина - робот ждет окончания набора позиции
local we_are_waiting_result = false
local signal_direction = ''			--направление сигнала buy/sell
local state_process_signal = false
local signals = nil --таблица обработанных сигналов.	
local orders = nil --таблица заявок
local trans_id = nil --здесь будет храниться номер транзакции, он будет помещен в таблицу orders
local signal_id = nil
--for debug
local test_signal_buy = false -- флаг, если истина, то функция сигнала вернет истину. для теста
local test_signal_sell = false -- флаг, если истина, то функция сигнала вернет истину. для теста


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

	window:InsertValue("Позиция",tostring(trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox)))
	settings:Load(trader.Path)
	strategy.LotToTrade=tonumber(settings.LotSizeBox)

	--прочитаем значения, не дожидаясь изменения параметров инструмента
	OnParam( settings.ClassCode, settings.SecCodeBox )
	
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

--Функция вызывается терминалом QUIK при при изменении текущих параметров. 
--class - строка, код класса
--sec - строка, код бумаги
function OnParam( class, sec )

	trans:CalcDateForStop()	--формирует строку ггммдд и возвращает ее в свойстве dateForStop таблицы trans
	
    if (tostring(sec) ~= settings.SecCodeBox)  then
		return 0
	end
		
	
	--main_loop()
	
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
	--message('onTrade '..helper:getMiliSeconds())
	logstoscreen:add('onTrade '..helper:getMiliSeconds())
	--[[
	safeIterationsTradesCount = safeIterationsTradesCount + 1
	if safeIterationsTradesCount >= safeIterationsTradesLimit then
		is_run = false
		working = false
		logstoscreen:add('safely break script (OnTrade)')
		logs:add('safely break script (OnTrade)')
		StopScript()
	end
	--]]
	
	--добавим номер заявки к сигналу, на основании которого она создана
	--add_order_num_to_signal(trade.trans_id, trade.order_num)
	
	
	local robot_id=''	--dummy
	
	--тут главное - найти ID сигнала, по которому прошла сделка
	
	--нам понадобятся поля
	--trade.trans_id
	--trade.order_num
	
	--нужно найти в таблице заявок этот trans_id. может быть несколько заявок (может ли?)
	--сравнить количество в сделке и количество в заявке
	--если равны - заявка исполнена целиком, можно:
	--		сменить ее статус
	--		проверить позицию (план и факт). если равны - закончить обработку заявки и сигнала
	--иначе - исполняем частично и ждем дальше
	--под частичным исполнением подразумеваем, что сделка увеличит размер позиции на свое количество
	
	
	local s = orders:GetSize()
	for i = 1, s do
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trade.trans_id) 
			and tostring(orders:GetValue(i, 'order').image) == tostring(trade.order_num) then
			orders:SetValue(i, 'trade', trade.trade_num)
			logstoscreen:add('OnTrade - trans_id '..tostring(orders:GetValue(i, 'trans_id').image))
			break
		end
	end
	
	
end

function OnOrder(order)
	if working == false then
		return
	end
	logstoscreen:add('onOrder '..helper:getMiliSeconds())
	--[[
	safeIterationsOrdersCount = safeIterationsOrdersCount + 1
	if safeIterationsOrdersCount >= safeIterationsOrdersLimit then
		is_run = false
		working = false
		logstoscreen:add('safely break script (OnOrder)')
		logs:add('safely break script (OnOrder)')
		StopScript()
	end
	--]]

	--добавим номер заявки к сигналу, на основании которого она создана
	-- 27 05 17. отсюда бесполезно вызывать эту функцию, т.к. колбэк OnOrder возникает позже,чем OnTrade :(
	-- add_order_num_to_signal(order.trans_id, order.order_num)
	
	
end

function add_order_num_to_signal(trans_id, order_num)


	--ищем заявку с таким же trans_id
	local sql = [[
	select
		rownum
	from
		transId
	where
		trans_id = ]] .. tostring(trans_id)
	
	--помещаем в найденную строку номер заявки
	for row in db:nrows(sql) do
		sql = [[
		update
			transId
		set
			order_num = ]] ..tostring(order_num) .. [[
		where
			rownum = ]] ..tostring(row.rownum)
		db:exec(sql)
	end
	
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
	
	strategy.db = db
	
	--создаем таблицу сигналов в базе
	sqlitework.db = db
	sqlitework:createTableSignals()
	--создаем таблицу позиций в базе
	sqlitework:createTablePositions()
	
	sqlitework:createTableOrders()
	
	--в этой таблице есть поля: rownum | trans_id | signal_id | order_num | robot_id
	--в нее пишем сначала из модуля strategy
	--а затем добавляем order_num из события OnOrder()
	sqlitework:createTableTransId()

	
	
	--создаем окно робота с таблицей и добавляем в эту таблицу строки
	local position = {x=10,y=10,dx=285,dy=400}
	
	create_window(position)
	
	SetTableNotificationCallback (window.hID, f_cb)

	
	strategy.logstoscreen = logstoscreen  --это класс 
	
	strategy.secCode = sec --ENS для отладки --зачем вообще это нужно?
	
	--это осталось от старого кода кбробота
	--strategy.Position=trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox)
	
---------------------------------------------------------------------------	
	signals = QTable.new()
	if not signals then
		message("error creation table Signals!", 3)
		return
	else
		--message("table with id = " ..signals.t_id .. " created", 1)
	end

	signals:AddColumn("id", QTABLE_INT_TYPE, 15)
	signals:AddColumn("date", QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("time", QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("price", QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("MA", QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("trans_id", QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("done", QTABLE_STRING_TYPE, 10)
	
	signals:SetCaption("Signals")
	signals:Show()

	SetWindowPos(signals.t_id, 810, 10, 500, 200)

---------------------------------------------------------------------------	
	orders = QTable.new()
	if not orders then
		message("error creation table orders!", 3)
		return
	else
		--message("table with id = " ..orders.t_id .. " created", 1)
	end

	orders:AddColumn("order", QTABLE_INT_TYPE, 20)
	orders:AddColumn("trade", QTABLE_INT_TYPE, 20)
	orders:AddColumn("trans_id", QTABLE_INT_TYPE, 20)
	
	orders:SetCaption("orders")
	orders:Show()
	
	SetWindowPos(orders.t_id, 810, 220, 500, 200)
	
	
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
	window:AddRow({"",""},"")
	window:AddRow({"TEST BUY",""},"Green")
	window:AddRow({"",""},"")
	window:AddRow({"TEST SELL",""},"Green")
	window:AddRow({"",""},"")	

end

--эта функция должна вызываться из обрамляющего цикла в функции main()
function main_loop()

	
	security:Update()	--обновляет цену последней сделки в таблице security (свойство Last,Close)

	window:InsertValue("Цена",tostring(security.last)) --помещаем цену в окно робота. просто для визуального наблюдения		

	--источник комментов [1] - это http://robostroy.ru/community/article.aspx?id=796
	--[1]Сначала мы получаем количество свечей. здесь: на графике цены
	NumCandles = getNumCandles(settings.IdPriceCombo)	

	if NumCandles==0 then
		--return 0
	end

	strategy.NumCandles=2

	--СУУ_ЕНС тут запрашиваем 2 предпоследних свечи. последняя не нужна, т.к. она еще не сформирована
	tPrice,n,s = getCandlesByIndex(settings.IdPriceCombo,0,NumCandles-3, 2)		
	strategy:SetSeries(tPrice)

	--далее пошли запрашивать цены с графика moving averages
	tPrice,n,s = getCandlesByIndex(settings.IdMA,0,NumCandles-3, 2)		
	strategy.Ma1Series=tPrice	--этого поля (Ma1Series) нет в Init, оно создается здесь


	--главное начинается здесь

		
	strategy:CalcLevels() --получим значения цены и средней скользящей
	

	if working==true  then
		--logstoscreen:add('----------------------------------')
		--logstoscreen:add('...main loop...')
		
	else
		return
		
	end
		
	if new_signal == false then
		--новые сигналы ожидаем только когда состояние робота не равно "обработка нового сигнала"
		local signal_buy =  signal_buy()
		local signal_sell =  signal_sell()
		if signal_buy == true or signal_sell == true then
			logstoscreen:add('we have got a signal: ')
			--если есть сигнал, нужно проверить, а может мы его уже обработали.-
			--таймфрейм тут планируется 1 час, поэтому главный цикл будет видеть сигнал
			--еще целый час после обработки
			local rows=0
			local cols=0
			rows,cols = signals:GetSize()
			local price_cell = {}
			local ma_cell = {}
			for i = 1 , rows do
				price_cell = signals:GetValue(i, "price")--потом доделать поиск по остальным полям
				ma_cell = signals:GetValue(i, "MA")--потом доделать поиск по остальным полям

				if tonumber(price_cell.image) == strategy.PriceSeries[1].close and tonumber(ma_cell.image) == strategy.Ma1 then 
					--уже есть сигнал, повторн обрабатывать не надо
					return
				end
			end
			
			--сигнала в таблице нет, добавляем новый
			
			signal_id = helper:getMiliSeconds_trans_id()
			
			local row = signals:AddLine()
			
			signals:SetValue(row, "id", signal_id)
			signals:SetValue(row, "date", os.date())
			signals:SetValue(row, "time", os.time()) --время свечи, потом переделать, а пока текущее время запишем
			signals:SetValue(row, "price", strategy.PriceSeries[1].close)
			signals:SetValue(row, "MA", strategy.Ma1)
			--signals:SetValue(row, "trans_id", )
			signals:SetValue(row, "done", false)
			
		end
		
		--закрытие свечи выше средней - покупка
		if signal_buy == true then 

			--if self:findSignal2()  == false then
			--	sig_id = self:saveSignal('buy')
			--end

			--включаем флаг, который выключим лишь после оокончания бработки сигнала
			new_signal = true
			logstoscreen:add('new_signal = '..tostring(new_signal))
			--processSignal('buy')
			signal_direction = 'buy'
			state_process_signal = true
			
		elseif signal_sell == true	then 

			--закрытие часовика ниже средней - продажа
			
			--if self:findSignal2()  == false then
			--	sig_id = self:saveSignal('sell')
			--end

			--включаем флаг, который выключим лишь после обработки сигнала
			new_signal = true
			logstoscreen:add('new_signal = '..tostring(new_signal))
			--processSignal('sell')
			signal_direction = 'sell'
			state_process_signal = true
			
		end
	
	else
	
		--сюда придем когда new_signal будет равен true
		
		if state_process_signal == true then
		
			if we_are_waiting_result == false then
			
				processSignal(signal_direction)
		
			else
				--заявку отправили, ждем пока придет ответ, перед отправкой новой
				logstoscreen:add('we are waiting the result of sending order')
				
				local s = orders:GetSize()
				for i = 1, s do
					--logstoscreen:add('trans_id = '..tostring(trans_id))
					if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trans_id) then
						--logstoscreen:add('trade = '..orders:GetValue(i, 'trade').image)
						if orders:GetValue(i, 'trade')~=nil and( orders:GetValue(i, 'trade').image~='0' or 
							orders:GetValue(i, 'trade').image~='') then
							--если в таблице orders появился номер сделки, это значит что заявка обработалась.
							we_are_waiting_result = false
							logstoscreen:add('order '..orders:GetValue(i, 'order').image..' processed')
							break
						end
					end
				end
				
				--a=1/0
				
			end
		end
	
	
	end	
		
		
	--обновляем данные в визуальной таблице робота
	window:InsertValue("MA (60)",tostring(strategy.Ma1))
	window:InsertValue("Close",tostring(strategy.PriceSeries[1].close))
	
	window:InsertValue("MA pred (60)",tostring(strategy.Ma1Pred))
	window:InsertValue("PredClose",tostring(strategy.PriceSeries[0].close))
	
	window:InsertValue("Позиция",tostring(strategy.Position))

		
end

--обработать сигнал
function processSignal(direction)
	
	logstoscreen:add('processing signal: '..direction)
	
	--нужно посмотреть, на сколько лотов/контрактов нужно открыть позицию - это в настройках робота
	local planQuantity = tonumber(settings.LotSizeBox)
	if direction == 'sell' then
		planQuantity = -1*planQuantity
	end
	logstoscreen:add('plan quantity: ' .. tostring(planQuantity))
	
	--посмотреть, сколько уже лотов/контрактов есть в позиции (с отбором по этому роботу)
	local factQuantity = trader:GetCurrentPosition(settings.SecCodeBox, settings.ClientBox)
	logstoscreen:add('fact quantity: ' .. tostring(factQuantity))
	
	--если эти значения отличаются, то добираем позу
	if (direction == 'buy' and factQuantity < planQuantity )
		or (direction == 'sell' and factQuantity > planQuantity)
		then
		
	
		--послать заявку
		
		trans_id = helper:getMiliSeconds_trans_id() --глобальная для скрипта переменная
		
		local qty = planQuantity - factQuantity
		
		logstoscreen:add('qty: ' .. tostring(qty))
		
		if direction == 'sell' then
			qty = -1*qty
		end
		
		--!!!!!!!!!!!!для отладки. хочу проверить как будет отрабатывать ожидание добора позиции 
		--qty = 1
		
		local row = orders:AddLine()
		orders:SetValue(row, "trans_id", trans_id)
		
		if direction == 'buy' then
			Buy(qty, trans_id)
		elseif direction == 'sell' then
			Sell(qty, trans_id)
		end
		
		--включаем флаг, признак того, что робот ждет ответа на выставленную заявку
		--флаг выключится в функции OnTrade()
		we_are_waiting_result = true
		
	else
		logstoscreen:add('вся позиция уже набрана, заявка не отправлена!')
		new_signal = false
		state_process_signal = false
	end
	
end

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

	--для тестов
	if working == true then
		if test_signal_buy == true then
			test_signal_buy = false
			return true
		end
	end
	
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
end

function signal_sell()

	--для тестов
	if working == true then
		if test_signal_sell == true then
			test_signal_sell = false
			return true
		end
	end
	
	if strategy.Ma1 ~= 0 
	and strategy.Ma1Pred  ~= 0 
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
	and strategy.PriceSeries[0].close > strategy.Ma1Pred --предпредыдущий бар выше средней
	and strategy.PriceSeries[1].close < strategy.Ma1 --предыдущий бар ниже средней
	then
		return true
	else
		return false
	end

end


--вызывается из этого же файла. Strategy:DoBisness()
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
