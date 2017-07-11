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
--setVal(row, 'LastPrice', tostring(security.last))
--получение значения из ячейки
-- local acc = getVal(row, 'Account')
--запись в лог
--logstoscreen:add2(window, row, nil,nil,nil,nil,'message to log')

local sqlite3 = require("lsqlite3")


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

--Это таблицы:
trader ={}
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

--для более простого включения инструмента в работу будем рассчитывать среднюю скользящую сами
local EMA_Array = {}--массив рассчитанных свечений индикатора средняя скользящая для одного инструмента
local TableEMA = {} --таблица с массивам средних скользящих для всех инструментов
local TableEMAlastCandle = {} -- таблица с последней рассчитанной свечой по ЕМА. чтобы каждый раз с начала не считать

local TableDS= {} --датасурсы для всех инструментов
local ErrorDS= {}

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

--это не обработчик события, а просто функция покупки/продажи
--Parameters:
--	row - int - number of row in main table
--	direction - string - deal direction. for case when function uses outside of main algorithm. values: 'buy', 'sell'
function buySell(row, direction)

	local SecCodeBox	= getVal(row, 'Ticker')
	local ClassCode 	= window:GetValueByColName(row, 'Class').image
	local ClientBox 	= window:GetValueByColName(row, 'Account').image
	local DepoBox 		= window:GetValueByColName(row, 'Depo').image
	--идентификатор транзакции нужен обязательно, чтобы потом можно было понять, на какую транзакцию пришел ответ
	local trans_id 		= tonumber(window:GetValueByColName(row, 'trans_id').image)
	
	--если передано направление - используем его
	local dir = ''
	if direction ~= nil then
		dir = direction
	else
		dir 			= getVal(row, 'sig_dir')
	end

	--количество для заявки берем из "переменной" - поля qty в главной таблице в строке из параметра row
	local qty 			= tonumber(window:GetValueByColName(row, 'qty').image)
	
	--получаем цену последней сделки, чтобы обладать актуальной информацией
	security.class = ClassCode
	security.code = SecCodeBox
	security:Update()
	
	--local minStepPrice = tonumber(window:GetValueByColName(row, 'minStepPrice').image)

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



--колбэк
function OnStop(s)

	stopScript()
	
end 

--закрывает окна и выключает флаг работы скрипта
function stopScript()

	is_run = false
	window:Close()
	
	logstoscreen:CloseTable()
	DestroyTable(signals.t_id)
	DestroyTable(orders.t_id)

	
end

--рефакторинг. запуск в работу одного инструмента
function startStopRow(row)

	if window:GetValueByColName(row, 'StartStop').image == 'start' then
		helperGrid:Red(window.hID, row, window:GetColNumberByName('StartStop'))

		setVal(row, 'StartStop', 'stop')
		setVal(row, 'current_state', 'waiting for a signal')
		logstoscreen:add2(window, row, nil,nil,nil,nil,'StartStopRow() инструмент запущен в работу')
	else
		helperGrid:Green(window.hID, row, window:GetColNumberByName('StartStop'))
		setVal(row, 'StartStop', 'start')
		setVal(row, 'current_state', 'stopped')
		logstoscreen:add2(window, row, nil,nil,nil,nil,'StartStopRow() инструмент остановлен')
		setVal(row, 'LastPrice', tostring(0))
	end
end


--событие, возникающее после отправки заявки на сервер
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
	par1 и par2 – значения параметров определяются типом сообщения msg, 
