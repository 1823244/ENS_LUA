--[[Справка.
	все инструменты должны торговаться в пределах одного торгового счета
	если есть необходимость запустить робота на двух счетах, то нужно запускать двух роботов
	имеется в виду, если есть ИИС и обычный
	хотя вообще это не строгое условие

	инструкция по настройке
	создать функцию, которая возвращает массив инструментов, образец - secListFutures()
	добавить инструменты в таблицу в функции main, см. по образцу
	создать графики цены всех новых инструментов. идентификатор графика формируется на основании тикера, см. образец готово.
--]]

--[[cheat sheet.
	установка значения в ячейке таблицы
		setVal(row, 'LastPrice', tostring(security.last))
	получение значения из ячейки
		local acc = getVal(row, 'Account')
	запись в лог:
		logstoscreen:add2(window, row, nil,nil,nil,nil,'message to log')
--]]

local sqlite3 = require("lsqlite3")

local math_ceil = math.ceil
local math_floor = math.floor

--common classes
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\class.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\class.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Window.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Helper.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Trader.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Transactions.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Security.lua") 
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\logs.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\logstoscreen.lua")

--common within one strategy
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Strategies\\StrategyOLE.lua")

--private for each robot
dofile (getScriptPath().."\\Classes\\SettingsGRID.lua")
dofile (getScriptPath().."\\Classes\\HelperGRID.lua")--вспомогательные функции только для этого робота

dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\EMA.lua")

dofile (getScriptPath() .. "\\quik_table_wrapper.lua")

--Это классы, которые на самом деле являются таблицами
trader={}
trans={}
helper={}
helperGrid={}
settings={}
strategy={}
security={}
window={}
logstoscreen={}
EMAclass = {}
logs={}

local is_run = true	--флаг работы скрипта, пока истина - скрипт работает

local signals = {} --таблица обработанных сигналов.	
local orders = {} --таблица заявок

--эти таблицы нужны для того, чтобы не обрабатывать повторные колбэки на одни и те же сделки/заявки
local processed_trades = {} --таблица обработанных сделок
local processed_orders = {} --таблица обработанных заявок

local db = nil --подключение к базе SQLite


function OnInit(path)
	trader = Trader()
	trader:Init(path)
	trans= Transactions()
	trans:Init()
	settings=Settings()
	settings:Init()
	helper= Helper()
	helper:Init()
	helperGrid= HelperGrid()
	helperGrid:Init()
	security=Security()
	security:Init()
	strategy=Strategy()
	strategy:Init()
	transactions=Transactions()
	transactions:Init()
	
  	logstoscreen = LogsToScreen()
	
	helperGrid.logstoscreen = logstoscreen
	
	local extended = true--флаг расширенной таблицы лога
	logstoscreen:Init(settings.log_position, extended) 	
	
	db = sqlite3.open(settings.db_path)
	
	--отключаем паранойю в сохранности данных, чтобы ускорить insert. по мотивам http://pawno.su/showthread.php?t=105737 (осторожнее, там сайт открывает всплывающие окна!)
	--результат: до выклчюения 50 записей вставлялись 5 секунд, после - 1 секунду и это, похоже не предел, я большее количество записей не проверял
	db:exec('PRAGMA journal_mode = OFF')
	db:exec('PRAGMA synchronous = OFF')
	
	
	helperGrid.db = db
	
	--создадим таблицы для ведения логов и сигналов в SQLite
	helperGrid:create_sqlite_table_orders()
	helperGrid:create_sqlite_table_signals()
	helperGrid:create_sqlite_table_Logs()
		
	EMAclass=MovingAverage()
	EMAclass:Init()
end

--[[это не обработчик события, а просто функция покупки/продажи
	Parameters:
		row - int - number of row in main table
		direction - string - deal direction. for case when function uses outside of main algorithm. values: 'buy', 'sell' --]]
