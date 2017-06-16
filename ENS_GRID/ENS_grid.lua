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

--local working = false	--флаг активности. чтобы не закрывая окно можно быть включить/выключить робота

test_signal_buy = false
test_signal_sell = false

local signals = {} --таблица обработанных сигналов.	
local orders = {} --таблица заявок

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
	transactions:Init(settings.ClientBox,settings.DepoBox, settings.SecCodeBox,settings.ClassCode)
	
  	logstoscreen = LogsToScreen()
	local position = {x=300,y=10,dx=500,dy=400}
	logstoscreen:Init(position) 	
end

--это не обработчик события, а просто функция покупки
function Buy(row)
    
	local SecCodeBox = window:GetValueByColName(row, 'Ticker').image
	local ClassCode = window:GetValueByColName(row, 'Class').image
	local ClientBox = window:GetValueByColName(row, 'Account').image
	local DepoBox = window:GetValueByColName(row, 'Depo').image
	local LotSizeBox = window:GetValueByColName(row, 'Lot').image
	
	security.class = ClassCode
	security.code = SecCodeBox
	security:Update()
	
	--message(security.code)
	local minStepPrice = tonumber(window:GetValueByColName(row, 'minStepPrice').image)
    trans:order(SecCodeBox, ClassCode,"B", ClientBox, DepoBox,tostring(security.last+100*minStepPrice),LotSizeBox)
	
end

--это не обработчик события, а просто функция продажи
function Sell(row)
	
	local SecCodeBox = window:GetValueByColName(row, 'Ticker').image
	local ClassCode = window:GetValueByColName(row, 'Class').image
	local ClientBox = window:GetValueByColName(row, 'Account').image
	local DepoBox = window:GetValueByColName(row, 'Depo').image
	local LotSizeBox = window:GetValueByColName(row, 'Lot').image
	
	security.class = ClassCode
	security.code = SecCodeBox
	security:Update()
	
	--message(security.code)
	local minStepPrice = tonumber(window:GetValueByColName(row, 'minStepPrice').image)	
	trans:order(SecCodeBox,ClassCode,"S",ClientBox,DepoBox,tostring(security.last-100*security.minStepPrice),LotSizeBox)
	
end

--это не метод квика, а просто функцию так назвали!
--параметры
--	row - число, номер строки в таблице. нужен, чтобы обновить последние значения по тикеру, который запустили в работу
function OnStart(row)

	--working = true
	--window:InsertValue("Позиция",tostring(trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox)))--доделать
	
	

	--обновить значения
 	OnParam( settings.ClassCode, window:GetValueByColName(row, 'Ticker').image )
end


function OnStop(s)

	is_run = false
	window:Close()
	
end 

--Функция вызывается терминалом QUIK при при изменении текущих параметров. 
--class - строка, код класса
--sec - строка, код бумаги
function OnParam( class, sec )

	--[[
	--поиск инструмента
	--message(tostring(GetTableSize(window.hID)))
	for row=1, GetTableSize(window.hID) do
		if sec == window:GetValueByColName(row, 'Ticker').image and  class == window:GetValueByColName(row, 'Class').image  then
			OnParam_one_security( row, class, sec )
			break
		end
	end
	--]]
	
end