--]]
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
		
		setVal(rowNum, 'Account', 	List[row][7])
		setVal(rowNum, 'Depo', 		List[row][8])
		setVal(rowNum, 'Name', 		List[row][1]) 
		setVal(rowNum, 'Ticker', 		List[row][3]) --код бумаги
		setVal(rowNum, 'Class', 		List[row][6]) --класс бумаги
		setVal(rowNum, 'Lot', 		List[row][4]) --размер лота для торговли
		--здесь наоборот надо, если в настройках start, то нужно запустить робота, а в поле StartStop поместить действие stop
		setVal(rowNum, 'StartStop', 	List[row][9])
		--[[
		if List[row][9] == 'start' then
			setVal(rowNum, 'StartStop', 'stop')
		else
			setVal(rowNum, 'StartStop', 'start')
		end
		--]]
		setVal(rowNum, 'BuyMarket', 'Buy')
		setVal(rowNum, 'SellMarket', 'Sell')
		
		--setVal(rowNum, 'MA60name',  	List[row][1] ..'_grid_MA60')
		--setVal(rowNum, 'PriceName', 	List[row][1]..'_grid_price')
		
		setVal(rowNum, 'rejim', 		List[row][5])
		
		--чтобы получить номер колонки используем функцию GetColNumberByName()
		
		helperGrid:Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		helperGrid:Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
		
		local minStepPrice = getParamEx(List[row][6], 	List[row][3], "SEC_PRICE_STEP").param_value + 0
		setVal(rowNum, 'minStepPrice', tostring(minStepPrice))
		
		
	end  

end




  


--главная функция робота, которая гоняется в цикле
function main()

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
	--stop_order_id - пользовательский ИД для стоп-лосса
	--start_price - цена по которой вошли в сделку. следим за прибылью и потихоньку уменьшаем позицию, если прибыль растет
	local t = {'current_state','Account','Depo','Name','Ticker','Class', 'Lot', 'Position','sig_dir','LastPrice','BuyMarket','SellMarket','StartStop','MA60Pred','MA60','PricePred','Price','PriceName','MA60name','minStepPrice','rejim','trans_id','signal_id','test_buy','test_sell','qty','savedPosition', 'stop_order_id', 'start_price'}
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
		
		--для самостоятельного расчета средней будем использовать datasource
		local class_code =  window:GetValueByColName(row, 'Class').image
		local sec_code =  window:GetValueByColName(row, 'Ticker').image
		
		--datasource создаем в глобальной таблице
		TableDS[row], ErrorDS[row] = CreateDataSource (class_code, sec_code, INTERVAL_M1) --индексы начинаются с единицы

		if TableDS[row] == nil then
			logstoscreen:add2(window, row, nil,nil,nil,nil,'error when setting creating DataSource: '..ErrorDS[row])
			--выключаем инструмент, по которому пришла ошибка

			setVal(row, 'StartStop', 'stop')--turn off
			startStopRow(row)
			logstoscreen:add2(window, row, nil,nil,nil,nil,  'instrument was turned off due to error creating datasource')
			
		else
		
			--установим колбэк на обновление свечек. пока пустой
			local res= TableDS[row]:SetEmptyCallback()
			if res == false then
				logstoscreen:add2(window, row, nil,nil,nil,nil,'error when setting empty callback '..sec_code)
			end
			
			--нужно подождать, пока загрузятся свечки
			local safecount = 1
			
			while TableDS[row]:Size() == 0 do
				--logstoscreen:add2(window, row, nil,nil,nil,nil,'size of data source: '..tostring(TableDS[row]:Size()))
				sleep(50)
				safecount = safecount + 1
				if safecount > 100 then
					logstoscreen:add2(window, row, nil,nil,nil,nil,'не дождались обновления рекордсета по инструменту '..sec_code)
					break
				end
			end
			logstoscreen:add2(window, row, nil,nil,nil,nil,'size of data source: '..tostring(TableDS[row]:Size()))
		
		end
		
		--сразу посчитаем среднюю
		
		TableEMAlastCandle[row] = 0 --таблица, в которой лежат номера последних рассчитанных свечей индикатора EMA. хотя наверное можно отказаться, брать по размеру таблицы
		
		TableEMA[row]={} --таблица индикатор EMA. 
		
		TableEMA[row], TableEMAlastCandle[row] = EMAclass:emaDS(TableEMA[row], TableDS[row], 60, TableEMAlastCandle[row])
		
		--logstoscreen:add2(window, row, nil,nil,nil,nil,'last of EMA array: '..tostring(TableEMA[row][TableEMAlastCandle[row]]))
		
	end
	
	
	--главный цикл
	while is_run do
	
		for row=1, GetTableSize(window.hID) do
			main_loop(row)
		end
		
		sleep(500)
	end

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
	
	---[[
	
	--еще одна проверка по мотивам http://www.kamynin.ru/2015/02/11/lua-proverka-podklyucheniya-k-serveru-quik/
	--если в программе надо проверить подключение, то это лучше делать так:
	if getInfoParam('SERVERTIME')=='' then
		-- подключения нет
		return false
	else
		--есть подключение
	end
	--]]
  
	---[[ проверка попадания в торговое окно
	local serv_time=tonumber(helperGrid:timeformat(getInfoParam("SERVERTIME"))) -- помещение в переменную времени сервера в формате HHMMSS
	--logstoscreen:add2(window, row, nil,nil,nil,nil,'server time '..tostring(serv_time))
	--первые 5 минут не торгуем
	if not (serv_time>=100500 and serv_time<235000) then
		return false
	end 	
	--]]

		

	--рассчитать среднюю самостоятельно
	
	TableEMA[row], TableEMAlastCandle[row] = EMAclass:emaDS(TableEMA[row], TableDS[row], 60, TableEMAlastCandle[row])

	setVal(row, 'PricePred', tostring(TableDS[row]:C(TableEMAlastCandle[row]-2)))
	setVal(row, 'Price',     tostring(TableDS[row]:C(TableEMAlastCandle[row]-1)))
	
	setVal(row, 'MA60Pred', tostring(TableEMA[row][TableEMAlastCandle[row]-2]))
	setVal(row, 'MA60',     tostring(TableEMA[row][TableEMAlastCandle[row]-1]))	

	

	--если строка выключена то можно проверить это здесь, а можно чуть дальше, чтобы сигналы все же показывались
	--[[
	if window:GetValueByColName(row, 'StartStop').image =='start'  then --инструмент выключен. когда включен, там будет Stop
		return
	end		
	--]]	
	-------------------------------------------------------------------
	--			ОСНОВНОЙ АЛГОРИТМ
	-------------------------------------------------------------------
	local current_state = window:GetValueByColName(row, 'current_state').image
	
	if current_state == 'waiting for a signal' then
		--ожидаем новые сигналы 
		wait_for_signal(row)
		
	elseif current_state == 'processing signal' then
		--в этом состоянии робот шлет заявки на сервер, пока не наберет позицию или не кончится время или количество попыток
		if window:GetValueByColName(row, 'StartStop').image =='stop'  then--строка запущена в работу
			processSignal(row)
		end		
		
	elseif current_state == 'waiting for a response' then
		--заявку отправили, ждем пока придет ответ, перед отправкой новой
		if window:GetValueByColName(row, 'StartStop').image =='stop'  then--строка запущена в работу
			wait_for_response(row)
		end
	end