function buySell(row, direction)

	local SecCodeBox	= getVal(row, 'Ticker')
	local ClassCode 	= getVal(row, 'Class')
	local ClientBox 	= getVal(row, 'Account')
	local DepoBox 		= getVal(row, 'Depo')
	--идентификатор транзакции нужен обязательно, чтобы потом можно было понять, на какую транзакцию пришел ответ
	local trans_id 		= tonumber(getVal(row, 'trans_id'))
	
	--если передано направление - используем его
	local dir = ''
	if direction ~= nil then
		dir = direction
	else
		dir 			= getVal(row, 'sig_dir')
	end

	--количество для заявки берем из "переменной" - поля qty в главной таблице в строке из параметра row
	local qty 			= tonumber(getVal(row, 'qty'))
	
	--получаем цену последней сделки, чтобы обладать актуальной информацией
	security.class = ClassCode
	security.code = SecCodeBox
	security:Update()
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() цена Last '..tostring(security.last))
	logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() minStepPrice '..tostring(security.minStepPrice))


	
	local price = 0

	if dir == 'buy' then
		price = tonumber(security.last) + 150 * security.minStepPrice
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() price = last + 150 * minStepPrice =  '..tostring(price))
	elseif dir == 'sell' then
		price = tonumber(security.last) - 150 * security.minStepPrice
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() price = last - 150 * minStepPrice =  '..tostring(price))
	end		

	--проверка цены на превышение лимитов (только для фьючей)
	if ClassCode == 'SPBFUT' or ClassCode == 'SPBOPT' then

		security:GetEdgePrices()
	
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() pricemax '..tostring(security.pricemax))--только для фьючей
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() pricemin '..tostring(security.pricemin))--только для фьючей
	
		if dir == 'buy' then
			if security.pricemax~=0 and price > security.pricemax then
				price = security.pricemax
				logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() цена была скорректирована из-за выхода за границы диапазона. Новое значение '..tostring(price))
			end
		elseif dir == 'sell' then
			if security.pricemin~=0 and price < security.pricemin then
				price = security.pricemin
				logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() цена была скорректирована из-за выхода за границы диапазона. Новое значение '..tostring(price))
			end
		end		
	end
	
    if dir == 'buy' then
		transactions:orderWithId(SecCodeBox, ClassCode, "B", ClientBox, DepoBox, tostring(price), qty, trans_id)
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() отправлена транзакция ИД '..tostring(trans_id)..' с направлением BUY по цене '..tostring(price) .. ', цена инструмента была '..tostring(security.last) .. ', количество '..tostring(qty))
	elseif dir == 'sell' then
		transactions:orderWithId(SecCodeBox, ClassCode, "S", ClientBox, DepoBox, tostring(price), qty, trans_id)
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() отправлена транзакция ИД '..tostring(trans_id)..' с направлением SELL по цене '..tostring(price) .. ', цена инструмента была '..tostring(security.last) .. ', количество '..tostring(qty))
	end	
	
	--очищаем, т.к. это временно значение
	setVal(row, 'qty', tostring(0))
	
end


function OnConnected(flag)
  --http://www.kamynin.ru/2015/02/11/lua-proverka-podklyucheniya-k-serveru-quik/
  --[[
    Проблема обычно в том, что после подключения т е когда isconnected уже сработал,
    терминал осуществляет загрузку данных с сервера.
    Т е если Вы по сигналу isConnected запустите скрипт,
    то можете получить пустые окна графиков и пустые таблицы.
    приведенный алгоритм позволяет запускать скрипт после загрузки исходных данных.
    Т е данный алгоритм определяет не только наличие соединения, но и приход исходных данных.
    Поэтому isConnected можно не использовать.
    Вообще-то, я использую колбек- OnConnected и данный алгоритм.  
  --]]
  
  --При написании роботов на LUA для терминала QUIK возникает проблема запуска робота после подключения к серверу.
  --Данную проблему можно решить следующим образом.
  
  
  --[[
  local i=200 
  local s=getInfoParam('SERVERTIME')
  
  while i>=0 and s=='' do 
    i=i-1
    sleep(200)
    s=getInfoParam('SERVERTIME')
  end
 
  local is_run = true  --флаг работы скрипта, пока истина - скрипт работает
  --]]
 
end

--this is callback
function OnStop(s)

	stopScript()
	
end 

--shutting windows and turning off working flag
function stopScript()

	is_run = false
	window:Close()
	
	logstoscreen:CloseTable()
	DestroyTable(signals.t_id)
	DestroyTable(orders.t_id)

	
end

--рефакторинг. запуск в работу одного инструмента
function startStopRow(row)

	if getVal(row, 'StartStop') == 'start' then
		helperGrid:Red(window.hID, row, window:GetColNumberByName('StartStop'))

		setVal(row, 'StartStop', 'stop')
		setVal(row, 'current_state', 'wait_for_new_theor')
		logstoscreen:add2(window, row, nil,nil,nil,nil,'StartStopRow() инструмент запущен в работу')
	else
		helperGrid:Green(window.hID, row, window:GetColNumberByName('StartStop'))
		setVal(row, 'StartStop', 'start')
		setVal(row, 'current_state', 'stopped')
		logstoscreen:add2(window, row, nil,nil,nil,nil,'StartStopRow() инструмент остановлен')
		setVal(row, 'LastPrice', tostring(0))
	end
end


--callback
function OnTransReply(trans_reply)

	--помещаем номер заявки в таблицу Orders, в строку с текущим trans_id
	local s = orders:GetSize()
	local rowNum=nil
	local found = false
	local orders_row = nil
	for i = s, 1, -1 do
		
		--здесь придется обойтись без строки в главной таблице - row, т.к. в контексте этой функции невозможно понять, по какой строке пришел колбэк
		--но это не будет проблемой, т.к. trans_id вполне однозначно определяет по какому инструменту ждем ответ.
		--не важно, что за заявка - лимитка или стоп-ордер.
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trans_reply.trans_id) then
			orders:SetValue(i, 'order', trans_reply.order_num)
			--logstoscreen:add2(window, row, nil,nil,nil,nil,'OnTransReply - trans_id '..tostring(orders:GetValue(i, 'trans_id').image))
			rowNum=tonumber(orders:GetValue(i, 'row').image)
			found = true
			orders_row = i
			break

		end
		
	end
	
	
	logstoscreen:add2(window, rowNum, nil,nil,nil,nil,'OnTransReply '..helper:getMiliSeconds() ..', trans_id = '..tostring(trans_reply.trans_id) .. ', status = ' ..tostring(trans_reply.status))	

	if trans_reply.status == 2 or trans_reply.status > 3 then
		logstoscreen:add2(window, rowNum, nil,nil,nil,nil,  'ERROR trans_id = '..tostring(trans_reply.trans_id) .. ', status = ' ..tostring(trans_reply.status) ..', '..helperGrid:StatusByNumber(trans_reply.status) )
		logstoscreen:add2(window, rowNum, nil,nil,nil,nil,  'подробное сообщение к предыдущей строке: '.. trans_reply.result_msg)
		
		--выключаем инструмент, по которому пришла ошибка
		if rowNum~=nil then
			setVal(rowNum, 'StartStop', 'stop')--turn off
			startStopRow(rowNum)
			logstoscreen:add2(window, rowNum, nil,nil,nil,nil,  'instrument was turned off due to error with code '..tostring(trans_reply.status))
		end
		
		--пишем признак ошибки в таблицу Orders
		orders:SetValue(orders_row, 'trans_reply', 'FAIL')
	end
	
