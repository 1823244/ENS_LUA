--это шаблон главного файла робота

local bit = require"bit"

--путь к классам нужно заменить на актуальный, вот эту часть
--"c:\\WORK\\lua\\ENS_LUA_Common_Classes"
--"c:\\WORK\\lua\\ENS_LUA_Strategies"

--приватная часть - последний класс, для каждого робота свой.

--common classes
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\class.lua")
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\Window.lua")
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\Helper.lua")
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\Trader.lua")
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\Transactions.lua")
--dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\Security.lua") --этот класс переопределен для данного робота
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\logs.lua")

--common within one strategy
dofile ("z:\\WORK\\lua\\ENS_LUA_Strategies\\StrategyOLE.lua")

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
	
	--зачем это? для трейлинга?
	trans:CalcDateForStop()	--формирует строку ггммдд и возвращает ее в свойстве dateForStop таблицы trans
	
	for row=1, #settings.secList do
		if (tostring(sec) == settings.secList[row][1])  then
			OnParam_one_security( row, class, sec )
		end
    end

end

function OnParam_one_security( row, class, sec )

	--[[
    if is_run == false or working==false then
        return
    end
	--]]
	
	--зачем это? для трейлинга?
	trans:CalcDateForStop()	--формирует строку ггммдд и возвращает ее в свойстве dateForStop таблицы trans

	time = os.date("*t")

	--это зачем?
	strategy.Second=time.sec	--секунда

	security:Update(class, sec)	--обновляет цену последней сделки в таблице security (свойство Last)

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
	
	window:Init(settings.TableCaption, {'Account','Ticker', 'Lot', 'Position','LastPrice','BuyMarket','SellMarket','StartStop','MA60Pred','MA60','PricePred','Price','MA60name','PriceName'})
	
	
	
	--message(window.columns[1] )
	
	--добавляем строки с инструментами в таблицу робота
	for row=1, #settings.secList do
		--DeleteRow(self.t.t_id, row)
		local secGroup = settings.secList[row][1] --код вида фьюча, например BR для брент
		local sec = settings.secList[row][2]
		local lot = settings.secList[row][3]
		
		window:AddRow({},'')--добавляем пустую строку, затем устанавливаем значения полей
		
		window:SetValueByColName(row, 'Account', settings.ClientBox)
		window:SetValueByColName(row, 'Ticker', sec) --код бумаги
		window:SetValueByColName(row, 'Lot', lot) --размер лота для торговли
		window:SetValueByColName(row, 'StartStop', 'Start')
		window:SetValueByColName(row, 'BuyMarket', 'Buy')
		window:SetValueByColName(row, 'SellMarket', 'Sell')
		
		window:SetValueByColName(row, 'MA60name', secGroup ..'_grid_MA60')
		window:SetValueByColName(row, 'PriceName', secGroup..'_grid_price')
		
		--чтобы получить номер колонки используем функцию GetColNumberByName()
		Green(window.hID, row, window:GetColNumberByName('StartStop')) 
		Green(window.hID, row, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, row, window:GetColNumberByName('SellMarket')) 
	end  


	--QLUA SetTableNotificationCallback
	--Задание функции обратного вызова для обработки событий в таблице. 
	--Формат вызова: 
	--NUMBER SetTableNotificationCallback (NUMBER t_id, FUNCTION f_cb)
	--Параметры: 
	--t_id – идентификатор таблицы, 
	--f_cb – функция обратного вызова для обработки событий в таблице.
	--В случае успешного завершения функция возвращает «1», иначе – «0». 
	--Формат вызова функции обратного вызова для обработки событий в таблице: 
	--f_cb = FUNCTION (NUMBER t_id, NUMBER msg, NUMBER par1, NUMBER par2)
	--Параметры: 
	--t_id – идентификатор таблицы, для которой обрабатывается сообщение, 
	--par1 и par2 – значения параметров определяются типом сообщения msg, 
	--msg – код сообщения.
	
	SetTableNotificationCallback (window.hID, f_cb)

	--при запуске один раз выполним OnParam, чтобы заполнить последние значения
	
	for row=1, #settings.secList do
		--message(settings.secList[row][1])
		OnParam( settings.ClassCode, settings.secList[row][1] )
	end
	
	--задержка 100 миллисекунд между итерациями 
	while is_run do
		sleep(50)
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