end

--[[ тренировка. расчет средней по статье http://bot4sale.ru/blog-menu/qlua/spisok-statej/487-coffee.html

из-за рекурсии вылетает в ошибку stack overflow

ma =
{
    -- Exponential Moving Average (EMA)
    -- EMA[i] = (EMA[i]-1*(per-1)+2*X[i]) / (per+1)
    -- Параметры:
    -- period - Период скользящей средней
    -- get - функция с одним параметром (номер в выборке), возвращающая значение выборки
    -- Возвращает массив, при обращению к которому будет рассчитываться только необходимый элемент
    -- При повторном обращении будет возвращено уже рассчитанное значение
	-- РЕКУРСИЯ!!!
    ema =
        function(period,get) 
            return setmetatable( 
                        {},
                        { __index = function(tbl,indx)
                                              if indx == 1 then
                                                  tbl[indx] = get(1)
                                              else
                                                  tbl[indx] = (tbl[indx-1] * (period-1) + 2 * get(indx)) / (period + 1)
                                              end
                                              return tbl[indx]
                                            end
                        })
       end
}
--]]

--обработать сигнал: сравнить текущую позицию с плановой, добрать количество до планового, если текущее меньше.
function processSignal(row)
	
	--нужно посмотреть, на сколько лотов/контрактов нужно открыть позицию - это в настройках каждой строки с инструментом
	
	local planQuantity = tonumber(getVal(row, 'Lot'))
	
	local signal_direction = getVal(row, 'sig_dir')
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'processing signal: '..signal_direction)
	
	if signal_direction == 'sell' then
		planQuantity = -1*planQuantity --сделаем отрицательным
	end
	
	
	
	--посмотреть, сколько уже лотов/контрактов есть в позиции (валюту для СЭЛТ пока оставим пустой, главное - сделать базовый функционал)
	local factQuantity = trader:GetCurrentPosition(getVal(row, 'Ticker'), 
													getVal(row, 'Account'),
													getVal(row, 'Class'))
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'fact quantity: ' .. tostring(factQuantity))
	
	local rejim = getVal(row, 'rejim')

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
		
		logstoscreen:add2(window, row, nil,nil,nil,nil,'qty: ' .. tostring(qty))
		
		
		--!!!!!!!!!!!!для отладки. хочу проверить как будет отрабатывать ожидание добора позиции 
		--qty = 5
		
		
		setVal(row, 'qty', tostring(qty))
		
		--для визуального контроля пишем информацию о заявке во вспомогательную таблицу. там же идет запись в sqlite		
		helperGrid:addRowToOrders(row, trans_id, signal_id, signal_direction, qty, window, 0) 
		
		--сохраним "старую" позицию
		setVal(row, 'savedPosition', tostring(factQuantity))
		
		--универсальная функция покупки/продажи. направление и количество она возьмет из строки "row"
		buySell(row)
		
		--после отправки транзакции на биржу меняем состояние робота на то, в котором он ждет ответа на выставленную заявку - 'waiting for a signal'
		--здесь может сложиться ситуация, когда buySell() будет исполняться долго, а в ответ ей придет,
		--что заявка не может быть исполнена. в этом случае OnTransReply() поставит состояние 'stopped',
		--а здесь мы должны проверить, установлено оно или нет, чтобы не поменять на 'waiting for a response',т.к. это ошибка.
		if getVal(row, 'current_state') ~= 'stopped' then
			setVal(row, 'current_state', 'waiting for a response')
		end

	else
		--позиция набрана
		--logstoscreen:add2(window, row, nil,nil,nil,nil,'вся позиция уже набрана, заявка не отправлена!')
		
		setVal(row, 'current_state', 'waiting for a signal')
		
		--обновим состояние сигнала в таблице сигналов
		local rows=0
		local cols=0
		rows,cols = signals:GetSize()
		for j = rows, 1, -1 do --в таких таблицах нумерация начинается с единицы
			if tostring(signal_id) == tostring(signals:GetValue(j, "id").image) 
				and row == tonumber(signals:GetValue(j, "row").image) then
			
				signals:SetValue(j, "done", true) 
				break
			end
		end		
		
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