end 

--callback
function OnTrade(trade)

	--если сделка уже есть в таблице обработанных, то еще раз не надо ее обрабатывать
	local found = false
	for i = #processed_trades, 1, -1 do
		if tostring(processed_trades[i]) == tostring(trade.trade_num) then
			found = true
			break
		end
	end
	if found == true then
		return
	else
		--добавляем сделку в таблицу обработанных
		processed_trades[#processed_trades+1] = trade.trade_num
	end
		
	
	
	--добавим количество из сделки в колонку qty_fact главной таблицы
 
	for i = orders:GetSize(),1,-1 do
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trade.trans_id) 
			and tostring(orders:GetValue(i, 'order').image) == tostring(trade.order_num) then

			logstoscreen:add2(window, tonumber(orders:GetValue(i, 'row').image), nil,nil,nil,nil,'OnTrade() '..helper:getMiliSeconds() ..', trans_id = '..tostring(trade.trans_id) .. ', number = ' ..tostring(trade.trade_num).. ', order number = ' ..tostring(trade.order_num))


			orders:SetValue(i, 'trade', trade.trade_num)
			local qty_fact = orders:GetValue(i, 'qty_fact').image
			if qty_fact == nil or qty_fact == '' then
				qty_fact = 0
			else
				qty_fact = tonumber(qty_fact)
			end
			local newFactQty = qty_fact + tonumber(trade.qty)
			
			local amount = orders:GetValue(i, 'amount').image
			if amount == nil or amount == '' then
				amount = 0
			else
				amount = tonumber(amount)
			end
			
			--сумма будет неправильная, т.к. количество в сделке - в лотах, но это нам не важно, главное - цена, а она будет правильной!
			local newAmount = amount + tonumber(trade.price*trade.qty)
			orders:SetValue(i, 'qty_fact', newFactQty)
			orders:SetValue(i, 'amount', newAmount)
			if newFactQty~=0 then
				orders:SetValue(i, 'avg_price', newAmount/newFactQty)
			else
				orders:SetValue(i, 'avg_price', 0)
			end
			--logstoscreen:add2(window, row, nil,nil,nil,nil,'OnTrade - trans_id '..tostring(orders:GetValue(i, 'trans_id').image))
			break
		end
	end
	
end

