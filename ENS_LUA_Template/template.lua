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
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\Security.lua")
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\logs.lua")

--common within one strategy
dofile ("z:\\WORK\\lua\\ENS_LUA_Strategies\\StrategyXXX.lua")

--private for each robot
dofile (getScriptPath().."\\Classes\\SettingsXXX.lua")



--Это таблицы:
trader ={}
trans={}
helper={}
settings={}
strategy={}
security={}
window={}

logs={}

--здесь можно объявить переменные
is_run = true	--флаг работы скрипта, пока истина - скрипт работает


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

function OnStop(s)

	window:Close()
	is_run = false
	
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

	
	--даблклик по таблице
	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="текст в ячейке" then
			message("нажали на ячейку",1)
			
		end
	end

	--закрытие окна робота по крестику
	if (msg==QTABLE_CLOSE)  then
		window:Close()
		is_run = false
		--message("Стоп",1)
	end
	
	--закрытие окна робота кнопкой ESC
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
	
	window:Init("Заголовок окна робота", {'A','B'})
	
	--добавляем строки в таблицу робота. есть 2 колонки - A и B.
	
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


	
	--задержка 100 миллисекунд между итерациями 
	while is_run do
		sleep(1000)
	end

end