function OnParam_one_security( row, class, sec )

	security.class=class
	security.code=sec
	security:Update()	--обновляет цену последней сделки в таблице security (свойство Last)

	--message(tostring(security.last))
	
	window:SetValueByColName(row, 'LastPrice', tostring(security.last))

	--QLUA getNumCandles
	--Функция предназначена для получения информации о количестве свечек по выбранному идентификатору. 
	--Формат вызова: 
	--NUMBER getNumCandles (STRING tag)
	--Возвращает число – количество свечек по выбранному идентификатору. 

	--источник комментов [1] - это http://robostroy.ru/community/article.aspx?id=796
	--[1]Сначала мы получаем количество свечей. здесь: на графике цены
	
	local IdPrice = window:GetValueByColName(row, 'PriceName').image   --идентификатор графика цены выбранной бумаги (таблица)
	
	local NumCandles = getNumCandles(IdPrice)	--это общее количество свечей на графике цены. нам нужны 2 - предпредпоследняя и предпоследняя. последняя не нужна, это текущая, еще не закрытая свеча
 
	if NumCandles==0 then
		return
	end
 
	--СУУ_ЕНС тут запрашиваем 2 предпоследних свечи. последняя не нужна, т.к. она еще не сформирована
	tPrice,n,s = getCandlesByIndex(IdPrice, 0, NumCandles-3, 2)		
	strategy:SetSeries(tPrice)

	--IdMA60 = window:GetValueByColName(row, 'MA60name').image  --идентификатор графика средней скользящей
	EMA(60, IdPrice)
	--далее пошли запрашивать цены с графиков moving averages
	--tPrice,n,s = getCandlesByIndex(IdMA60, 0, NumCandles-3, 2)		
	--strategy.Ma1Series=tPrice

	--strategy.Position=trader:GetCurrentPosition(sec, settings.ClientBox)
	
	--strategy.secCode = sec --ENS для отладки
	
	strategy.LotToTrade=tonumber(window:GetValueByColName(row, 'Lot').image)
	
	
	window:SetValueByColName(row, 'PricePred', strategy.PriceSeries[0].close)
	window:SetValueByColName(row, 'Price', strategy.PriceSeries[1].close)
	
	window:SetValueByColName(row, 'LastPrice', tostring(security.last))
	
end

--событие, возникающее после отправки заявки на сервер
function OnTransReply(trans_reply)

	--logstoscreen:add('OnTransReply '..helper:getMiliSeconds())
	
	local s = orders:GetSize()
	--logstoscreen:add('size of orders = '..tostring(s))
	for i = 1, s do
		--здесь придется обойтись без строки в главном окне - row, т.к. его негде получить в контексте этой функции
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trans_reply.trans_id) then
			orders:SetValue(i, 'order', trans_reply.order_num)
			--logstoscreen:add('OnTransReply - trans_id '..tostring(orders:GetValue(i, 'trans_id').image))
			break
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
		
	
	--logstoscreen:add('onTrade '..helper:getMiliSeconds())
	
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
	
	--logstoscreen:add('onOrder '..helper:getMiliSeconds())

	
end

--f_cb – функция обратного вызова для обработки событий в таблице. вызывается из main()
--(или, другими словами, обработчик клика по таблице робота)
--параметры:
--	t_id - хэндл таблицы, полученный функцией AllocTable()
--	msg - тип события, происшедшего в таблице
--	par1 и par2 – значения параметров определяются типом сообщения msg, 
--
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
			if x["image"]=="Start" then
				Red(window.hID, par1, par2)
				SetCell(window.hID, par1, par2, 'Stop')
				OnStart(par1)
				working = true
			else
				Green(window.hID, par1, par2)
				SetCell(window.hID, par1, par2, 'Start')
				working = false
			end
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('BuyMarket') then
			--message('buy')
			Buy(par1)
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('SellMarket') then
			--message('buy')
			Sell(par1)
		end
	end


	if (msg==QTABLE_CLOSE)  then
		window:Close()
		is_run = false
		working = false
	end

	--закрытие окна робота кнопкой ESC
	if msg==QTABLE_VKEY then
		--message(par2)
		if par2 == 27 then-- esc
			window:Close()
			is_run=false
			working = false
		end
	end	

end 


