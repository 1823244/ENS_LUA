--это шаблон главного файла робота

local bit = require"bit"

--путь к классам нужно заменить на актуальный, вот эту часть
--"c:\\WORK\\lua\\ENS_LUA_Common_Classes"
--"c:\\WORK\\lua\\ENS_LUA_Strategies"

--приватная часть - последний класс, для каждого робота свой.

--common classes
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\class.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\class.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Window.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Helper.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Trader.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Transactions.lua")
--dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Security.lua") --этот класс переопределен для данного робота
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\logs.lua")

--common within one strategy
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Strategies\\StrategyOLE.lua")

--private for each robot
dofile (getScriptPath().."\\Classes\\SettingsGRID.lua")
dofile (getScriptPath().."\\Classes\\Security.lua")--этот класс переопределен для данного робота


--Это таблицы:
trader ={}
trans={}
helper={}
settings={}
strategy={}
security={}
window={}

logs={}

is_run = true	--флаг работы скрипта, пока истина - скрипт работает

working = false	--флаг активности. чтобы не закрывая окно можно быть включить/выключить робота

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

	
	
end

--это не обработчик события, а просто функция покупки
function OnBuy()
    if working  then
      trans:order(settings.SecCodeBox,settings.ClassCode,"B",settings.ClientBox,settings.DepoBox,tostring(security.last+100*security.minStepPrice),settings.LotSizeBox)
	end 
end

--это не обработчик события, а просто функция продажи
function OnSell()
	if working then
		trans:order(settings.SecCodeBox,settings.ClassCode,"S",settings.ClientBox,settings.DepoBox,tostring(security.last-100*security.minStepPrice),settings.LotSizeBox)
	end
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

	window:Close()
	is_run = false
	
end 

--Функция вызывается терминалом QUIK при при изменении текущих параметров. 
--class - строка, код класса
--sec - строка, код бумаги
function OnParam( class, sec )

	--[[
	if is_run == false or working==false then
        return
    end
	--]]
	
	--поиск инструмента
	--message(tostring(GetTableSize(window.hID)))
	for row=1, GetTableSize(window.hID) do
		
		local class = window:GetValueByColName(row, 'Class').image
		--message(class)
		local ticker = window:GetValueByColName(row, 'Ticker').image
		--message(ticker)
		if (tostring(sec) == ticker)  then
			OnParam_one_security( row, class, ticker )
		end
	end
	
end