--функция ставит стоп-лосс
--параметры
--	factQuantity - вх - число - этого количества нет в главной таблице, поэтому приходится передавать его явно
function send_stop_loss(row, factQuantity)

	local seccode 	= window:GetValueByColName(row, 'Ticker').image
	local class 	= window:GetValueByColName(row, 'Class').image
	local client 	= window:GetValueByColName(row, 'Account').image
	local depo 		= window:GetValueByColName(row, 'Depo').image
	local sig_dir 	= window:GetValueByColName(row, 'sig_dir').image
	
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

--функция убирает стоп-лосс
function kill_stop_loss(row)

	--получаем id стоп_лосса из главной таблицы
	local stop_id = getVal(row, 'stop_order_id')
	if stop_id == nil or stop_id == 'nil' or stop_id == '' or stop_id == ' ' or stop_id == 0 then
		return
	end	
	
	--сначала нужно найти номер стоп-лосса в таблице stop_orders по id
	local s = orders:GetSize()
	local rowNum=nil
	local number = nil
	for i = s, 1, -1 do
		--здесь придется обойтись без строки в главной таблице - row, т.к. в контексте этой функции невозможно понять, по какой строке пришел колбэк
		--но это не будет проблемой, т.к. trans_id вполне однозначно определяет по какому инструменту ждем ответ
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(stop_id) then
			rowNum=tonumber(orders:GetValue(i, 'row').image)
			number=tonumber(orders:GetValue(i, 'order').image)
			break
		end
	end		

	if number~=nil then
		
		transactions:killStopOrder(number, 
									getVal(row, 'Ticker'), 
									getVal(row, 'Class'),
									stop_id)
		
		setVal(row, 'stop_order_id', ' ')--заметаем следы
		
		logstoscreen:add2(window, row, nil,nil,nil,nil,'stop loss '..tostring(stop_id)..' was killed')
	end
	