function secListFutures()
  
  local secList = {} --таблица инструментов. 
  --там 4 колонки:
  --Имя инструмента, код вида фьюча, код фьюча и количество контрактов
  
  --код вида фьюча нужен для идентификации скользящей средней
  
  --раз в квартал менять код месяца
  
  --индексы
  secList[1]={'RTS','RI', 'RIU7', 2} --RTS
  secList[2]={'MICEX','MX', 'MXU7', 2} --ММВБ обычный
  secList[3]={'MCX MINI','MM', 'MMU7', 2} --ММВБ мини
  
  --валюты
  secList[4]={'SI','Si', 'SiU7',2} --USD/RUB Si
  secList[5]={'EU','Eu', 'EuU7',2} --EUR/RUB Eu
  secList[6]={'ED','ED', 'EDU7',2} --EUR/USD ED
  secList[7]={'UJPY','JP', 'JPU7',2} --USD/JPY UJPY
  secList[8]={'GBPU','GU', 'GUU7',2} --GBP/USD GBPU
  secList[9]={'AUDU','AU', 'AUU7',2} --AUD/USD AUDU
  secList[10]={'UCAD','CA', 'CAU7',2} --USD/CAD UCAD
  secList[11]={'UCHF','CF', 'CFU7',2} --USD/CHF UCHF
  secList[12]={'UTRY','TR', 'TRU7',2} --USD/TRY UTRY
  secList[13]={'UUAH','UH', 'UHU7',2} --USD/UAH UUAH гривна
  
  --комоды
  --brent надо обновлять каждый месяц
  secList[14]={'BRENT','BR', 'BRN7',2} --brent BR-4.17
  
  secList[15]={'GOLD','GD', 'GDU7',2} --gold
  secList[16]={'SILV','SV', 'SVU7',2} --silv
  secList[17]={'PLT','PT', 'PTU7',2} --plt
  secList[18]={'PLD','PD', 'PDU7',2} --pld
  
  return secList

end

function secListFuturesOnShares()
  
  local secList = {} --таблица инструментов. 
  --там 3 колонки:
  --код вида фьюча, код фьюча и количество контрактов
  
  --код вида фьюча нужен для идентификации скользящей средней
  
  --раз в квартал менять код месяца
  
  --shares futures
  secList[1]={'SBRF','SR', 'SRU7',2} --SBRF
  secList[2]={'GAZR','GZ', 'GZU7',2} --GAZR
  secList[3]={'VTBR','VB', 'VBU7',2} --VTBR
  secList[4]={'LKOH','LK', 'LKU7',2} --LKOH
  secList[5]={'ROSN','RN', 'RNU7',2} --ROSN
  secList[6]={'SBPR','SP', 'SPU7',2} --SBPR sber pref
  secList[7]={'FEES','FS', 'FSU7',2} --FEES
  secList[8]={'HYDR','HY', 'HYU7',2} --HYDR
  secList[9]={'GMKR','GM', 'GMU7',2} --GMKR
  secList[10]={'MGNT','MN', 'MNU7',2} --MGNT
  secList[11]={'SNGR','SN', 'SNU7',2} --SNGR
  secList[12]={'MOEX','ME', 'MEU7',2} --MOEX
  secList[13]={'SNGP','SG', 'SGU7',2} --SNGP
  secList[14]={'ALRS','AL', 'ALU7',2} --ALRS
  secList[15]={'NLMK','NM', 'NMU7',2} --NLMK
  secList[16]={'TATN','TT', 'TTU7',2} --TATN
  secList[17]={'MTSI','MT', 'MTU7',2} --MTSI
  secList[18]={'RTKM','RT', 'RTU7',2} --RTKM
  secList[19]={'CHMF','CH', 'CHU7',2} --CHMF --северсталь
  secList[20]={'TRNF','TN', 'TNU7',2} --TRNF
  secList[21]={'NOTK','NK', 'NKU7',2} --NOTK --новатэк
  secList[22]={'URKA','UK', 'UKU7',2} --URKA
  
  return secList
end

function secListETS()
  
  local secList = {} --таблица инструментов. 
  --там 4 колонки:
  --Имя инструмента, код вида фьюча, код инструмента и количество лотов
  
  secList[1]={'USD','USD', 'USD000UTSTOM', 2}
  
  
  return secList

end

function secListSPOT()
  
  local secList = {} --таблица инструментов. 
  --там 4 колонки:
  --Имя инструмента, код вида фьюча, код инструмента и количество лотов
  
  secList[1]={'GAZPROM','GAZP', 'GAZP', 2}
  
  
  return secList

end