--callback
function OnOrder(order)
	
	--тут есть нюанс. приходят несколько колбэков, и в первом еще нет trans_id! поэтому первый колбэк не обрабатываем
	if order.trans_id==0 then
		return
	end
	--если заявка уже есть в таблице обработанных, то еще раз не надо ее обрабатывать
	local found = false
	for i = #processed_orders, 1, -1 do
		
		if tostring(processed_orders[i]) == tostring(order.order_num) then
			found = true
			break
		end
	end
	if found == true then
		--пока отключим, для отладки
		--return
	else
		processed_orders[#processed_orders+1] = order.order_num
	end
	
  for i = orders:GetSize(),1,-1 do
    if tostring(orders:GetValue(i, 'trans_id').image) == tostring(order.trans_id) 
      and tostring(orders:GetValue(i, 'order').image) == tostring(order.order_num) then

        logstoscreen:add2(window, tonumber(orders:GetValue(i, 'row').image), nil,nil,nil,nil,'OnOrder() '..helper:getMiliSeconds() ..', trans_id = '..tostring(order.trans_id) .. ', number = ' ..tostring(order.order_num))

      break
    end
  end
	
	
end

--[[f_cb – функция обратного вызова для обработки событий в таблице. вызывается из main()
	(или, другими словами, обработчик клика по таблице робота)
	параметры:
	t_id - хэндл таблицы, полученный функцией AllocTable()
	msg - тип события, происшедшего в таблице
	par1 и par2 – значения параметров определяются типом сообщения msg --]]
local f_cb = function( t_id,  msg,  par1, par2)
	
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
				startStopRow(par1)
			else
				--Stop but not closed
				startStopRow(par1)
			end
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('BuyMarket') then
			--message('buy')
			buySell(par1, 'buy')
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('SellMarket') then
			--message('buy')
			buySell(par1, 'sell')
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('test_buy') then
			--message('buy')
			setVal(par1, 'test_buy', 'true')
			
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('test_sell') then
			--message('buy')
			setVal(par1, 'test_sell', 'true')
			
		end
	end


	if (msg==QTABLE_CLOSE)  then
		--window:Close()
		--is_run = false
		--working = false
		stopScript()
	end

	--закрытие окна робота кнопкой ESC
	if msg==QTABLE_VKEY then
		--message(par2)
		if par2 == 27 then-- esc
			--window:Close()
			--is_run=false
			--working = false
			stopScript()
		end
	end	

end 

--читает из настроек таблицу инструментов и добавляет строки с ними в главную таблицу
function addRowsToMainWindow()

	local List = settings:instruments_list() --Это двумерный массив (таблица)
	
	--добавляем строки с инструментами в таблицу робота
	for row=1, #List do
		
		rowNum = InsertRow(window.hID, -1)
		
		'current_state',--состояние робота по этой строке инструмента
		'BaseAsset',
		'Ticker',
		'PutCall',--put/call
		'Plan',	--qty plan
		'Action', --buy/sell
		'Class',--SPBOPT	
		'Expiration',
		'Account',
		'Depo',
		'StartStop',--10 режим включения. start (включается сразу после запуска) / stop (не включается)
		'TheorDiff',--11 отступ от теор цены. в шагах цены. например, +2 - дороже на шага, -3 - дешевле на 3 шага

		setVal(rowNum, 'Account', 	List[row][9])
		setVal(rowNum, 'Depo', 		List[row][8])
		setVal(rowNum, 'Name', 		List[row][1]) 
		setVal(rowNum, 'Ticker', 	List[row][3]) --код бумаги
		setVal(rowNum, 'Class', 	List[row][6]) --класс бумаги
		setVal(rowNum, 'Lot', 		List[row][4]) --размер лота для торговли
		--здесь наоборот надо, если в настройках start, то нужно запустить робота, а в поле StartStop поместить действие stop
		setVal(rowNum, 'StartStop', List[row][9])

		setVal(rowNum, 'BuyMarket', 'Buy')
		setVal(rowNum, 'SellMarket', 'Sell')
		
		--чтобы получить номер колонки используем функцию GetColNumberByName()
		helperGrid:Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		helperGrid:Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
		
		--local minStepPrice = getParamEx(List[row][6], 	List[row][3], "SEC_PRICE_STEP").param_value + 0
		--setVal(rowNum, 'minStepPrice', tostring(minStepPrice))
		
		
	end  

end


--+-----------------------------------------------
--|			MAIN
--+-----------------------------------------------

function main()
	--главная функция робота, которая гоняется в цикле
	
	if settings.invert_deals == true then
		message('включено инвертирование сделок!!!',3)
		logstoscreen:add2(window, nil, nil,nil,nil,nil,'включено инвертирование сделок!!!')
	end

	--создаем вспомогательные таблицы

	--signals
	if helperGrid:createTableSignals() == false then
		return
	end
	signals = helperGrid.signals

	--orders
	if helperGrid:createTableOrders() == false then
		return
	end	
	orders = helperGrid.orders
	
	--создаем окно робота с таблицей и добавляем в эту таблицу строки
	window = Window()									--функция Window() расположена в файле Window.luac и создает класс
	
	--ENS класс window содержит поле columns, чтобы потом можно было найти  номер колонки по имени
	
	--формат идентификатора: кодИнструмента_grid_MA60, кодИнструмента_grid_price
	
	--last_theor - последняя теор цена, определенная на предыдущей итерации

	--колонки 'BuyMarket','SellMarket' - это "кнопки", т.е. колонки, по которым нужно даблкликнуть, чтобы купить/продать по рынку количество контрактов из колонки Lot
	--'StartStop' - "кнопка", управляющая включением робота для конкретного инструмента. если робот выключен, то он все равно показывает
	--значения последней цены, предпредыдущей и предыдущей цены и средней скользящей
	
	--rejim: long / short / revers
	--sig_dir - signal direction
	--trans_id - число, идентификатор пользовательской транзакции, отправленной программно. по нему фильтруем сделки и заявки при наборе позиции
	--current_state - текущее состояние по инструменту
	--signal_id - идентификатор сигнала
	
	
	
	local t = settings:create_main_t()

	window:Init(settings.TableCaption, t, settings.main_position)
	
	--добавляем строки с инструментами в главную таблицу
	addRowsToMainWindow()

	--обработчик событий главной таблицы
	SetTableNotificationCallback (window.hID, f_cb)

	--запускаем все согласно настроек	
	local col = window:GetColNumberByName('StartStop')
	for row=1, GetTableSize(window.hID) do
		if settings.start_all == true then
			startStopRow(row)
		else
			helperGrid:Green(window.hID, row, window:GetColNumberByName('StartStop'))
		end
		
	end
	
	--главный цикл
	while is_run do
	
		for row=1, GetTableSize(window.hID) do
			main_loop(row)
		end
		
		sleep(50)
	end

end

--+-----------------------------------------------
--|			ОСНОВНОЙ АЛГОРИТМ
--+-----------------------------------------------

function main_loop(row)
	--*эта функция должна вызываться из обрамляющего цикла в функции main()
	if isConnected() == 0 then
		return
	end
	--еще одна проверка по мотивам http://www.kamynin.ru/2015/02/11/lua-proverka-podklyucheniya-k-serveru-quik/
	--если в программе надо проверить подключение, то это лучше делать так:
	if getInfoParam('SERVERTIME')=='' then
		-- подключения нет
		return false
	else
		--есть подключение
	end
	local serv_time=tonumber(helperGrid:timeformat(getInfoParam("SERVERTIME"))) -- помещение в переменную времени сервера в формате HHMMSS
	--logstoscreen:add2(window, row, nil,nil,nil,nil,'server time '..tostring(serv_time))
	--первые 5 минут не торгуем
	if not (serv_time>=100500 and serv_time<235000) then
		return false
	end 	
	--если строка выключена то можно проверить это здесь, а можно чуть дальше, чтобы сигналы все же показывались
	--[[
	if getVal(row, 'StartStop') =='start'  then --инструмент выключен. когда включен, там будет Stop
		return
	end		
	--]]	
	--+-----------------------------------------------------------------
	--|			ОСНОВНОЙ АЛГОРИТМ
	--+-----------------------------------------------------------------
	--local current_state = getVal(row, 'current_state')
	local is_running = getVal(row, 'StartStop') =='stop' --строка запущена в работу

	--для строки нужно получить теор цену и выставить заявку в стакан по какой-то цене,
	--которая отличается от теории на заданную величину

	local theor = getParamEx(getVal(row, 'Class'), getVal(row, 'Ticker'), "THEORPRICE").param_value + 0
	local minStepPrice = getParamEx(getVal(row, 'Class'), getVal(row, 'Ticker'), "SEC_PRICE_STEP").param_value + 0
	
	if getVal(row, 'current_state') == 'wait_for_new_theor'	--если мы в состоянии ожидания новой тер цены
		and getVal(row, 'last_theor')~=theor 				--и если теория поменялась
		and getVal(row,'plan')~=getVal(row,'fact') 			--и позиция еще не набрана
		then
	
		--переключаем состояние робота на "ждем удаления"
		setVal(row, 'current_state', 'kill_order')

	elseif getVal(row, 'current_state') == 'kill_order' then
		--убить заявку
		--у нас есть trans_id выставленной заявки,
		--по нему нужно найти номер, который есть в таблице orders		

		local number = nil
		for i = orders:GetSize(), 1, -1 do
			if tostring(orders:GetValue(i, 'trans_id').image) == tostring(getVal(row,'trans_id')) then
				number=tonumber(orders:GetValue(i, 'order').image)
				break
			end
		end			
		transactions:killOrder(number, getVal(row, 'Ticker'), getVal(row, 'Class'))

		--переключаем состояние робота на "ждем удаления"
		setVal(row, 'current_state', 'wait_for_kill_order')

	elseif getVal(row, 'current_state') == 'wait_for_kill_order' then
		--ждем удаления
		
		for i = orders:GetSize(), 1, -1 do
			if tostring(orders:GetValue(i, 'trans_id').image) == tostring(getVal(row,'trans_id')) and orders:GetValue(i, 'deleted').image == 'true' then
				--переключаем состояние робота на "отправить заявку"
				setVal(row, 'current_state', 'send_new_order')
				break
			end
		end	
	
	elseif getVal(row, 'current_state') == 'send_new_order' then

		--выставить новую заявку

		local new_theor = theor + minStepPrice

		local trans_dir=''
		if getVal(row, 'sig_dir')=='buy' then
			trans_dir="B"
		else
			trans_dir="S"
		end

		local qty = 1 --getVal(row, 'Lot')

		local trans_id = helper:getMiliSeconds_trans_id()

		transactions:orderWithId(getVal(row, 'Ticker'), getVal(row, 'Class'), trans_dir, getVal(row, 'Account'), getVal(row, 'Depo'), tostring(new_theor), qty, trans_id)

		setVal(row, 'current_state', 'wait_for_new_order')

	elseif getVal(row, 'current_state') == 'wait_for_new_order' then

		--ждем появления новой заявки в таблице orders
		local deleted = false
		for i = orders:GetSize(), 1, -1 do
			if tostring(orders:GetValue(i, 'trans_id').image) == tostring(getVal(row,'trans_id')) then
				--переключаем состояние робота на "ждать новую теорию". цикл замкнулся
				setVal(row, 'current_state', 'wait_for_new_theor')
				break
			end
		end	
	end


end

--[[это не обработчик события, а просто функция покупки/продажи
	Parameters:
		row - int - number of row in main table
		direction - string - deal direction. for case when function uses outside of main algorithm. values: 'buy', 'sell' --]]

function processSignal(row)
	--функция набирает позицию

	--нужно посмотреть, на сколько лотов/контрактов нужно открыть позицию - это в настройках каждой строки с инструментом
	local planQuantity = tonumber(getVal(row, 'Lot'))
	
	local signal_direction = getVal(row, 'sig_dir') -- 'buy'/'sell'
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'processing signal: '..signal_direction)
	
	if signal_direction == 'sell' then
		planQuantity = -1*planQuantity --сделаем отрицательным
	end
	
	
	
	--посмотреть, сколько уже лотов/контрактов есть в позиции (валюту для СЭЛТ пока оставим пустой, главное - сделать базовый функционал)
	local factQuantity = trader:GetCurrentPosition(getVal(row, 'Ticker'), 
													getVal(row, 'Account'),
													getVal(row, 'Class'))
		
	logstoscreen:add2(window, row, nil,nil,nil,nil,'fact quantity: ' .. tostring(factQuantity))
	
	local rejim = getVal(row, 'rejim')--'long'/'short'/'revers'

	if rejim == 'revers' then
		--все разрешено
		
	elseif rejim == 'long' then
		--нельзя в шорт. длинную позицию продаем в ноль
		if signal_direction == 'sell' and factQuantity >= 0 then
			planQuantity = 0
		end
		
	elseif rejim == 'short' then
		--нельзя в лонг. короткую позицию откупаем в ноль
		if signal_direction == 'buy' and factQuantity <= 0 then
			planQuantity = 0
		end
	end
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'plan quantity: ' .. tostring(planQuantity))
	
	local signal_id = getVal(row, 'signal_id')
	
	--если эти значения отличаются, то добираем позу
	if (signal_direction == 'buy' and factQuantity < planQuantity )
		or (signal_direction == 'sell' and factQuantity > planQuantity)
		then
		
		--послать заявку

		--сформируем ID заявки, чтобы потом можно быть ее отловить
		local trans_id = helper:getMiliSeconds_trans_id()
		--закинем ID заявки в строку главной таблицы
		setVal(row, 'trans_id', tostring(trans_id))		
		--рассчитаем количество для добора позиции
		local qty = planQuantity - factQuantity		
		if qty == 0 then
			logstoscreen:add2(window, row, nil,nil,nil,nil,'ОШИБКА! qty = 0')
			--если получилось нулевое количество - переходим к ожиданию нового сигнала
			setVal(row, 'current_state', 'waiting for a signal')
			setVal(row, 'sig_dir', ' ')
			return
		end
		if signal_direction == 'sell' then --приведем к положительному, т.к. в заявке не может быть отрицательного количества
			qty = -1*qty
		end
		logstoscreen:add2(window, row, nil,nil,nil,nil,'количество в заявку: ' .. tostring(qty))
		
		--!!!!!!!!!!!!для отладки. хочу проверить как будет отрабатывать ожидание добора позиции 
		--можно поставить любое число. например, если поставить 1, то позиция будет набираться одним лотом до планового количества
		--qty = 5

		setVal(row, 'qty', tostring(qty))
		
		--для визуального контроля пишем информацию о заявке во вспомогательную таблицу. там же идет запись в sqlite		
		helperGrid:addRowToOrders(row, trans_id, signal_id, signal_direction, qty, window, 0) 
		
		--сохраним "старую" позицию
		setVal(row, 'savedPosition', tostring(factQuantity))
		
		--универсальная функция покупки/продажи. направление и количество она возьмет из строки "row"
		buySell(row)
		
		--После отправки транзакции на биржу меняем состояние робота на то, в котором он ждет ответа на выставленную заявку - 'waiting for a signal'
		--Здесь может сложиться ситуация, когда buySell() будет исполняться долго, а в ответ ей придет,
		--что заявка не может быть исполнена. В этом случае OnTransReply() поставит состояние 'stopped',
		--а здесь мы должны проверить, установлено оно или нет, чтобы не поменять на 'waiting for a response',т.к. это ошибка.
		if getVal(row, 'current_state') ~= 'stopped' then
			setVal(row, 'current_state', 'waiting for a response')
		end

	else
		--позиция набрана
		--logstoscreen:add2(window, row, nil,nil,nil,nil,'вся позиция уже набрана, заявка не отправлена!')
		
		--переключаем состояние робота на прием новых сигналов
		setVal(row, 'current_state', 'waiting for a signal')
		
		--обновим состояние сигнала в таблице сигналов
		for j = signals:GetSize(), 1, -1 do --в таких таблицах нумерация начинается с единицы
			if tostring(signal_id) == tostring(signals:GetValue(j, "id").image) 
						   and row == tonumber(signals:GetValue(j, "row").image) then
				signals:SetValue(j, "done", true) 
				break
			end
		end		
		
		--обнуляем "переменные"
		setVal(row, 'trans_id', 0)
		setVal(row, 'signal_id', 0)
		
		
		--[[запоминаем среднюю цену входа в главной таблице. пока отключено.
		--найдем последнюю строку с этим инструментом в таблице orders
		for i = orders:GetSize(),1,-1 do
			if tostring(signal_id) == tostring(orders:GetValue(i, "signal_id").image) 
				and tostring(orders:GetValue(i, 'row').image) == tostring(row) then
				
				logstoscreen:add2(window, tonumber(orders:GetValue(i, 'row').image), nil,nil,nil,nil,'found avg_price')

				local avg_price = tonumber(orders:GetValue(i, "avg_price").image)
				
				setVal(row, 'start_price', avg_price)
				
				break
			end
		end		
		--]]
		
		
		--+------------------------------
		--|		ставим стоп лосс
		--+------------------------------
		
		--[[
			--сначала удаляем несработавший стоп лосс (если он, конечно, есть)
			kill_stop_loss(row)
			--потом ставим новый
			if factQuantity<0 then
				factQuantity=-1*factQuantity
			end
			send_stop_loss(row, factQuantity)
		--]]
	end
	
