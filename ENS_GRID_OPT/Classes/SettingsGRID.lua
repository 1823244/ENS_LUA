helper = {}
Settings = class(function(acc)
end)

function Settings:Init()
  self.DepoBox = ""
  self.ClientBox = ""
  self.ClassCode = ""
  self.SecCodeBox = ""
  self.LotSizeBox = ""
  self.logFile = ""
  self.start_all = true
  
  self.Path = ""
  self.TableCaption="MAIN::ENS_GRID_OPTIONS"
  helper = Helper()
  helper:Init()
  
  self.logFile = getScriptPath()..'\\log.txt'
  
  --ниже идет геометрия экрана
  
  self.main_position = {x=0,y=0,dx=600,dy=100} --позиция главного окна
  self.log_position = {x=0,y=100,dx=600,dy=100} --позиция окна логов
  
  self.signals_position = {x=0,y=200,dx=600,dy=100} --позиция окна сигналов
  self.orders_position = {x=0,y=300,dx=600,dy=100} --позиция окна заявок

  
  self.db_path = getScriptPath() .. "\\ens_grid.db"
  self.robot_id = 'ENS_GRID_OPTIONS_BRENT_9_17_#01'
end

function Settings:instruments_list()
	local row = 1
	--local secList = {} --таблица инструментов. 
	local secList = QTable.new()
	--колонки:
	--1 Имя базового инструмента, например RTS-9.17, оно только для информации
	secList:AddColumn('BaseASset', QTABLE_STRING_TYPE, 10 )
	--2 код опциона
	secList:AddColumn('Ticker', QTABLE_STRING_TYPE, 10 )
	--3 тип опциона - call/put - для информации
	secList:AddColumn('PutCall', QTABLE_STRING_TYPE, 10 )
	--4 количество контрактов план
	secList:AddColumn('Plan', QTABLE_DOUBLE_TYPE, 10 )
	--5 действие - buy/sell
	secList:AddColumn('Action', QTABLE_STRING_TYPE, 10 )
	--6 класс инструмента (SPBOPT)
	secList:AddColumn('Class', QTABLE_STRING_TYPE, 10 )
	--7	дата экспирации - только для информации, чтобы визуально можно было понять, какая это серия
	secList:AddColumn('Expiration', QTABLE_STRING_TYPE, 10 )
	--8 торговый счет
	secList:AddColumn('Account', QTABLE_STRING_TYPE, 10 )
	--9 счет депо
	secList:AddColumn('Depo', QTABLE_STRING_TYPE, 10 )
	--10 режим включения. start (включается сразу после запуска) / stop (не включается)
	secList:AddColumn('StartStop', QTABLE_STRING_TYPE, 10 )
	--11 отступ от теор цены. в шагах цены. например, +2 - дороже на шага, -3 - дешевле на 3 шага
	secList:AddColumn('TheorDiff', QTABLE_DOUBLE_TYPE, 10 )
		
	---[[
	--										1					2		3	4		5	6			7				8			9			10		11
	row = addOneInstrumentToTable(row, {'BR-9.17 (BRU7)', 'BR47BT7', 'PUT', 20, 'buy', 'SPBOPT', '26.08.17','SPBFUT00922', 'SPBFUT00922', 'stop', '-1'}, secList)
	
	--]]
	
  return secList

end

function addOneInstrumentToTable(row, inst_table, res_table)
	--добавляет "строку в таблицу" с инкрементом счетчика (а то руками неудобно каждый раз перенумеровывать)
	--row - число, номер элемента массива (номер строки другими словами)
	--inst_table - массив с параметрами инструмента (строка таблицы)
	--res_table - in/out - результирующая таблица

	res_table[row]=inst_table
	row = row + 1
	return row
end

function Settings:create_main_t()
	--создает таблицу, которая является прототипом для главного окна робота
	--это должна быть обычная таблица lua

	--1 Имя базового инструмента, например RTS-9.17, оно только для информации
	--2 код опциона
	--3 тип опциона - call/put - для информации
	--4 количество контрактов план
	--5 действие - buy/sell
	--6 класс инструмента (SPBOPT)
	--7	дата экспирации - только для информации, чтобы визуально можно было понять, какая это серия
	--8 торговый счет
	--9 счет депо
	--10 режим включения. start (включается сразу после запуска) / stop (не включается)
	--11 отступ от теор цены. в шагах цены. например, +2 - дороже на шага, -3 - дешевле на 3 шага

	local t = {
	'current_state',--состояние робота по этой строке инструмента
	'BaseAsset',
	'Ticker',
	'PutCall',--put/call
	'Plan',	--qty plan
	
	--'Action', --buy/sell
	
	--'Class',--SPBOPT	
	t:AddColumn('Class', QTABLE_STRING_TYPE, 10 )
	--'Expiration',
	t:AddColumn('Expiration', QTABLE_STRING_TYPE, 10 )
	--'Account',
	t:AddColumn('Account', QTABLE_STRING_TYPE, 10 )
	--'Depo',
	t:AddColumn('Depo', QTABLE_STRING_TYPE, 10 )
	--'StartStop',--10 режим включения. start (включается сразу после запуска) / stop (не включается)
	t:AddColumn('StartStop', QTABLE_STRING_TYPE, 10 )
	--'TheorDiff'--11 отступ от теор цены. в шагах цены. например, +2 - дороже на шага, -3 - дешевле на 3 шага
	t:AddColumn('TheorDiff', QTABLE_DOUBLE_TYPE, 10 )
	--}

	return t

end