--главная функция робота, которая гоняется в цикле
function main()

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
	
	window:Init(settings.TableCaption, {'current_state','Account','Depo','Name','Ticker','Class', 'Lot', 'Position','sig_dir','LastPrice','BuyMarket','SellMarket','StartStop','MA60Pred','MA60','PricePred','Price','PriceName','MA60name','minStepPrice','rejim','trans_id','signal_id'})
	
	
	
	--НАСТРОЙКИ ПОКА ЗАДАЮТСЯ ЗДЕСЬ!!!!
	
	--фьючерсы  (индексы, валюты, комоды)
	
	local List = secListFutures() --Это двумерный массив
	
	--добавляем строки с инструментами в таблицу робота
	for row=1, #List do
		--DeleteRow(self.t.t_id, row)
		local secGroup = List[row][1] --код вида фьюча, например BR для брент
		
		--rowNum = window:AddRow({},'')--добавляем пустую строку, затем устанавливаем значения полей
		rowNum = InsertRow(window.hID, -1)
		
		window:SetValueByColName(rowNum, 'Account', '41105E5')
		window:SetValueByColName(rowNum, 'Depo', '41105E5')
		window:SetValueByColName(rowNum, 'Name', List[row][1]) 
		window:SetValueByColName(rowNum, 'Ticker', List[row][3]) --код бумаги
		window:SetValueByColName(rowNum, 'Class', 'SPBFUT') --класс бумаги
		window:SetValueByColName(rowNum, 'Lot', List[row][4]) --размер лота для торговли
		window:SetValueByColName(rowNum, 'StartStop', 'Start')
		window:SetValueByColName(rowNum, 'BuyMarket', 'Buy')
		window:SetValueByColName(rowNum, 'SellMarket', 'Sell')
		
		window:SetValueByColName(rowNum, 'MA60name', secGroup ..'_grid_MA60')--это уже не надо, т.к. я научился вычислять среднюю скользящую сам
		window:SetValueByColName(rowNum, 'PriceName', secGroup..'_grid_price')
		
		--чтобы получить номер колонки используем функцию GetColNumberByName()
		Green(window.hID, rowNum, window:GetColNumberByName('StartStop')) 
		Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
		
		local minStepPrice = getParamEx('SPBFUT', List[row][3], "SEC_PRICE_STEP").param_value + 0
		window:SetValueByColName(rowNum, 'minStepPrice', tostring(minStepPrice))
		--self.STEPPRICET = getParamEx(self.class, self.code, "STEPPRICET").param_value + 0
		if minStepPrice == nil or tonumber(minStepPrice) == 0 then
			--message("Для инструмента "..List[row][3].." нет минимального шага цены в Квике. Добавьте его в таблицу инструментов", 2)
		end		
	end  

	--фьючерсы на акции
	
	List = secListFuturesOnShares() --Это двумерный массив
	
	--добавляем строки с инструментами в таблицу робота
	for row=1, #List do
		--DeleteRow(self.t.t_id, row)
		local secGroup = List[row][1] --код вида фьюча, например BR для брент
		
		--rowNum = window:AddRow({},'')--добавляем пустую строку, затем устанавливаем значения полей
		rowNum = InsertRow(window.hID, -1)
		
		window:SetValueByColName(rowNum, 'Account', '41105E5')
		window:SetValueByColName(rowNum, 'Depo', '41105E5')
		window:SetValueByColName(rowNum, 'Name', List[row][1]) 
		window:SetValueByColName(rowNum, 'Ticker', List[row][3]) --код бумаги
		window:SetValueByColName(rowNum, 'Class', 'SPBFUT') --класс бумаги
		window:SetValueByColName(rowNum, 'Lot', List[row][4]) --размер лота для торговли
		window:SetValueByColName(rowNum, 'StartStop', 'Start')
		window:SetValueByColName(rowNum, 'BuyMarket', 'Buy')
		window:SetValueByColName(rowNum, 'SellMarket', 'Sell')
		
		window:SetValueByColName(rowNum, 'MA60name', secGroup ..'_grid_MA60')--это уже не надо, т.к. я научился вычислять среднюю скользящую сам
		window:SetValueByColName(rowNum, 'PriceName', secGroup..'_grid_price')
		
		--чтобы получить номер колонки используем функцию GetColNumberByName()
		Green(window.hID, rowNum, window:GetColNumberByName('StartStop')) 
		Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
		
		local minStepPrice = getParamEx('SPBFUT', List[row][3], "SEC_PRICE_STEP").param_value + 0
		window:SetValueByColName(rowNum, 'minStepPrice', tostring(minStepPrice))
		--self.STEPPRICET = getParamEx(self.class, self.code, "STEPPRICET").param_value + 0
		if minStepPrice == nil or tonumber(minStepPrice) == 0 then
			--message("Для инструмента "..List[row][3].." нет минимального шага цены в Квике. Добавьте его в таблицу инструментов", 2)
		end		
		
	end  

	--валюты

	local List = secListETS() --Это двумерный массив
	
	--добавляем строки с инструментами в таблицу робота
	for row=1, #List do
		--DeleteRow(self.t.t_id, row)
		local secGroup = List[row][1] --код вида фьюча, например BR для брент
		
		--rowNum = window:AddRow({},'')--добавляем пустую строку, затем устанавливаем значения полей
		rowNum = InsertRow(window.hID, -1)
		
		window:SetValueByColName(rowNum, 'Account', '11267')
		window:SetValueByColName(rowNum, 'Depo', 'MB1000100002')
		window:SetValueByColName(rowNum, 'Name', List[row][1]) 
		window:SetValueByColName(rowNum, 'Ticker', List[row][3]) --код бумаги
		window:SetValueByColName(rowNum, 'Class', 'CETS') --класс бумаги
		window:SetValueByColName(rowNum, 'Lot', List[row][4]) --размер лота для торговли
		window:SetValueByColName(rowNum, 'StartStop', 'Start')
		window:SetValueByColName(rowNum, 'BuyMarket', 'Buy')
		window:SetValueByColName(rowNum, 'SellMarket', 'Sell')
		
		window:SetValueByColName(rowNum, 'MA60name', secGroup ..'_grid_MA60')--это уже не надо, т.к. я научился вычислять среднюю скользящую сам
		window:SetValueByColName(rowNum, 'PriceName', secGroup..'_grid_price')
		
		--чтобы получить номер колонки используем функцию GetColNumberByName()
		Green(window.hID, rowNum, window:GetColNumberByName('StartStop')) 
		Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
		
		local minStepPrice = getParamEx('CETS', List[row][3], "SEC_PRICE_STEP").param_value + 0
		window:SetValueByColName(rowNum, 'minStepPrice', tostring(minStepPrice))
		--self.STEPPRICET = getParamEx(self.class, self.code, "STEPPRICET").param_value + 0
		if minStepPrice == nil or tonumber(minStepPrice) == 0 then
			--message("Для инструмента "..List[row][3].." нет минимального шага цены в Квике. Добавьте его в таблицу инструментов", 2)
		end		
		
	end  
	
	--спот

	local List = secListSPOT() --Это двумерный массив
	
	--добавляем строки с инструментами в таблицу робота
	for row=1, #List do
		--DeleteRow(self.t.t_id, row)
		local secGroup = List[row][1] --код вида фьюча, например BR для брент
		
		--rowNum = window:AddRow({},'')--добавляем пустую строку, затем устанавливаем значения полей
		rowNum = InsertRow(window.hID, -1)
		
		window:SetValueByColName(rowNum, 'Account', '11267')
		window:SetValueByColName(rowNum, 'Depo', 'NL0011100043')
		window:SetValueByColName(rowNum, 'Name', List[row][1]) 
		window:SetValueByColName(rowNum, 'Ticker', List[row][3]) --код бумаги
		window:SetValueByColName(rowNum, 'Class', 'QJSIM') --класс бумаги
		window:SetValueByColName(rowNum, 'Lot', List[row][4]) --размер лота для торговли
		window:SetValueByColName(rowNum, 'StartStop', 'Start')
		window:SetValueByColName(rowNum, 'BuyMarket', 'Buy')
		window:SetValueByColName(rowNum, 'SellMarket', 'Sell')
		
		window:SetValueByColName(rowNum, 'MA60name', secGroup ..'_grid_MA60')--это уже не надо, т.к. я научился вычислять среднюю скользящую сам
		window:SetValueByColName(rowNum, 'PriceName', secGroup..'_grid_price')
		
		--чтобы получить номер колонки используем функцию GetColNumberByName()
		Green(window.hID, rowNum, window:GetColNumberByName('StartStop')) 
		Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
		
		local minStepPrice = getParamEx('QJSIM', List[row][3], "SEC_PRICE_STEP").param_value + 0
		window:SetValueByColName(rowNum, 'minStepPrice', tostring(minStepPrice))
		--self.STEPPRICET = getParamEx(self.class, self.code, "STEPPRICET").param_value + 0
		if minStepPrice == nil or tonumber(minStepPrice) == 0 then
			--message("Для инструмента "..List[row][3].." нет минимального шага цены в Квике. Добавьте его в таблицу инструментов", 2)
		end		
		
	end  
	
	
	
	SetTableNotificationCallback (window.hID, f_cb)

	--при запуске один раз выполним OnParam, чтобы заполнить последние значения
	
	for row=1, GetTableSize(window.hID) do
		OnParam( window:GetValueByColName(row, 'Class').image, window:GetValueByColName(row, 'Ticker').image )
	end
	
	