function OnParam_one_security( row, class, sec )

	--[[
    if is_run == false or working==false then
        return
    end
	--]]
	
	time = os.date("*t")

	--это зачем?
	strategy.Second=time.sec	--секунда

	security:Update(class, sec)	--обновляет цену последней сделки в таблице security (свойство Last)

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
 
	if NumCandles~=0 then
 
		strategy.NumCandles=2
  
		--QLUA getCandlesByIndex
		--Функция предназначена для получения информации о свечках по идентификатору 
		--(заказ данных для построения графика плагин не осуществляет, поэтому для успешного доступа нужный график должен быть открыт). 
		--Формат вызова: 
		--TABLE t, NUMBER n, STRING l getCandlesByIndex (STRING tag, NUMBER line, NUMBER first_candle, NUMBER count) 
		--Параметры: 
		--tag – строковый идентификатор графика или индикатора, 
		--line – номер линии графика или индикатора. Первая линия имеет номер 0, 
		--first_candle – индекс первой свечки. Первая (самая левая) свечка имеет индекс 0, 
		--count – количество запрашиваемых свечек.
		--Возвращаемые значения: 
		--t – таблица, содержащая запрашиваемые свечки, 
		--n – количество свечек в таблице t , 
		--l – легенда (подпись) графика.
  
		--[1]функция getCandlesByIndex требует указывать, с какой по счету свечи мы получаем данные, 
		--а счет начинается с самой левой свечки. Она имеет номер 0, а самая права, текущая, 
		--соответственно N-1 – на единицу меньше количества свечек.
		
		--СУУ_ЕНС тут запрашиваем 2 предпоследних свечи. последняя не нужна, т.к. она еще не сформирована
		tPrice,n,s = getCandlesByIndex(IdPrice, 0, NumCandles-3, 2)		
		strategy:SetSeries(tPrice)

		IdMA60 = window:GetValueByColName(row, 'MA60name').image  --идентификатор графика средней скользящей
		
		--далее пошли запрашивать цены с графиков moving averages
		tPrice,n,s = getCandlesByIndex(IdMA60, 0, NumCandles-3, 2)		
		strategy.Ma1Series=tPrice

		security:Update(class, sec)		--обновляет цену последней сделки в таблице security (свойство Last)
		strategy.Position=trader:GetCurrentPosition(sec, settings.ClientBox)
		
		strategy.secCode = sec --ENS для отладки
		
		strategy.LotToTrade=tonumber(window:GetValueByColName(row, 'Lot').image)
		
		--[[
		if working==true  then
			strategy:DoBisness()
		else
			--ENS только показываем значения скользящих
			strategy:CalcLevels()
		end
		--]]
		--for debug. потом это убрать и включить условие, которео выше
		strategy:CalcLevels()
		--функция DoBisness() может отправить заявку на сервер, она отработает и изменится позиция. обновим ее
		strategy.PredPosition=strategy.Position
		
		--обновляем данные в визуальной таблице робота
		window:SetValueByColName(row, 'MA60Pred', strategy.Ma1Pred)
		window:SetValueByColName(row, 'MA60', strategy.Ma1)
		
		window:SetValueByColName(row, 'PricePred', strategy.PriceSeries[0].close)
		window:SetValueByColName(row, 'Price', strategy.PriceSeries[1].close)
		
		window:SetValueByColName(row, 'LastPrice', tostring(security.last))


	end

	
	
end

