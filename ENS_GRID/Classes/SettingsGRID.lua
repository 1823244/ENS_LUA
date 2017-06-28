helper = {}
Settings = class(function(acc)
end)

function Settings:Init()
  self.DepoBox = ""
  self.ClientBox = ""
  self.ClassCode = ""
  self.SecCodeBox = ""
  self.LotSizeBox = ""
  self.TypeLimitCombo = ""
  self.IdPriceCombo = ""
  self.IdMA = ""
  self.logFile = ""
  self.invert_deals = false
  self.start_all = true
  
  self.Path = ""
  self.TableCaption=""
  self.rejim=""
  helper = Helper()
  helper:Init()
  
  self.logFile = getScriptPath()..'\\log.txt'
  
  --ниже идет геометрия экрана
  
  self.main_position = {x=50,y=105,dx=1300,dy=400} --позиция главного окна
  self.log_position = {x=50,y=500,dx=1300,dy=300} --позиция окна логов
  
  self.signals_position = {x=810,y=10,dx=700,dy=200} --позиция окна сигналов
  self.orders_position = {x=810,y=210,dx=700,dy=200} --позиция окна заявок
  
  self.db_path = getScriptPath() .. "\\ens_grid.db"
  self.robot_id = 'ENS_GRID_01'
end



function Settings:instruments_list()
  
	local secList = {} --таблица инструментов. 
	--колонки:
	--1 Имя инструмента
	--2 код вида фьюча (необязательный для спота). планировалось, что он будет использовать для имени графика, но потом для этого я стал использовать имя инструмента из первой колонки
	--3 код инструмента
	--4 количество лотов
	--5 режим
	--6 класс инструмента
	--7 торговый счет
	--8 счет депо
	--9 режим включения. start (включается сразу после запуска) / stop
	

  
	--раз в квартал менять код месяца
  
	local row = 1
	---[[
	--индексы
	row, secList = addOneInstrumentToTable(row, {'RTS',     'RI', 'RIU7', 2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'MICEX',   'MX', 'MXU7', 2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'MCX MINI','MM', 'MMU7', 2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList)
	
	--валюты
	row, secList = addOneInstrumentToTable(row, {'SI',  'Si', 'SiU7', 2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'EU',  'Eu', 'EuU7', 2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --EUR/RUB Eu
	row, secList = addOneInstrumentToTable(row, {'ED',  'ED', 'EDU7', 2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --EUR/USD ED
	row, secList = addOneInstrumentToTable(row, {'UJPY','JP', 'JPU7', 2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --USD/JPY UJPY
	row, secList = addOneInstrumentToTable(row, {'GBPU','GU', 'GUU7', 2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --GBP/USD GBPU
	row, secList = addOneInstrumentToTable(row, {'AUDU','AU', 'AUU7', 2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --AUD/USD AUDU
	row, secList = addOneInstrumentToTable(row, {'UCAD','CA', 'CAU7', 2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --USD/CAD UCAD
	--в следующих трех движений нет вообще!!!
	--row, secList = addOneInstrumentToTable(row, {'UCHF','CF', 'CFU7', 2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --USD/CHF UCHF
	--row, secList = addOneInstrumentToTable(row, {'UTRY','TR', 'TRU7', 2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --USD/TRY UTRY
	--row, secList = addOneInstrumentToTable(row, {'UUAH','UH', 'UHU7', 2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --USD/UAH UUAH гривна

	--комоды
	--brent надо обновлять каждый месяц
	row, secList = addOneInstrumentToTable(row, {'BRENT','BR', 'BRN7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --brent BR-4.17

	row, secList = addOneInstrumentToTable(row, {'GOLD','GD', 'GDU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --gold
	row, secList = addOneInstrumentToTable(row, {'SILV','SV', 'SVU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --silv
	row, secList = addOneInstrumentToTable(row, {'PLT', 'PT', 'PTU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --plt
	row, secList = addOneInstrumentToTable(row, {'PLD', 'PD', 'PDU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --pld

	--фьючерсы на акции
	row, secList = addOneInstrumentToTable(row, {'SBRF','SR', 'SRU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --SBRF
	row, secList = addOneInstrumentToTable(row, {'GAZR','GZ', 'GZU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --GAZR
	row, secList = addOneInstrumentToTable(row, {'VTBR','VB', 'VBU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --VTBR
	row, secList = addOneInstrumentToTable(row, {'LKOH','LK', 'LKU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --LKOH
	row, secList = addOneInstrumentToTable(row, {'ROSN','RN', 'RNU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --ROSN
	row, secList = addOneInstrumentToTable(row, {'SBPR','SP', 'SPU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --SBPR sber pref
	row, secList = addOneInstrumentToTable(row, {'FEES','FS', 'FSU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --FEES
	row, secList = addOneInstrumentToTable(row, {'HYDR','HY', 'HYU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --HYDR
	row, secList = addOneInstrumentToTable(row, {'GMKR','GM', 'GMU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --GMKR
	row, secList = addOneInstrumentToTable(row, {'MGNT','MN', 'MNU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --MGNT
	row, secList = addOneInstrumentToTable(row, {'SNGR','SN', 'SNU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --SNGR
	row, secList = addOneInstrumentToTable(row, {'MOEX','ME', 'MEU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --MOEX
	row, secList = addOneInstrumentToTable(row, {'SNGP','SG', 'SGU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --SNGP
	row, secList = addOneInstrumentToTable(row, {'ALRS','AL', 'ALU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --ALRS
	row, secList = addOneInstrumentToTable(row, {'NLMK','NM', 'NMU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --NLMK
	row, secList = addOneInstrumentToTable(row, {'TATN','TT', 'TTU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --TATN
	row, secList = addOneInstrumentToTable(row, {'MTSI','MT', 'MTU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --MTSI
	row, secList = addOneInstrumentToTable(row, {'RTKM','RT', 'RTU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --RTKM
	row, secList = addOneInstrumentToTable(row, {'CHMF','CH', 'CHU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --CHMF --северсталь
	row, secList = addOneInstrumentToTable(row, {'TRNF','TN', 'TNU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --TRNF
	row, secList = addOneInstrumentToTable(row, {'NOTK','NK', 'NKU7',2, 'revers', 'SPBFUT', 'SPBFUT00922', 'SPBFUT00922', 'start'}, secList) --NOTK --новатэк

    
    --валюты
	row, secList = addOneInstrumentToTable(row, {'USD',  '' , 'USD000UTSTOM', 2, 'revers', 'CETS', '10646', 'MB1000100002', 'stop'}, secList)
    
	--]]
    --акции на споте
	---[[
	row, secList = addOneInstrumentToTable(row, {'GAZPROM',	'', 'GAZP', 10, 'revers', 'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'GMK',		'', 'GMKN', 10, 'revers', 'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'LUKOIL',	'', 'LKOH', 10, 'revers', 'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'ROSNEFT',	'', 'ROSN', 10, 'long',   'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'SBER',	'', 'SBER', 10, 'revers', 'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'MECHEL',	'', 'MTLR', 10, 'long',   'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'AEROFLOT','', 'AFLT', 10, 'long', 'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'ALROSA',	'', 'ALRS', 10, 'revers', 'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'FSK',		'', 'FEES', 10, 'revers', 'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'RUSHYDRO','', 'HYDR', 10, 'revers', 'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'MOEXSPOT','', 'MOEX', 10, 'revers', 'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'SURGUT',	'', 'SNGS', 10, 'long', 'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'YANDEX',	'', 'YNDX', 10, 'revers', 'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	--]]
	row, secList = addOneInstrumentToTable(row, {'VTB',		'', 'VTBR', 10, 'long', 'QJSIM', '10646', 'NL0011100043', 'start'}, secList)
	row, secList = addOneInstrumentToTable(row, {'MTS',		'', 'MTSS', 10, 'long', 'QJSIM', '10646', 'NL0011100043', 'start'}, secList)

	
	
  return secList

end

--добавляет "строку в таблицу" с инкрементом счетчика (а то руками неудобно каждый раз перенумеровывать)
--row - число, номер элемента массива (номер строки другими словами)
--inst_table - массив с параметрами инструмента (строка таблицы)
--res_table - in/out - результирующая таблица
function addOneInstrumentToTable(row, inst_table, res_table)

	
	res_table[row]=inst_table
	
	row = row + 1
	
	return row, res_table
	
end