end

function send_stop_loss(row, factQuantity)
	--функция ставит стоп-лосс
	--параметры
	--	factQuantity - вх - число - этого количества нет в главной таблице, поэтому приходится передавать его явно

	local seccode 	= getVal(row, 'Ticker')
	local class 	= getVal(row, 'Class')
	local client 	= getVal(row, 'Account')
	local depo 		= getVal(row, 'Depo')
	local sig_dir 	= getVal(row, 'sig_dir')
	
	local operation = 'B'
	if sig_dir == 'buy' then
		operation 	= 'S'
	end
	
	security.class = class
	security.code = seccode
	security:Update()
	
	local stop_price = 0
	--стоп цена будет отличаться от текущей на 1%
	if sig_dir == 'buy' then
		stop_price = tonumber(security.last) - helper:round_to_step(tonumber(security.last)* 0.005,security.minStepPrice) 
	else
		stop_price = tonumber(security.last) + helper:round_to_step(tonumber(security.last)* 0.005,security.minStepPrice) 
	end
	--цена выставления заявки - еще на 1% выше/ниже стоп-цены
	local price		= 0
	if sig_dir == 'buy' then
		price = stop_price - helper:round_to_step(stop_price* 0.005,security.minStepPrice) --по этой цене будем продавать
	else
		price = stop_price + helper:round_to_step(stop_price* 0.005,security.minStepPrice) --по этой цене будем покупать
	end		
	
	--если скорость компьютера будет высока, то есть риск, что сгенерируется одинаковый транс_ид для разных строк.
	--надо найти способ генерировать заведомо уникальный. пока будем прибавлять номер строки
	local trans_id 	= helper:getMiliSeconds_trans_id()+row
	
	signal_id = nil -- нужен ли он здесь???
	helperGrid:addRowToOrders(row, trans_id, signal_id, sig_dir, factQuantity, window, 1)
	
	transactions:StopLimitWithId(seccode, class, client, depo, operation, stop_price, price, factQuantity, trans_id)
		
	setVal(row, 'stop_order_id', tostring(trans_id))
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'stop loss witn trans_id '..tostring(trans_id)..' was sent')
	