--событие, возникающее после отправки заявки на сервер
function OnTransReply(trans_reply)
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
	
	window:Init(settings.TableCaption, {'Account','Depo','Name','Ticker','Class', 'Lot', 'Position','LastPrice','BuyMarket','SellMarket','StartStop','MA60Pred','MA60','PricePred','Price','MA60name','PriceName'})
	
	
	
	--НАСТРОЙКИ ПОКА ЗАДАЮТСЯ ЗДЕСЬ!!!!
	
	--фьючерсы  (индексы, валюты, комоды)
	
	local futuresList = secListFutures() --Это двумерный массив
	
	--добавляем строки с инструментами в таблицу робота
	for row=1, #futuresList do
		--DeleteRow(self.t.t_id, row)
		local secGroup = futuresList[row][1] --код вида фьюча, например BR для брент
		
		rowNum = window:AddRow({},'')--добавляем пустую строку, затем устанавливаем значения полей
		
		window:SetValueByColName(rowNum, 'Account', '41105E5')
		window:SetValueByColName(rowNum, 'Depo', '41105E5')
		window:SetValueByColName(rowNum, 'Name', futuresList[row][1]) 
		window:SetValueByColName(rowNum, 'Ticker', futuresList[row][3]) --код бумаги
		window:SetValueByColName(rowNum, 'Class', 'SPBFUT') --класс бумаги
		window:SetValueByColName(rowNum, 'Lot', futuresList[row][4]) --размер лота для торговли
		window:SetValueByColName(rowNum, 'StartStop', 'Start')
		window:SetValueByColName(rowNum, 'BuyMarket', 'Buy')
		window:SetValueByColName(rowNum, 'SellMarket', 'Sell')
		
		window:SetValueByColName(rowNum, 'MA60name', secGroup ..'_grid_MA60')--это уже не надо, т.к. я научился вычислять среднюю скользящую сам
		window:SetValueByColName(rowNum, 'PriceName', secGroup..'_grid_price')
		
		--чтобы получить номер колонки используем функцию GetColNumberByName()
		Green(window.hID, rowNum, window:GetColNumberByName('StartStop')) 
		Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
	end  

	--фьючерсы на акции
	
	futuresList = secListFuturesOnShares() --Это двумерный массив
	
	--добавляем строки с инструментами в таблицу робота
	for row=1, #futuresList do
		--DeleteRow(self.t.t_id, row)
		local secGroup = futuresList[row][1] --код вида фьюча, например BR для брент
		
		rowNum = window:AddRow({},'')--добавляем пустую строку, затем устанавливаем значения полей
		
		window:SetValueByColName(rowNum, 'Account', '41105E5')
		window:SetValueByColName(rowNum, 'Depo', '41105E5')
		window:SetValueByColName(rowNum, 'Name', futuresList[row][1]) 
		window:SetValueByColName(rowNum, 'Ticker', futuresList[row][3]) --код бумаги
		window:SetValueByColName(rowNum, 'Class', 'SPBFUT') --класс бумаги
		window:SetValueByColName(rowNum, 'Lot', futuresList[row][4]) --размер лота для торговли
		window:SetValueByColName(rowNum, 'StartStop', 'Start')
		window:SetValueByColName(rowNum, 'BuyMarket', 'Buy')
		window:SetValueByColName(rowNum, 'SellMarket', 'Sell')
		
		window:SetValueByColName(rowNum, 'MA60name', secGroup ..'_grid_MA60')--это уже не надо, т.к. я научился вычислять среднюю скользящую сам
		window:SetValueByColName(rowNum, 'PriceName', secGroup..'_grid_price')
		
		--чтобы получить номер колонки используем функцию GetColNumberByName()
		Green(window.hID, rowNum, window:GetColNumberByName('StartStop')) 
		Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
	end  

	--валюты

	local ETSList = secListETS() --Это двумерный массив
	
	--добавляем строки с инструментами в таблицу робота
	for row=1, #ETSList do
		--DeleteRow(self.t.t_id, row)
		local secGroup = ETSList[row][1] --код вида фьюча, например BR для брент
		
		rowNum = window:AddRow({},'')--добавляем пустую строку, затем устанавливаем значения полей
		
		window:SetValueByColName(rowNum, 'Account', '41105E5')
		window:SetValueByColName(rowNum, 'Depo', '41105E5')
		window:SetValueByColName(rowNum, 'Name', ETSList[row][1]) 
		window:SetValueByColName(rowNum, 'Ticker', ETSList[row][3]) --код бумаги
		window:SetValueByColName(rowNum, 'Class', 'CETS') --класс бумаги
		window:SetValueByColName(rowNum, 'Lot', ETSList[row][4]) --размер лота для торговли
		window:SetValueByColName(rowNum, 'StartStop', 'Start')
		window:SetValueByColName(rowNum, 'BuyMarket', 'Buy')
		window:SetValueByColName(rowNum, 'SellMarket', 'Sell')
		
		window:SetValueByColName(rowNum, 'MA60name', secGroup ..'_grid_MA60')--это уже не надо, т.к. я научился вычислять среднюю скользящую сам
		window:SetValueByColName(rowNum, 'PriceName', secGroup..'_grid_price')
		
		--чтобы получить номер колонки используем функцию GetColNumberByName()
		Green(window.hID, rowNum, window:GetColNumberByName('StartStop')) 
		Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
	end  
	
	
	
	
	
	SetTableNotificationCallback (window.hID, f_cb)

	--при запуске один раз выполним OnParam, чтобы заполнить последние значения
	
	for row=1, GetTableSize(window.hID) do
		--message(settings.secList[row][1])
		local class = window:GetValueByColName(row, 'Class').image
		local ticker = window:GetValueByColName(row, 'Ticker').image
		--message(tostring(ticker))
		OnParam( class, ticker )
	end
	
	--задержка 100 миллисекунд между итерациями 
	while is_run do
		sleep(5000)
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