---------------------------------------------------------------------------	
	if createTableSignals() == false then
		return
	end

	SetWindowPos(signals.t_id, 810, 10, 600, 200)

---------------------------------------------------------------------------	
	if createTableOrders() == false then
		return
	end	
	
	--задержка 100 миллисекунд между итерациями 
	while is_run do
	
		for row=1, GetTableSize(window.hID) do
			main_loop(row, window:GetValueByColName(row, 'Ticker').image, window:GetValueByColName(row, 'Class').image)
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

	signals:AddColumn("row", QTABLE_INT_TYPE, 5) --номер строки в главной таблице. внешний ключ!!!
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
	
	orders:AddColumn("row", QTABLE_INT_TYPE, 5) --номер строки в главной таблице. внешний ключ!!!
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


--+-----------------------------------------------
--|			ОСНОВНОЙ АЛГОРИТМ
--+-----------------------------------------------

--эта функция должна вызываться из обрамляющего цикла в функции main()
function main_loop(row, sec, class)

	if isConnected() == 0 then
		--window:InsertValue("Сигнал", "Not connected")
		return
	end
	
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
	
	--EMA(60, IdPriceCombo)--рассчитываем среднюю скользящую (экспоненциальную)

	
	
	local acc = window:GetValueByColName(row, 'Account').image
	local currency_CETS='USD'
	--обновляем данные в визуальной таблице робота
	
	window:SetValueByColName(row, 'Position', tostring(trader:GetCurrentPosition(sec, acc, class, currency_CETS)))
	
	--window:SetValueByColName(row, 'MA60Pred', tostring(EMA_TMP[#EMA_TMP-2]))
	--window:SetValueByColName(row, 'MA60', tostring(EMA_TMP[#EMA_TMP-1]))

	window:SetValueByColName(row, 'MA60Pred', tostring(strategy.Ma1Pred))
	window:SetValueByColName(row, 'MA60', tostring(strategy.Ma1))
	
	window:SetValueByColName(row, 'PricePred', strategy.PriceSeries[0].close)
	window:SetValueByColName(row, 'Price', strategy.PriceSeries[1].close)
	
	local working = window:GetValueByColName(row, 'StartStop').image 
	
	if working=='Start'  then --инструмент выключен. когда включен, там будет Stop
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
	
	--logstoscreen:add('processing signal: '..signal_direction)
	
	--нужно посмотреть, на сколько лотов/контрактов нужно открыть позицию - это в настройках каждой строки с инструментом
	
	local planQuantity = tonumber(window:GetValueByColName(row, 'Lot').image)
	local signal_direction = window:GetValueByColName(row, 'sig_dir').image
	if signal_direction == 'sell' then
		planQuantity = -1*planQuantity --сделаем отрицательным
	end
	--logstoscreen:add('plan quantity: ' .. tostring(planQuantity))
	
	--посмотреть, сколько уже лотов/контрактов есть в позиции (валюту для СЭЛТ пока оставим пустой, главное - сделать базовый функционал)
	local factQuantity = trader:GetCurrentPosition(window:GetValueByColName(row, 'Ticker').image, window:GetValueByColName(row, 'Account').image, window:GetValueByColName(row, 'Class').image)
	--logstoscreen:add('fact quantity: ' .. tostring(factQuantity))
	
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
			--logstoscreen:add('ОШИБКА! qty = 0')
			--переходим к ожиданию нового сигнала
			 
			window:SetValueByColName(row, 'current_state', 'waiting for a signal')
			return
		end
		
		--logstoscreen:add('qty: ' .. tostring(qty))
		
		if signal_direction == 'sell' then --приведем к положительному
			qty = -1*qty
		end
		
		
		--!!!!!!!!!!!!для отладки. хочу проверить как будет отрабатывать ожидание добора позиции 
		--qty = 5
		
		
		
		local newR = orders:AddLine()
		orders:SetValue(newR, "row", row)
		orders:SetValue(newR, "trans_id", trans_id)
		orders:SetValue(newR, "signal_id", signal_id)
		orders:SetValue(newR, "qty", qty)
		
		if signal_direction == 'buy' then
			Buy(qty, trans_id)
		elseif signal_direction == 'sell' then
			Sell(qty, trans_id)
		end
		
		--включаем флаг, признак того, что робот ждет ответа на выставленную заявку
		--флаг выключится в функции OnTrade()
		--we_are_waiting_result = true
		window:SetValueByColName(row, 'current_state', 'waiting for a response')

	else
		--logstoscreen:add('вся позиция уже набрана, заявка не отправлена!')
		
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
	--logstoscreen:add('we are waiting the result of sending order')

	local s = orders:GetSize()
	for i = 1, s do
		
		local trans_id = window:GetValueByColName(row, 'trans_id').image
		
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trans_id)
			and tonumber(orders:GetValue(i, 'row').image) == row then
			
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
					
					--logstoscreen:add('order '..orders:GetValue(i, 'order').image..': qty = qty_fact - order is processed')
					
				end
				
				--logstoscreen:add('order '..orders:GetValue(i, 'order').image..' processed')
				
				window:SetValueByColName(row, 'current_state', 'processing signal')
				
			
			end
		end
	end
		
end

--ждать новые сигналы
function wait_for_signal(row)

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
	if find_signal(row, candle_date, candle_time) == true then
		return
	end
		
	--logstoscreen:add('we have got a signal: ')
	
	local sig_dir = nil
	if signal_buy == true then 
		--закрытие свечи выше средней - покупка
		sig_dir='buy'
		
	elseif signal_sell == true	then 
		--закрытие часовика ниже средней - продажа
		sig_dir='sell'
		
	end
	
	window:SetValueByColName(row, 'sig_dir', sig_dir)
	
	--сигнала в таблице нет, добавляем новый
	local signal_id = helper:getMiliSeconds_trans_id()
	window:SetValueByColName(row, 'signal_id', tostring(signal_id))
	
	local newR = signals:AddLine()
	signals:SetValue(newR, "row", row)
	signals:SetValue(newR, "id", 	signal_id)
	signals:SetValue(newR, "dir", 	sig_dir)
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
т.е. когда он поступил в момент формирования новой свечи, он еще будет поступать всю следующую свечу--]]
function find_signal(row, candle_date, candle_time)
	local rows=0
	local cols=0
	rows,cols = signals:GetSize()
	for i = 1 , rows do --в таких таблицах нумерация начинается с единицы
		if tonumber(signals:GetValue(i, "row").image) == row and
			signals:GetValue(i, "date").image == candle_date and
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


function signal_buy()

--  Ma1 = Ma1Series[1].close						--предыдущая свеча
--  Ma1Pred = Ma1Series[0].close 	--ENS		--предпредыдущая свеча

	--для тестов
	if working == true then
		if test_signal_buy == true then
			test_signal_buy = false
			return true
		end
	else
		return false
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

function signal_sell()

--  Ma1 = Ma1Series[1].close						--предыдущая свеча
--  Ma1Pred = Ma1Series[0].close 	--ENS		--предпредыдущая свеча


	--для тестов
	if working == true then
		if test_signal_sell == true then
			test_signal_sell = false
			return true
		end
	else
		return false
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