end

function wait_for_response(row)
	--ждать ответа на отправленную заявку

	--logstoscreen:add2(window, row, nil,nil,nil,nil,'we are waiting the result of sending order')

	---[[
	
	--оптимальнее будет искать заявку в таблице, начиная с конца
	for i = orders:GetSize(),1,-1 do
		
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(getVal(row, 'trans_id'))
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
				--пока позиция не изменилась относительно сохраненного перед отправкой транзакции количества - состояние робота не меняем
				
				--получим текущую позицию по бумаге
				local curPosition = trader:GetCurrentPosition(	getVal(row, 'Ticker'), 
																getVal(row, 'Account'), 
																getVal(row, 'Class'))
				--получим предыдущую позицию из главной таблицы робота
				local savedPosition = tonumber(getVal(row, 'savedPosition'))
				
				--если позиция изменилась, значит заявку обработали, хотя бы частично.
				--доделать. нужно добавить счетчик безопасного выполнения, чтобы в бесконечный цикл не уйти
				if curPosition ~= savedPosition then
					
					--переключаем состояние робота по данному инструменту - снова переходим к обработке сигнала, т.к. проверка позиции делается там
					setVal(row, 'current_state', 'processing signal')
					--текущую позицию по данным терминала поместим в главную таблицу
					setVal(row, 'savedPosition', tostring(curPosition))--хотя это можно не делать, все равно в processSignal() обновится
					
				end

				break	

			end
		end
	end
	--]]
		