end

--ждать ответа на отправленную заявку
function wait_for_response(row)
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

--функция проверяет, на сколько изменилась цена
function test_profit(row)


	local SecCodeBox	= window:GetValueByColName(row, 'Ticker').image
	local ClassCode 	= window:GetValueByColName(row, 'Class').image
	local dir			= window:GetValueByColName(row, 'sig_dir').image
	local ClientBox 	= window:GetValueByColName(row, 'Account').image
	local DepoBox 		= window:GetValueByColName(row, 'Depo').image
	
	security.class = ClassCode
	security.code = SecCodeBox
	
	
	
	if window:GetValueByColName(row, 'start_price').image~=nil and window:GetValueByColName(row, 'start_price').image~='' then
	
		local start_price = tonumber(window:GetValueByColName(row, 'start_price').image)
		
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

--ждать новые сигналы и следить за ценой.
function wait_for_signal(row)


	--сначала посчитаем прибыль.
	--если она есть, то частично закрываем позицию
	
	test_profit(row)
	

	
	--потом проверим сигнал

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
	--local dt=strategy.PriceSeries[1].datetime--предыдущая свеча
	local dt = TableDS[row]:T(TableEMAlastCandle[row]-1)
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
	if window:GetValueByColName(row, 'StartStop').image =='stop'  then--строка запущена в работу
		setVal(row, 'current_state', 'processing signal')
	end
	
end

--[[	ищет сигнал в таблице сигналов. вызывается при поступлении нового сигнала.
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

--для варианта с функцией getCandlesByIndex()
function signal_buy_old(row)

--  Ma1 = Ma1Series[1].close						--предыдущая свеча
--  Ma1Pred = Ma1Series[0].close 	--ENS		--предпредыдущая свеча

	--для тестов
    
	if window:GetValueByColName(row, 'test_buy').image == 'true' then
		setVal(row, 'test_buy', 'false')
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
	if EMA_Array[#EMA_Array-1]  ~= 0 		--предыдущая свеча
	and EMA_Array[#EMA_Array-2]  ~= 0 		--предпредыдущая свеча
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
	and strategy.PriceSeries[0].close < EMA_Array[#EMA_Array-2] --предпредыдущий бар ниже средней
	and strategy.PriceSeries[1].close > EMA_Array[#EMA_Array-1] --предыдущий бар выше средней
	then
		return true
	else
		return false
	end
--]]	
end

--для варианта с функцией getCandlesByIndex()
function signal_sell_old(row)

--  Ma1 = Ma1Series[1].close						--предыдущая свеча
--  Ma1Pred = Ma1Series[0].close 	--ENS		--предпредыдущая свеча


	--для тестов
	
	if window:GetValueByColName(row, 'test_sell').image == 'true' then
		setVal(row, 'test_sell', 'false')
		return true
	end
	
	if strategy.Ma1 ~= 0 
	and strategy.Ma1Pred  ~= 0 
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
--	and strategy.PriceSeries[0].close > EMA_Array[#EMA_Array-2] --предпредыдущий бар выше средней
--	and strategy.PriceSeries[1].close < EMA_Array[#EMA_Array-1] --предыдущий бар ниже средней
	and strategy.PriceSeries[0].close > strategy.Ma1Pred --предпредыдущий бар выше средней
	and strategy.PriceSeries[1].close < strategy.Ma1 --предыдущий бар ниже средней
	then
		return true
	else
		return false
	end

end



function signal_buy(row)

	--для тестов
    
	if window:GetValueByColName(row, 'test_buy').image == 'true' then
		setVal(row, 'test_buy', 'false')
		return true
	end
		
	---[[
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
	--]]	
		
end

function signal_sell(row)

	--для тестов
	
	if window:GetValueByColName(row, 'test_sell').image == 'true' then
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

--обертка для получения значения из текущей строки главной таблицы
function getVal(row, colName)
	return window:GetValueByColName(row, colName).image
end

function setVal(row, colName, val)
	window:SetValueByColName(row, colName, val)
end