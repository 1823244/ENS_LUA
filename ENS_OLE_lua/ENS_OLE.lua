--система Олейника
--закрытие часа выше 60-и периодной скользящей - покупка и дальнейшая работа от лонга
--закрытие часа ниже 60-и периодной скользящей - продажа и дальнейшая работа от шорта

local sqlite3 = require("lsqlite3")
local db = sqlite3.open(getScriptPath() .. "..\\positions.db")

local bit = require"bit"

--актуальнй путь к файлам классов
--c:\TRAIDING\ROBOTS\DEV\ENS_MA_lua\devzone\ClassesC\

--common classes
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\class.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Window.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Helper.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Trader.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Transactions.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Security.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\logs.lua")

--common within one strategy
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Strategies\\StrategyOLE.lua")

--private for each robot
dofile (getScriptPath().."\\Classes\\SettingsOLE.lua")


--dofile ("C:\\TRAIDING\\ROBOTS\\DEV\\ENS_MA_lua\\devzone\\ClassesC\\NKLog.luac")
--require "NKLog"

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

Waiter=0		--какой-то флаг, здесь похоже не используется, зато есть в свойствах класса StrategyBollinger

--local hID=0		--вроде бы не используется, зачем он тут нужен?
 
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
	trans:CalcDateForStop()	--формирует строку ггммдд и возвращает ее в свойстве dateForStop таблицы trans
	
    if (tostring(sec) ~= settings.SecCodeBox)  then
		return 0
	end
		
	time = os.date("*t")

	strategy.Second=time.sec	--секунда

	security:Update()	--обновляет цену последней сделки в таблице security (свойство Last,Close)

	window:InsertValue("Цена",tostring(security.last))

	--QLUA getNumCandles
	--Функция предназначена для получения информации о количестве свечек по выбранному идентификатору. 
	--Формат вызова: 
	--NUMBER getNumCandles (STRING tag)
	--Возвращает число – количество свечек по выбранному идентификатору. 

	--источник комментов [1] - это http://robostroy.ru/community/article.aspx?id=796
	--[1]Сначала мы получаем количество свечей. здесь: на графике цены
	NumCandles = getNumCandles(settings.IdPriceCombo)	
 
	if NumCandles==0 then
		return 0
	end
 
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
	tPrice,n,s = getCandlesByIndex(settings.IdPriceCombo,0,NumCandles-3, 2)		
	strategy:SetSeries(tPrice)


		
	--далее пошли запрашивать цены с графика moving averages
	tPrice,n,s = getCandlesByIndex(settings.IdMA,0,NumCandles-3, 2)		
	strategy.Ma1Series=tPrice	--этого поля (Ma1Series) нет в Init, оно создается здесь


	security:Update()		--обновляет цену последней сделки в таблице security (свойство Last,Close)
	strategy.Position=trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox)
	
	--[[
	local logfile = "c:\\TRAIDING\\ROBOTS\\DEMO\\ENS_MA_lua\\ARQA\\log.txt"
	Helper:AppendInFile(logfile, "----------------------------------------".."\n")
	--Helper:AppendInFile(logfile, "sec code: "..self.secCode.."\n")
	Helper:AppendInFile(logfile, "sec code: "..tostring(settings.SecCodeBox).."\n")
	Helper:AppendInFile(logfile, "Position: "..tostring(strategy.Position).."\n")	
	Helper:AppendInFile(logfile, "settings.LotSizeBox: "..tostring(settings.LotSizeBox).."\n")	
	Helper:AppendInFile(logfile, "strategy.LotToTrade: "..tostring(strategy.LotToTrade).."\n")	
	--Helper:AppendInFile(logfile, "enter_quantity: "..tostring(enter_quantity).."\n")	
	--Helper:AppendInFile(logfile, "exit_quantity: "..tostring(exit_quantity).."\n")	
	Helper:AppendInFile(logfile, "rejim: "..tostring(settings.rejim).."\n")	
	--]]
	
	strategy.secCode = sec --ENS для отладки
	if working==true  then
		strategy:DoBisness()
	else
		--ENS только показываем значения скользящих
		strategy:CalcLevels()
		
	end
	strategy.PredPosition=strategy.Position

	
	--обновляем данные в визуальной таблице робота
	window:InsertValue("MA (60)",tostring(strategy.Ma1))
	window:InsertValue("Close",tostring(strategy.PriceSeries[1].close))
	
	window:InsertValue("MA pred (60)",tostring(strategy.Ma1Pred))
	window:InsertValue("PredClose",tostring(strategy.PriceSeries[0].close))
	
	window:InsertValue("Позиция",tostring(strategy.Position))

	--для отладки
	--покажем сигнал: buy/sell
	
	--strategy.PriceSeries[0].close - закрытие предпредыдущего бара (самого раннего из двух)
	--strategy.PriceSeries[1].close - закрытие предыдущего бара
	

	---[[
  --закрытие часовика выше средней - покупка
	if strategy:signal_buy() == true then
		window:InsertValue("Сигнал", 'buy')
		logs:add('signal buy'..'\n')
	else
		window:InsertValue("Сигнал", '')
		
	end
	
	--закрытие часовика ниже средней - продажа
	if strategy:signal_sell() == true then
		window:InsertValue("Сигнал", 'sell')
		logs:add('signal sell'..'\n')
	else
		window:InsertValue("Сигнал", '')
		
	end
	
	--]]
	
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
	
	x=GetCell(window.hID, par1, par2) 

	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="Buy по рынку" then
			message("Buy",1)
			OnBuy()
		end
	end

	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="Sell по рынку" then
			message("Sell",1)
			OnSell()
		end
	end


	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="Старт" then
			OnStart()
			message("Старт",1)
			window:SetValueWithColor("Старт","Остановка","Red")
			working=true
		end
	end

	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="Остановка" then

			message("Остановка",1)
			window:SetValueWithColor("Остановка","Старт","Green")
			working=false
		end
	end




	if (msg==QTABLE_CLOSE)  then
		window:Close()
		is_run = false
		--message("Стоп",1)
	end

	if msg==QTABLE_VKEY then
		--message(par2)
		if par2 == 27 then-- esc
			window:Close()
			is_run=false
			
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
	
	--window:Init("ENS MovingAverages", {'A','B'})	--вызываем метод init класса window
	window:Init(settings.TableCaption, {'A','B'})	--вызываем метод init класса window
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

	--автозапуск
	
	--для массового тестирования этот флаг надо сразу включать, т.к. вручную неудобно если роботов много
	--[[ для продакшн - нужно выключить автозапуск
	if working == false then
		OnStart()
		message("Старт",1)
		window:SetValueWithColor("Старт","Остановка","Red")
		working=true
	end
	--]]
	
	--задержка 100 миллисекунд между итерациями 
	while is_run do
		sleep(1000)
	end

end