end

function test_profit(row)
	--функция проверяет, на сколько изменилась цена

	local SecCodeBox	=getVal(row, 'Ticker')
	local ClassCode 	=getVal(row, 'Class')
	local dir			=getVal(row, 'sig_dir')
	local ClientBox 	=getVal(row, 'Account')
	local DepoBox 		=getVal(row, 'Depo')
	
	security.class = ClassCode
	security.code = SecCodeBox
	
	
	
	if getVal(row, 'start_price')~=nil and getVal(row, 'start_price')~='' then
	
		local start_price = tonumber(getVal(row, 'start_price'))
		
		security:Update()
		
		if dir == 'buy' then
			
			local profit = security.bid - start_price
			if profit > 0 then
			
				if profit/start_price >= 0.001 then
					--если есть 0,1% прибыли - закрываем 2 лота
					local trans_id 	= helper:getMiliSeconds_trans_id()+(row*2)
					local price = security.bid - (security.minStepPrice * 3)
					transactions:orderWithId(SecCodeBox, ClassCode, "S", ClientBox, DepoBox, tostring(price), 2, trans_id)
					logstoscreen:add2(window, row, nil,nil,nil,nil,'закрыли 2 лота из позции. отправлена транзакция ИД '..tostring(trans_id)..' с направлением SELL по цене '..tostring(price) .. ', цена инструмента была '..tostring(security.last))
					
				end
			end

		elseif dir == 'sell' then
			
			local profit = start_price - security.offer
			if profit > 0 then
			
				if profit/start_price >= 0.001 then
					--если есть 0,1% прибыли - закрываем 2 лота
					local trans_id 	= helper:getMiliSeconds_trans_id()+(row*3)
					local price = security.offer + (security.minStepPrice * 3)
					transactions:orderWithId(SecCodeBox, ClassCode, "B", ClientBox, DepoBox, tostring(price), 2, trans_id)
					logstoscreen:add2(window, row, nil,nil,nil,nil,'закрыли 2 лота из позции. отправлена транзакция ИД '..tostring(trans_id)..' с направлением BUY по цене '..tostring(price) .. ', цена инструмента была '..tostring(security.last))
					
				end
			
			end

		end
	end
