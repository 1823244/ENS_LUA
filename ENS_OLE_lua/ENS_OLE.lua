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
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\SQLiteWork.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\logstoscreen.lua")

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
sqlitework={}
logstoscreen={}

logs={}


local db = nil 


is_run = true	--флаг работы скрипта, пока истина - скрипт работает

working = false	--флаг активности. чтобы не закрывая окно можно быть включить/выключить робота

Waiter=0		--какой-то флаг, здесь похоже не используется, зато есть в свойствах класса StrategyBollinger

--лимиты и счетчики безопасного количества выполнения колбэков. если уйдем в бесконечный цикл, то по достижении лимита прервем его
safeIterationsOrdersLimit = 5
safeIterationsOrdersCount = 0
safeIterationsTradesLimit = 5
safeIterationsTradesCount = 0

--local hID=0		--вроде бы не используется, зачем он тут нужен?

--переменна нужна для отображения анимации в окне робота,чтобы понимать,что он работает 
local count_animation=0

local math_abs = math.abs
	
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
	logstoscreen:Init() 


  
  db = sqlite3.open(settings.dbpath)
  

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

	--message('OnTransReply '..helper:getMiliSeconds())
	logstoscreen:add('OnTransReply '..helper:getMiliSeconds())

end 

--событие, возникающее после поступления сделки
function OnTrade(trade)
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
	add_order_num_to_signal(trade.trans_id, trade.order_num)
	
	
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
	

	
	
end

function OnOrder(order)
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
			--message("Старт",1)
			window:SetValueWithColor("Старт","Остановка","Red")
			working=true
		end
	end

	--для отладки
	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="TEST" then
			message("TEST",1)
			funcTest()
			--window:SetValueWithColor("Старт","Остановка","Red")
			--working=true
		end
	end
	
	--для отладки
	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="check position" then
			--message("TEST",1)
			checkPositionTest()
			--window:SetValueWithColor("Старт","Остановка","Red")
			--working=true
		end
	end	

	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="Остановка" then

			--message("Остановка",1)
			window:SetValueWithColor("Остановка","Старт","Green")
			working=false
		end
	end




	if (msg==QTABLE_CLOSE)  then
		--[[window:Close()
		is_run = false
		--message("Стоп",1)
		--]]
		StopScript()
	end

	if msg==QTABLE_VKEY then
			--message(par2)
		if par2 == 27 then-- esc
			StopScript()
			--window:Close()
			--is_run=false
			
		end
	end	

end 

--главная функция робота, которая гоняется в цикле
function main()


	--для отладки - автостарт
	--working = true
	
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
	create_window()
	
	SetTableNotificationCallback (window.hID, f_cb)

	strategy.logstoscreen = logstoscreen
	
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


function create_window()

	
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
	window:AddRow({"",""},"")
	window:AddRow({"TEST",""},"Green")
	window:AddRow({"",""},"")
	window:AddRow({"check position",""},"Green")
end


function main_loop()

		security:Update()	--обновляет цену последней сделки в таблице security (свойство Last,Close)

		window:InsertValue("Цена",tostring(security.last))		

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

		security:Update()		--обновляет цену последней сделки в таблице security (свойство Last,Close)
		strategy.Position=trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox)
		
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
		elseif strategy:signal_sell() == true then
		--закрытие часовика ниже средней - продажа
			window:InsertValue("Сигнал", 'sell')
			logs:add('signal sell'..'\n')			
			
		end
	


end

function animation()
	  
	if working==false then return false end
	
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


--запускает тест стратегии. только добавляет сигнал, а остальное сделает DoBusiness
function funcTest()

	strategy:DoBisness(true)
	
end

--для отладки. проверяет функцию получения текущей позиции
function checkPositionTest()

a = strategy:findPosition2(settings.SecCodeBox, settings.ClassCode, settings.ClientBox, settings.DepoBox, settings.robot_id)
message(tostring(a))
end