end

function wait_for_signal(row)
	--ждать новые сигналы и следить за ценой.

	--нужно только так, сначала поместить сигналы в переменные, потом работать с переменными
	--это надо, чтобы работал тест сигналов - когда включается тестовый флаг, функция сигнала возвращает истину, а перед этим выключает флаг
	--т.е. более одного раза вызвать функцию сигнала в режиме теста не получится
	local signal_buy  =  signal_buy(row)
	local signal_sell =  signal_sell(row)
	
	if signal_buy == false and signal_sell == false then
		return
	end
		
	--[[если есть сигнал, нужно проверить, а может мы его уже обработали.-
		таймфрейм тут планируется 1 час, поэтому главный цикл будет видеть сигнал
		еще целый час после обработки
		local dt=strategy.PriceSeries[1].datetime--предыдущая свеча
	--]]
	--возьмем свечу из DataSource
	local dt = TableDS[row]:T(TableEMAlastCandle[row]-1)
	--и на основе этой свечи сформируем дату и время
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
		--message(sig_dir)
		
	elseif signal_sell == true	then 
		--закрытие часовика ниже средней - продажа
		if settings.invert_deals == false then
			sig_dir='sell'
		else
			sig_dir='buy'
		end
		
	end
	
	setVal(row, 'sig_dir', sig_dir)
	
	--сигнала в таблице нет, добавляем новый
	local signal_id = helper:getMiliSeconds_trans_id()
	setVal(row, 'signal_id', tostring(signal_id))
	
	helperGrid:addRowToSignals(row, trans_id, signal_id, sig_dir, window, candle_date, candle_time, TableDS[row]:C(TableEMAlastCandle[row]-1), TableEMA[row][TableEMAlastCandle[row]-1], false) 
	
	--переходим в режим обработки сигнала. функция обработки сработает на следующей итерации
	if getVal(row, 'StartStop') =='stop'  then--строка запущена в работу
		setVal(row, 'current_state', 'processing signal')
	end
	
end

function find_signal(row, candle_date, candle_time)
	--[[ищет сигнал в таблице сигналов. вызывается при поступлении нового сигнала.
	сигнал будет поступать все следующее время после формирования, согласно выбранному таймфрейму графика цены
	т.е. когда он поступил в момент формирования новой свечи, он еще будет поступать всю эту свечу.
	Есть один баг. Если робота перезапустить во время жизни свечи, на которой возник сигнал, то он опять увидит этот сигнал
	и попробует вставить в позицию. Если позиция уже была сформирована до перезапуска, то ничего страшного, 
	сработает проверка plan-fact и не позволит увеличить позу.--]]

	local rows=0
	local cols=0
	rows,cols = signals:GetSize()
	for i = rows,1,-1 do --в таких таблицах нумерация начинается с единицы
		if tonumber(signals:GetValue(i, "row").image) == row and
			signals:GetValue(i, "date").image == candle_date and
			signals:GetValue(i, "time").image == candle_time 
		then
			--уже есть сигнал, повторно обрабатывать не надо
			--logstoscreen:add2(window, row, nil,nil,nil,nil,'the signal is already processed: '..tostring(signals:GetValue(i, "id").image))
			return true
		end
	end
	return false
end

function signal_buy(row)

	--для тестов
	if getVal(row, 'test_buy') == 'true' then
		setVal(row, 'test_buy', 'false')
		return true
	end
		
	if tonumber(TableEMA[row][TableEMAlastCandle[row]-1]) ~= 0 
		and tonumber(TableEMA[row][TableEMAlastCandle[row]-2])  ~= 0 
		and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-2)) ~= 0
		and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-1)) ~= 0
		and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-2)) < tonumber(TableEMA[row][TableEMAlastCandle[row]-2]) --предпредыдущий бар ниже средней
		and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-1)) > tonumber(TableEMA[row][TableEMAlastCandle[row]-1]) --предыдущий бар выше средней
	then
		return true
	else
		return false
	end
		
end

function signal_sell(row)

	--для тестов	
	if getVal(row, 'test_sell') == 'true' then
		setVal(row, 'test_sell', 'false')
		return true
	end
	
	if tonumber(TableEMA[row][TableEMAlastCandle[row]-1]) ~= 0 
		and tonumber(TableEMA[row][TableEMAlastCandle[row]-2])  ~= 0 
		and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-2)) ~= 0
		and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-1)) ~= 0
		and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-2)) > tonumber(TableEMA[row][TableEMAlastCandle[row]-2]) --предпредыдущий бар выше средней
		and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-1)) < tonumber(TableEMA[row][TableEMAlastCandle[row]-1]) --предыдущий бар ниже средней
	then
		return true
	else
		return false
	end

end

--+-----------------------------------------------
--|			SERVICE
--+-----------------------------------------------

--обертка для получения значения из текущей строки главной таблицы
function getVal(row, colName)
	return window:GetValueByColName(row, colName).image
end

--обертка для установки значения в текущую строку главной таблицы
function setVal(row, colName, val)
	window:SetValueByColName(row, colName, val)
end