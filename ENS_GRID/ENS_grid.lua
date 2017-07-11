--��� ����������� ������ ����������� � �������� ������ ��������� �����
--���� ���� ������������� ��������� ������ �� ���� ������, �� ����� ��������� ���� �������
--������� � ����, ���� ���� ��� � �������
--���� ������ ��� �� ������� �������

--���������� �� ���������
--������� �������, ������� ���������� ������ ������������, ������� - secListFutures()
--�������� ����������� � ������� � ������� main, ��. �� �������
--������� ������� ���� ���� ����� ������������. ������������� ������� ����������� �� ��������� ������, ��. �������
--������.

--cheat sheet
--��������� �������� � ������ �������
--setVal(row, 'LastPrice', tostring(security.last))
--��������� �������� �� ������
-- local acc = getVal(row, 'Account')
--������ � ���
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
dofile (getScriptPath().."\\Classes\\HelperGRID.lua")--��������������� ������� ������ ��� ����� ������

dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\EMA.lua")

dofile (getScriptPath() .. "\\quik_table_wrapper.lua")

--��� �������:
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

local is_run = true	--���� ������ �������, ���� ������ - ������ ��������

local signals = {} --������� ������������ ��������.	
local orders = {} --������� ������


--��� ������� ����� ��� ����, ����� �� ������������ ��������� ������� �� ���� � �� �� ������/������
local processed_trades = {} --������� ������������ ������
local processed_orders = {} --������� ������������ ������

local db = nil --����������� � ���� SQLite

--��� ����� �������� ��������� ����������� � ������ ����� ������������ ������� ���������� ����
local EMA_Array = {}--������ ������������ �������� ���������� ������� ���������� ��� ������ �����������
local TableEMA = {} --������� � �������� ������� ���������� ��� ���� ������������
local TableEMAlastCandle = {} -- ������� � ��������� ������������ ������ �� ���. ����� ������ ��� � ������ �� �������

local TableDS= {} --��������� ��� ���� ������������
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
	
	local extended = true--���� ����������� ������� ����
	logstoscreen:Init(settings.log_position, extended) 	
	
	db = sqlite3.open(settings.db_path)
	
	--��������� �������� � ����������� ������, ����� �������� insert. �� ������� http://pawno.su/showthread.php?t=105737 (����������, ��� ���� ��������� ����������� ����!)
	--���������: �� ���������� 50 ������� ����������� 5 ������, ����� - 1 ������� � ���, ������ �� ������, � ������� ���������� ������� �� ��������
	db:exec('PRAGMA journal_mode = OFF')
	db:exec('PRAGMA synchronous = OFF')
	
	
	helperGrid.db = db
	
	--�������� ������� ��� ������� ����� � �������� � SQLite
	helperGrid:create_sqlite_table_orders()
	helperGrid:create_sqlite_table_signals()
	helperGrid:create_sqlite_table_Logs()
		
	EMAclass=MovingAverage()
	EMAclass:Init()
end

--��� �� ���������� �������, � ������ ������� �������/�������
--Parameters:
--	row - int - number of row in main table
--	direction - string - deal direction. for case when function uses outside of main algorithm. values: 'buy', 'sell'
function buySell(row, direction)

	local SecCodeBox	= getVal(row, 'Ticker')
	local ClassCode 	= window:GetValueByColName(row, 'Class').image
	local ClientBox 	= window:GetValueByColName(row, 'Account').image
	local DepoBox 		= window:GetValueByColName(row, 'Depo').image
	--������������� ���������� ����� �����������, ����� ����� ����� ���� ������, �� ����� ���������� ������ �����
	local trans_id 		= tonumber(window:GetValueByColName(row, 'trans_id').image)
	
	--���� �������� ����������� - ���������� ���
	local dir = ''
	if direction ~= nil then
		dir = direction
	else
		dir 			= getVal(row, 'sig_dir')
	end

	--���������� ��� ������ ����� �� "����������" - ���� qty � ������� ������� � ������ �� ��������� row
	local qty 			= tonumber(window:GetValueByColName(row, 'qty').image)
	
	--�������� ���� ��������� ������, ����� �������� ���������� �����������
	security.class = ClassCode
	security.code = SecCodeBox
	security:Update()
	
	--local minStepPrice = tonumber(window:GetValueByColName(row, 'minStepPrice').image)

	logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() ���� Last '..tostring(security.last))
	logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() minStepPrice '..tostring(security.minStepPrice))


	
	local price = 0

	if dir == 'buy' then
		price = tonumber(security.last) + 150 * security.minStepPrice
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() price = last + 150 * minStepPrice =  '..tostring(price))
	elseif dir == 'sell' then
		price = tonumber(security.last) - 150 * security.minStepPrice
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() price = last - 150 * minStepPrice =  '..tostring(price))
	end		

	--�������� ���� �� ���������� ������� (������ ��� ������)
	if ClassCode == 'SPBFUT' or ClassCode == 'SPBOPT' then

		security:GetEdgePrices()
	
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() pricemax '..tostring(security.pricemax))--������ ��� ������
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() pricemin '..tostring(security.pricemin))--������ ��� ������
	
		if dir == 'buy' then
			if security.pricemax~=0 and price > security.pricemax then
				price = security.pricemax
				logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() ���� ���� ��������������� ��-�� ������ �� ������� ���������. ����� �������� '..tostring(price))
			end
		elseif dir == 'sell' then
			if security.pricemin~=0 and price < security.pricemin then
				price = security.pricemin
				logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() ���� ���� ��������������� ��-�� ������ �� ������� ���������. ����� �������� '..tostring(price))
			end
		end		
	end
	
    if dir == 'buy' then
		transactions:orderWithId(SecCodeBox, ClassCode, "B", ClientBox, DepoBox, tostring(price), qty, trans_id)
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() ���������� ���������� �� '..tostring(trans_id)..' � ������������ BUY �� ���� '..tostring(price) .. ', ���� ����������� ���� '..tostring(security.last) .. ', ���������� '..tostring(qty))
	elseif dir == 'sell' then
		transactions:orderWithId(SecCodeBox, ClassCode, "S", ClientBox, DepoBox, tostring(price), qty, trans_id)
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() ���������� ���������� �� '..tostring(trans_id)..' � ������������ SELL �� ���� '..tostring(price) .. ', ���� ����������� ���� '..tostring(security.last) .. ', ���������� '..tostring(qty))
	end	
	
	--�������, �.�. ��� �������� ��������
	setVal(row, 'qty', tostring(0))
	
end


function OnConnected(flag)
  --http://www.kamynin.ru/2015/02/11/lua-proverka-podklyucheniya-k-serveru-quik/
  --[[
    �������� ������ � ���, ��� ����� ����������� � � ����� isconnected ��� ��������,
    �������� ������������ �������� ������ � �������.
    � � ���� �� �� ������� isConnected ��������� ������,
    �� ������ �������� ������ ���� �������� � ������ �������.
    ����������� �������� ��������� ��������� ������ ����� �������� �������� ������.
    � � ������ �������� ���������� �� ������ ������� ����������, �� � ������ �������� ������.
    ������� isConnected ����� �� ������������.
    ������-��, � ��������� ������- OnConnected � ������ ��������.  
  --]]
  
  --��� ��������� ������� �� LUA ��� ��������� QUIK ��������� �������� ������� ������ ����� ����������� � �������.
  --������ �������� ����� ������ ��������� �������.
  
  
  --[[
  local i=200 
  local s=getInfoParam('SERVERTIME')
  
  while i>=0 and s=='' do 
    i=i-1
    sleep(200)
    s=getInfoParam('SERVERTIME')
  end
 
  local is_run = true  --���� ������ �������, ���� ������ - ������ ��������
  --]]
 
end



--������
function OnStop(s)

	stopScript()
	
end 

--��������� ���� � ��������� ���� ������ �������
function stopScript()

	is_run = false
	window:Close()
	
	logstoscreen:CloseTable()
	DestroyTable(signals.t_id)
	DestroyTable(orders.t_id)

	
end

--�����������. ������ � ������ ������ �����������
function startStopRow(row)

	if window:GetValueByColName(row, 'StartStop').image == 'start' then
		helperGrid:Red(window.hID, row, window:GetColNumberByName('StartStop'))

		setVal(row, 'StartStop', 'stop')
		setVal(row, 'current_state', 'waiting for a signal')
		logstoscreen:add2(window, row, nil,nil,nil,nil,'StartStopRow() ���������� ������� � ������')
	else
		helperGrid:Green(window.hID, row, window:GetColNumberByName('StartStop'))
		setVal(row, 'StartStop', 'start')
		setVal(row, 'current_state', 'stopped')
		logstoscreen:add2(window, row, nil,nil,nil,nil,'StartStopRow() ���������� ����������')
		setVal(row, 'LastPrice', tostring(0))
	end
end


--�������, ����������� ����� �������� ������ �� ������
function OnTransReply(trans_reply)

	--�������� ����� ������ � ������� Orders, � ������ � ������� trans_id
	local s = orders:GetSize()
	local rowNum=nil
	local found = false
	local orders_row = nil
	for i = s, 1, -1 do
		
		--����� �������� �������� ��� ������ � ������� ������� - row, �.�. � ��������� ���� ������� ���������� ������, �� ����� ������ ������ ������
		--�� ��� �� ����� ���������, �.�. trans_id ������ ���������� ���������� �� ������ ����������� ���� �����.
		--�� �����, ��� �� ������ - ������� ��� ����-�����.
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
		logstoscreen:add2(window, rowNum, nil,nil,nil,nil,  '��������� ��������� � ���������� ������: '.. trans_reply.result_msg)
		
		--��������� ����������, �� �������� ������ ������
		if rowNum~=nil then
			setVal(rowNum, 'StartStop', 'stop')--turn off
			startStopRow(rowNum)
			logstoscreen:add2(window, rowNum, nil,nil,nil,nil,  'instrument was turned off due to error with code '..tostring(trans_reply.status))
		end
		
		--����� ������� ������ � ������� Orders
		orders:SetValue(orders_row, 'trans_reply', 'FAIL')
	end
	
end 


function OnTrade(trade)

	--���� ������ ��� ���� � ������� ������������, �� ��� ��� �� ���� �� ������������
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
		--��������� ������ � ������� ������������
		processed_trades[#processed_trades+1] = trade.trade_num
	end
		
	
	
	--������� ���������� �� ������ � ������� qty_fact ������� �������
 
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
			
			--����� ����� ������������, �.�. ���������� � ������ - � �����, �� ��� ��� �� �����, ������� - ����, � ��� ����� ����������!
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
	
	--��� ���� �����. �������� ��������� ��������, � � ������ ��� ��� trans_id! ������� ������ ������ �� ������������
	if order.trans_id==0 then
		return
	end
	--���� ������ ��� ���� � ������� ������������, �� ��� ��� �� ���� �� ������������
	local found = false
	for i = #processed_orders, 1, -1 do
		
		if tostring(processed_orders[i]) == tostring(order.order_num) then
			found = true
			break
		end
	end
	if found == true then
		--���� ��������, ��� �������
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

--[[f_cb � ������� ��������� ������ ��� ��������� ������� � �������. ���������� �� main()
	(���, ������� �������, ���������� ����� �� ������� ������)
	���������:
	t_id - ����� �������, ���������� �������� AllocTable()
	msg - ��� �������, ������������ � �������
	par1 � par2 � �������� ���������� ������������ ����� ��������� msg, 
--]]
local f_cb = function( t_id,  msg,  par1, par2)
	
	--QLUA GetCell
	--������� ���������� �������, ���������� ������ �� ������ � ������ � ������ �key�, ����� ������� �code� � ������� �t_id�. 
	--������ ������: 
	--TABLE GetCell(NUMBER t_id, NUMBER key, NUMBER code)
	--��������� �������: 
	--image � ��������� ������������� �������� � ������, 
	--value � �������� �������� ������.
	--���� ������� ��������� ���� ������ ��������, �� ������������ �nil�.
	
	local x=GetCell(window.hID, par1, par2) 

	--�������
	--QTABLE_LBUTTONDBLCLK � ������� ������� ����� ������ ����, ��� ���� par1 �������� ����� ������, par2 � ����� �������, 
	
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

	--�������� ���� ������ ������� ESC
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

--������ �� �������� ������� ������������ � ��������� ������ � ���� � ������� �������
function addRowsToMainWindow()

	local List = settings:instruments_list() --��� ��������� ������ (�������)
	
	--��������� ������ � ������������� � ������� ������
	for row=1, #List do
		
		rowNum = InsertRow(window.hID, -1)
		
		setVal(rowNum, 'Account', 	List[row][7])
		setVal(rowNum, 'Depo', 		List[row][8])
		setVal(rowNum, 'Name', 		List[row][1]) 
		setVal(rowNum, 'Ticker', 		List[row][3]) --��� ������
		setVal(rowNum, 'Class', 		List[row][6]) --����� ������
		setVal(rowNum, 'Lot', 		List[row][4]) --������ ���� ��� ��������
		--����� �������� ����, ���� � ���������� start, �� ����� ��������� ������, � � ���� StartStop ��������� �������� stop
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
		
		--����� �������� ����� ������� ���������� ������� GetColNumberByName()
		
		helperGrid:Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		helperGrid:Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
		
		local minStepPrice = getParamEx(List[row][6], 	List[row][3], "SEC_PRICE_STEP").param_value + 0
		setVal(rowNum, 'minStepPrice', tostring(minStepPrice))
		
		
	end  

end




  


--������� ������� ������, ������� �������� � �����
function main()

	if settings.invert_deals == true then
		message('�������� �������������� ������!!!',3)
		logstoscreen:add2(window, nil, nil,nil,nil,nil,'�������� �������������� ������!!!')
	end

	--������� ��������������� �������

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
	
	--������� ���� ������ � �������� � ��������� � ��� ������� ������
	window = Window()									--������� Window() ����������� � ����� Window.luac � ������� �����
	
	--ENS ����� window �������� ���� columns, ����� ����� ����� ���� �����  ����� ������� �� �����
	--������� 'MA60name','PriceName' �������� �������������� ��������. ��� ������ ������ - ���� �������������
	--������ ��������������: ��������������_grid_MA60, ��������������_grid_price
	--������� 'MA60Pred','MA60' �������� �������� ������� ���������� ��� ��������������� � ����������� ���� ��������������
	--������� 'PricePred','Price' �������� �������� ���� ��� ��������������� � ����������� ���� ��������������
	--������� 'BuyMarket','SellMarket' - ��� "������", �.�. �������, �� ������� ����� ������������, ����� ������/������� �� ����� ���������� ���������� �� ������� Lot
	--'StartStop' - "������", ����������� ���������� ������ ��� ����������� �����������. ���� ����� ��������, �� �� ��� ����� ����������
	--�������� ��������� ����, �������������� � ���������� ���� � ������� ����������
	
	--rejim: long / short / revers
	--sig_dir - signal direction
	--trans_id - �����, ������������� ���������������� ����������, ������������ ����������. �� ���� ��������� ������ � ������ ��� ������ �������
	--current_state - ������� ��������� �� �����������
	--signal_id - ������������� �������
	--savedPosition - ����� - ���� ��������� ������� ����� ��������� ����������, � ����� � ������� �������� ������ ���������, ���������� �� ��� ����������
	--stop_order_id - ���������������� �� ��� ����-�����
	--start_price - ���� �� ������� ����� � ������. ������ �� �������� � ���������� ��������� �������, ���� ������� ������
	local t = {'current_state','Account','Depo','Name','Ticker','Class', 'Lot', 'Position','sig_dir','LastPrice','BuyMarket','SellMarket','StartStop','MA60Pred','MA60','PricePred','Price','PriceName','MA60name','minStepPrice','rejim','trans_id','signal_id','test_buy','test_sell','qty','savedPosition', 'stop_order_id', 'start_price'}
	window:Init(settings.TableCaption, t, settings.main_position)
	
	--��������� ������ � ������������� � ������� �������
	addRowsToMainWindow()

	--���������� ������� ������� �������
	SetTableNotificationCallback (window.hID, f_cb)

	--��������� ��� �������� ��������	
	local col = window:GetColNumberByName('StartStop')
	for row=1, GetTableSize(window.hID) do
		if settings.start_all == true then
			startStopRow(row)
		else
			helperGrid:Green(window.hID, row, window:GetColNumberByName('StartStop'))
		end
		
		--��� ���������������� ������� ������� ����� ������������ datasource
		local class_code =  window:GetValueByColName(row, 'Class').image
		local sec_code =  window:GetValueByColName(row, 'Ticker').image
		
		--datasource ������� � ���������� �������
		TableDS[row], ErrorDS[row] = CreateDataSource (class_code, sec_code, INTERVAL_M1) --������� ���������� � �������

		if TableDS[row] == nil then
			logstoscreen:add2(window, row, nil,nil,nil,nil,'error when setting creating DataSource: '..ErrorDS[row])
			--��������� ����������, �� �������� ������ ������

			setVal(row, 'StartStop', 'stop')--turn off
			startStopRow(row)
			logstoscreen:add2(window, row, nil,nil,nil,nil,  'instrument was turned off due to error creating datasource')
			
		else
		
			--��������� ������ �� ���������� ������. ���� ������
			local res= TableDS[row]:SetEmptyCallback()
			if res == false then
				logstoscreen:add2(window, row, nil,nil,nil,nil,'error when setting empty callback '..sec_code)
			end
			
			--����� ���������, ���� ���������� ������
			local safecount = 1
			
			while TableDS[row]:Size() == 0 do
				--logstoscreen:add2(window, row, nil,nil,nil,nil,'size of data source: '..tostring(TableDS[row]:Size()))
				sleep(50)
				safecount = safecount + 1
				if safecount > 100 then
					logstoscreen:add2(window, row, nil,nil,nil,nil,'�� ��������� ���������� ���������� �� ����������� '..sec_code)
					break
				end
			end
			logstoscreen:add2(window, row, nil,nil,nil,nil,'size of data source: '..tostring(TableDS[row]:Size()))
		
		end
		
		--����� ��������� �������
		
		TableEMAlastCandle[row] = 0 --�������, � ������� ����� ������ ��������� ������������ ������ ���������� EMA. ���� �������� ����� ����������, ����� �� ������� �������
		
		TableEMA[row]={} --������� ��������� EMA. 
		
		TableEMA[row], TableEMAlastCandle[row] = EMAclass:emaDS(TableEMA[row], TableDS[row], 60, TableEMAlastCandle[row])
		
		--logstoscreen:add2(window, row, nil,nil,nil,nil,'last of EMA array: '..tostring(TableEMA[row][TableEMAlastCandle[row]]))
		
	end
	
	
	--������� ����
	while is_run do
	
		for row=1, GetTableSize(window.hID) do
			main_loop(row)
		end
		
		sleep(500)
	end

end



--+-----------------------------------------------
--|			�������� ��������
--+-----------------------------------------------

--��� ������� ������ ���������� �� ������������ ����� � ������� main()
function main_loop(row)

	if isConnected() == 0 then
		--window:InsertValue("������", "Not connected")
		return
	end
	
	---[[
	
	--��� ���� �������� �� ������� http://www.kamynin.ru/2015/02/11/lua-proverka-podklyucheniya-k-serveru-quik/
	--���� � ��������� ���� ��������� �����������, �� ��� ����� ������ ���:
	if getInfoParam('SERVERTIME')=='' then
		-- ����������� ���
		return false
	else
		--���� �����������
	end
	--]]
  
	---[[ �������� ��������� � �������� ����
	local serv_time=tonumber(helperGrid:timeformat(getInfoParam("SERVERTIME"))) -- ��������� � ���������� ������� ������� � ������� HHMMSS
	--logstoscreen:add2(window, row, nil,nil,nil,nil,'server time '..tostring(serv_time))
	--������ 5 ����� �� �������
	if not (serv_time>=100500 and serv_time<235000) then
		return false
	end 	
	--]]

		

	--���������� ������� ��������������
	
	TableEMA[row], TableEMAlastCandle[row] = EMAclass:emaDS(TableEMA[row], TableDS[row], 60, TableEMAlastCandle[row])

	setVal(row, 'PricePred', tostring(TableDS[row]:C(TableEMAlastCandle[row]-2)))
	setVal(row, 'Price',     tostring(TableDS[row]:C(TableEMAlastCandle[row]-1)))
	
	setVal(row, 'MA60Pred', tostring(TableEMA[row][TableEMAlastCandle[row]-2]))
	setVal(row, 'MA60',     tostring(TableEMA[row][TableEMAlastCandle[row]-1]))	

	

	--���� ������ ��������� �� ����� ��������� ��� �����, � ����� ���� ������, ����� ������� ��� �� ������������
	--[[
	if window:GetValueByColName(row, 'StartStop').image =='start'  then --���������� ��������. ����� �������, ��� ����� Stop
		return
	end		
	--]]	
	-------------------------------------------------------------------
	--			�������� ��������
	-------------------------------------------------------------------
	local current_state = window:GetValueByColName(row, 'current_state').image
	
	if current_state == 'waiting for a signal' then
		--������� ����� ������� 
		wait_for_signal(row)
		
	elseif current_state == 'processing signal' then
		--� ���� ��������� ����� ���� ������ �� ������, ���� �� ������� ������� ��� �� �������� ����� ��� ���������� �������
		if window:GetValueByColName(row, 'StartStop').image =='stop'  then--������ �������� � ������
			processSignal(row)
		end		
		
	elseif current_state == 'waiting for a response' then
		--������ ���������, ���� ���� ������ �����, ����� ��������� �����
		if window:GetValueByColName(row, 'StartStop').image =='stop'  then--������ �������� � ������
			wait_for_response(row)
		end
	end

end

--[[ ����������. ������ ������� �� ������ http://bot4sale.ru/blog-menu/qlua/spisok-statej/487-coffee.html

��-�� �������� �������� � ������ stack overflow

ma =
{
    -- Exponential Moving Average (EMA)
    -- EMA[i] = (EMA[i]-1*(per-1)+2*X[i]) / (per+1)
    -- ���������:
    -- period - ������ ���������� �������
    -- get - ������� � ����� ���������� (����� � �������), ������������ �������� �������
    -- ���������� ������, ��� ��������� � �������� ����� �������������� ������ ����������� �������
    -- ��� ��������� ��������� ����� ���������� ��� ������������ ��������
	-- ��������!!!
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

--���������� ������: �������� ������� ������� � ��������, ������� ���������� �� ���������, ���� ������� ������.
function processSignal(row)
	
	--����� ����������, �� ������� �����/���������� ����� ������� ������� - ��� � ���������� ������ ������ � ������������
	
	local planQuantity = tonumber(getVal(row, 'Lot'))
	
	local signal_direction = getVal(row, 'sig_dir')
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'processing signal: '..signal_direction)
	
	if signal_direction == 'sell' then
		planQuantity = -1*planQuantity --������� �������������
	end
	
	
	
	--����������, ������� ��� �����/���������� ���� � ������� (������ ��� ���� ���� ������� ������, ������� - ������� ������� ����������)
	local factQuantity = trader:GetCurrentPosition(getVal(row, 'Ticker'), 
													getVal(row, 'Account'),
													getVal(row, 'Class'))
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'fact quantity: ' .. tostring(factQuantity))
	
	local rejim = getVal(row, 'rejim')

	if rejim == 'revers' then
		--��� ���������
		
	elseif rejim == 'long' then
		--������ � ����. ������� ������� ������� � ����
		if signal_direction == 'sell' and factQuantity >= 0 then
			planQuantity = 0
		end
		
	elseif rejim == 'short' then
		--������ � ����. �������� ������� �������� � ����
		if signal_direction == 'buy' and factQuantity <= 0 then
			planQuantity = 0
		end
	end
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'plan quantity: ' .. tostring(planQuantity))
	
	local signal_id = getVal(row, 'signal_id')
	
	--���� ��� �������� ����������, �� �������� ����
	if (signal_direction == 'buy' and factQuantity < planQuantity )
		or (signal_direction == 'sell' and factQuantity > planQuantity)
		then
		
		--������� ������

		--���������� ID ������, ����� ����� ����� ���� �� ��������
		local trans_id = helper:getMiliSeconds_trans_id()
		
		setVal(row, 'trans_id', tostring(trans_id))
		
		--���������� ���������� ��� ������ �������
		local qty = planQuantity - factQuantity
		
		if qty == 0 then
			logstoscreen:add2(window, row, nil,nil,nil,nil,'������! qty = 0')
			--���� ���������� ������� ���������� - ��������� � �������� ������ �������
			 
			setVal(row, 'current_state', 'waiting for a signal')
			setVal(row, 'sig_dir', ' ')
			return
		end
		
		if signal_direction == 'sell' then --�������� � ��������������, �.�. � ������ �� ����� ���� �������������� ����������
			qty = -1*qty
		end
		
		logstoscreen:add2(window, row, nil,nil,nil,nil,'qty: ' .. tostring(qty))
		
		
		--!!!!!!!!!!!!��� �������. ���� ��������� ��� ����� ������������ �������� ������ ������� 
		--qty = 5
		
		
		setVal(row, 'qty', tostring(qty))
		
		--��� ����������� �������� ����� ���������� � ������ �� ��������������� �������. ��� �� ���� ������ � sqlite		
		helperGrid:addRowToOrders(row, trans_id, signal_id, signal_direction, qty, window, 0) 
		
		--�������� "������" �������
		setVal(row, 'savedPosition', tostring(factQuantity))
		
		--������������� ������� �������/�������. ����������� � ���������� ��� ������� �� ������ "row"
		buySell(row)
		
		--����� �������� ���������� �� ����� ������ ��������� ������ �� ��, � ������� �� ���� ������ �� ������������ ������ - 'waiting for a signal'
		--����� ����� ��������� ��������, ����� buySell() ����� ����������� �����, � � ����� �� ������,
		--��� ������ �� ����� ���� ���������. � ���� ������ OnTransReply() �������� ��������� 'stopped',
		--� ����� �� ������ ���������, ����������� ��� ��� ���, ����� �� �������� �� 'waiting for a response',�.�. ��� ������.
		if getVal(row, 'current_state') ~= 'stopped' then
			setVal(row, 'current_state', 'waiting for a response')
		end

	else
		--������� �������
		--logstoscreen:add2(window, row, nil,nil,nil,nil,'��� ������� ��� �������, ������ �� ����������!')
		
		setVal(row, 'current_state', 'waiting for a signal')
		
		--������� ��������� ������� � ������� ��������
		local rows=0
		local cols=0
		rows,cols = signals:GetSize()
		for j = rows, 1, -1 do --� ����� �������� ��������� ���������� � �������
			if tostring(signal_id) == tostring(signals:GetValue(j, "id").image) 
				and row == tonumber(signals:GetValue(j, "row").image) then
			
				signals:SetValue(j, "done", true) 
				break
			end
		end		
		
		setVal(row, 'trans_id', 0)
		setVal(row, 'signal_id', 0)
		
		
		--[[���������� ������� ���� ����� � ������� �������. ���� ���������.
		--������ ��������� ������ � ���� ������������ � ������� orders
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
		--|		������ ���� ����
		--+------------------------------
		
		--[[
		--������� ������� ������������� ���� ���� (���� ��, �������, ����)
		kill_stop_loss(row)
		--����� ������ �����
		if factQuantity<0 then
			factQuantity=-1*factQuantity
		end
		send_stop_loss(row, factQuantity)
		--]]
	end
	
end

--������� ������ ����-����
--���������
--	factQuantity - �� - ����� - ����� ���������� ��� � ������� �������, ������� ���������� ���������� ��� ����
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
	--���� ���� ����� ���������� �� ������� �� 1%
	if sig_dir == 'buy' then
		stop_price = tonumber(security.last) - helper:round_to_step(tonumber(security.last)* 0.005,security.minStepPrice) 
	else
		stop_price = tonumber(security.last) + helper:round_to_step(tonumber(security.last)* 0.005,security.minStepPrice) 
	end
	--���� ����������� ������ - ��� �� 1% ����/���� ����-����
	local price		= 0
	if sig_dir == 'buy' then
		price = stop_price - helper:round_to_step(stop_price* 0.005,security.minStepPrice) --�� ���� ���� ����� ���������
	else
		price = stop_price + helper:round_to_step(stop_price* 0.005,security.minStepPrice) --�� ���� ���� ����� ��������
	end		
	
	--���� �������� ���������� ����� ������, �� ���� ����, ��� ������������� ���������� �����_�� ��� ������ �����.
	--���� ����� ������ ������������ �������� ����������. ���� ����� ���������� ����� ������
	local trans_id 	= helper:getMiliSeconds_trans_id()+row
	
	signal_id = nil -- ����� �� �� �����???
	helperGrid:addRowToOrders(row, trans_id, signal_id, sig_dir, factQuantity, window, 1)
	
	transactions:StopLimitWithId(seccode, class, client, depo, operation, stop_price, price, factQuantity, trans_id)
		
	setVal(row, 'stop_order_id', tostring(trans_id))
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'stop loss witn trans_id '..tostring(trans_id)..' was sent')
	
end

--������� ������� ����-����
function kill_stop_loss(row)

	--�������� id ����_����� �� ������� �������
	local stop_id = getVal(row, 'stop_order_id')
	if stop_id == nil or stop_id == 'nil' or stop_id == '' or stop_id == ' ' or stop_id == 0 then
		return
	end	
	
	--������� ����� ����� ����� ����-����� � ������� stop_orders �� id
	local s = orders:GetSize()
	local rowNum=nil
	local number = nil
	for i = s, 1, -1 do
		--����� �������� �������� ��� ������ � ������� ������� - row, �.�. � ��������� ���� ������� ���������� ������, �� ����� ������ ������ ������
		--�� ��� �� ����� ���������, �.�. trans_id ������ ���������� ���������� �� ������ ����������� ���� �����
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
		
		setVal(row, 'stop_order_id', ' ')--�������� �����
		
		logstoscreen:add2(window, row, nil,nil,nil,nil,'stop loss '..tostring(stop_id)..' was killed')
	end
	
end

--����� ������ �� ������������ ������
function wait_for_response(row)
	--logstoscreen:add2(window, row, nil,nil,nil,nil,'we are waiting the result of sending order')

	---[[
	
	--����������� ����� ������ ������ � �������, ������� � �����
	for i = orders:GetSize(),1,-1 do
		
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(getVal(row, 'trans_id'))
			and tonumber(orders:GetValue(i, 'row').image) == row then
			
			if orders:GetValue(i, 'trade')~=nil and ( orders:GetValue(i, 'trade').image~='0' and orders:GetValue(i, 'trade').image~='' and orders:GetValue(i, 'trade').image~='nil') then
				--���� � ������� orders �������� ����� ������, ��� ������ ��� ������ ������������.				
				--� ��� � �� ����. ����� �������� ���������� � ������ � � ������. ���� ������ ��������� �������������, �� ������ ����� ��� ������, ��� ��� ������������
				--���� ��� ������� � 10 ����� �������� ����� ������� ����� ���������...
				
				--����� �������������� �������� �����, ���������� ������ ��� ����� �������� �����������
				local qty_fact = orders:GetValue(i, 'qty_fact').image
				if qty_fact == nil or qty_fact == '' then
					qty_fact = 0
				else
					qty_fact = tonumber(qty_fact)
				end
			
				--����� �������������� �������� �����, ���������� ������ ��� ����� �������� �����������
				local qty = orders:GetValue(i, 'qty').image
				if qty == nil or qty == '' then
					qty = 0
				else
					qty = tonumber(qty)
				end
				
				--���������� ����������, ������� ��������� � ������ (qty) � ����������, ������� ������ � ����� � ������� (qty_fact)
				if qty_fact >= qty then
					
					logstoscreen:add2(window, row, nil,nil,nil,nil,'order '..orders:GetValue(i, 'order').image..': qty_fact >= qty. Order is processed!')
					
				end

				--��������� �������. ��� ����� ������ ���������� �� ���������� ������� orders
				--���� ������� �� ���������� ������������ ������������ ����� ��������� ���������� ���������� - ��������� ������ �� ������
				
				--������� ������� ������� �� ������
				local curPosition = trader:GetCurrentPosition(	getVal(row, 'Ticker'), 
																getVal(row, 'Account'), 
																getVal(row, 'Class'))
				--������� ���������� ������� �� ������� ������� ������
				local savedPosition = tonumber(getVal(row, 'savedPosition'))
				
				--���� ������� ����������, ������ ������ ����������, ���� �� ��������.
				--��������. ����� �������� ������� ����������� ����������, ����� � ����������� ���� �� ����
				if curPosition ~= savedPosition then
					
					--����������� ��������� ������ �� ������� ����������� - ����� ��������� � ��������� �������, �.�. �������� ������� �������� ���
					setVal(row, 'current_state', 'processing signal')
					--������� ������� �� ������ ��������� �������� � ������� �������
					setVal(row, 'savedPosition', tostring(curPosition))--���� ��� ����� �� ������, ��� ����� � processSignal() ���������
					
				end

				break	

			end
		end
	end
	--]]
		
end

--������� ���������, �� ������� ���������� ����
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
					--���� ���� 0,1% ������� - ��������� 2 ����
					local trans_id 	= helper:getMiliSeconds_trans_id()+(row*2)
					local price = security.bid - (security.minStepPrice * 3)
					transactions:orderWithId(SecCodeBox, ClassCode, "S", ClientBox, DepoBox, tostring(price), 2, trans_id)
					logstoscreen:add2(window, row, nil,nil,nil,nil,'������� 2 ���� �� ������. ���������� ���������� �� '..tostring(trans_id)..' � ������������ SELL �� ���� '..tostring(price) .. ', ���� ����������� ���� '..tostring(security.last))
					
				end
			end

		elseif dir == 'sell' then
			
			local profit = start_price - security.offer
			if profit > 0 then
			
				if profit/start_price >= 0.001 then
					--���� ���� 0,1% ������� - ��������� 2 ����
					local trans_id 	= helper:getMiliSeconds_trans_id()+(row*3)
					local price = security.offer + (security.minStepPrice * 3)
					transactions:orderWithId(SecCodeBox, ClassCode, "B", ClientBox, DepoBox, tostring(price), 2, trans_id)
					logstoscreen:add2(window, row, nil,nil,nil,nil,'������� 2 ���� �� ������. ���������� ���������� �� '..tostring(trans_id)..' � ������������ BUY �� ���� '..tostring(price) .. ', ���� ����������� ���� '..tostring(security.last))
					
				end
			
			end

		end
	end
end

--����� ����� ������� � ������� �� �����.
function wait_for_signal(row)


	--������� ��������� �������.
	--���� ��� ����, �� �������� ��������� �������
	
	test_profit(row)
	

	
	--����� �������� ������

	--����� ������ ���, ������� ��������� ������� � ����������, ����� �������� � �����������
	--��� ����, ����� ������� ���� �������� - ����� ���������� �������� ����, ������� ������� ���������� ������, � ����� ���� ��������� ����
	--�.�. ����� ������ ���� ������� ������� ������� � ������ ����� �� ���������
	local signal_buy =  signal_buy(row)
	local signal_sell =  signal_sell(row)
	
	if signal_buy == false and signal_sell == false then
		return
	end
		
	--���� ���� ������, ����� ���������, � ����� �� ��� ��� ����������.-
	--��������� ��� ����������� 1 ���, ������� ������� ���� ����� ������ ������
	--��� ����� ��� ����� ���������
	--local dt=strategy.PriceSeries[1].datetime--���������� �����
	local dt = TableDS[row]:T(TableEMAlastCandle[row]-1)
	local candle_date = dt.year..'-'..dt.month..'-'..dt.day
	local candle_time = dt.hour..':'..dt.min..':'..dt.sec

	--�������� ������� �������, ����� �� ������������ ��������
	if find_signal(row, candle_date, candle_time) == true then
		--logstoscreen:add2(window, row, nil,nil,nil,nil,'signal '..candle_date..' '..candle_time..' is already processed')
		return
	end
		
	--logstoscreen:add2(window, row, nil,nil,nil,nil,'we have got a signal: ')
	
	local sig_dir = nil
	if signal_buy == true then 
		
		--�������� ����� ���� ������� - �������
		if settings.invert_deals == false then
			sig_dir='buy'
		else
			sig_dir='sell'
		end
		--message(sig_dir)
		
	elseif signal_sell == true	then 
		--�������� �������� ���� ������� - �������
		if settings.invert_deals == false then
			sig_dir='sell'
		else
			sig_dir='buy'
		end
		
	end
	
	setVal(row, 'sig_dir', sig_dir)
	
	--������� � ������� ���, ��������� �����
	local signal_id = helper:getMiliSeconds_trans_id()
	setVal(row, 'signal_id', tostring(signal_id))
	
	helperGrid:addRowToSignals(row, trans_id, signal_id, sig_dir, window, candle_date, candle_time, TableDS[row]:C(TableEMAlastCandle[row]-1), TableEMA[row][TableEMAlastCandle[row]-1], false) 
	
	--��������� � ����� ��������� �������. ������� ��������� ��������� �� ��������� ��������
	if window:GetValueByColName(row, 'StartStop').image =='stop'  then--������ �������� � ������
		setVal(row, 'current_state', 'processing signal')
	end
	
end

--[[	���� ������ � ������� ��������. ���������� ��� ����������� ������ �������.
������ ����� ��������� ��� ��������� ����� ����� ������������, �������� ���������� ���������� ������� ����
�.�. ����� �� �������� � ������ ������������ ����� �����, �� ��� ����� ��������� ��� ��� �����.
���� ���� ���. ���� ������ ������������� �� ����� ����� �����, �� ������� ������ ������, �� �� ����� ������ ���� ������
� ��������� �������� � �������. ���� ������� ��� ���� ������������ �� �����������, �� ������ ���������, 
��������� �������� plan-fact � �� �������� ��������� ����.
--]]
function find_signal(row, candle_date, candle_time)
	local rows=0
	local cols=0
	rows,cols = signals:GetSize()
	for i = 1 , rows do --� ����� �������� ��������� ���������� � �������
		if tonumber(signals:GetValue(i, "row").image) == row and
			signals:GetValue(i, "date").image == candle_date and
			signals:GetValue(i, "time").image == candle_time then
			--��� ���� ������, �������� ������������ �� ����
			--logstoscreen:add2(window, row, nil,nil,nil,nil,'the signal is already processed: '..tostring(signals:GetValue(i, "id").image))
			return true
		end
	end
	return false
end


--+-----------------------------------------------
--|			�������� �������� - �����
--+-----------------------------------------------

--��� �������� � �������� getCandlesByIndex()
function signal_buy_old(row)

--  Ma1 = Ma1Series[1].close						--���������� �����
--  Ma1Pred = Ma1Series[0].close 	--ENS		--�������������� �����

	--��� ������
    
	if window:GetValueByColName(row, 'test_buy').image == 'true' then
		setVal(row, 'test_buy', 'false')
		return true
	end
		
	---[[
	if strategy.Ma1 ~= 0 
	and strategy.Ma1Pred  ~= 0 
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
	and strategy.PriceSeries[0].close < strategy.Ma1Pred --�������������� ��� ���� �������
	and strategy.PriceSeries[1].close > strategy.Ma1 --���������� ��� ���� �������
	then
		return true
	else
		return false
	end
	--]]
	
	--[[
	if EMA_Array[#EMA_Array-1]  ~= 0 		--���������� �����
	and EMA_Array[#EMA_Array-2]  ~= 0 		--�������������� �����
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
	and strategy.PriceSeries[0].close < EMA_Array[#EMA_Array-2] --�������������� ��� ���� �������
	and strategy.PriceSeries[1].close > EMA_Array[#EMA_Array-1] --���������� ��� ���� �������
	then
		return true
	else
		return false
	end
--]]	
end

--��� �������� � �������� getCandlesByIndex()
function signal_sell_old(row)

--  Ma1 = Ma1Series[1].close						--���������� �����
--  Ma1Pred = Ma1Series[0].close 	--ENS		--�������������� �����


	--��� ������
	
	if window:GetValueByColName(row, 'test_sell').image == 'true' then
		setVal(row, 'test_sell', 'false')
		return true
	end
	
	if strategy.Ma1 ~= 0 
	and strategy.Ma1Pred  ~= 0 
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
--	and strategy.PriceSeries[0].close > EMA_Array[#EMA_Array-2] --�������������� ��� ���� �������
--	and strategy.PriceSeries[1].close < EMA_Array[#EMA_Array-1] --���������� ��� ���� �������
	and strategy.PriceSeries[0].close > strategy.Ma1Pred --�������������� ��� ���� �������
	and strategy.PriceSeries[1].close < strategy.Ma1 --���������� ��� ���� �������
	then
		return true
	else
		return false
	end

end



function signal_buy(row)

	--��� ������
    
	if window:GetValueByColName(row, 'test_buy').image == 'true' then
		setVal(row, 'test_buy', 'false')
		return true
	end
		
	---[[
	if tonumber(TableEMA[row][TableEMAlastCandle[row]-1]) ~= 0 
	and tonumber(TableEMA[row][TableEMAlastCandle[row]-2])  ~= 0 
	and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-2)) ~= 0
	and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-1)) ~= 0
	and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-2)) < tonumber(TableEMA[row][TableEMAlastCandle[row]-2]) --�������������� ��� ���� �������
	and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-1)) > tonumber(TableEMA[row][TableEMAlastCandle[row]-1]) --���������� ��� ���� �������
	then
		return true
	else
		return false
	end
	--]]	
		
end

function signal_sell(row)

	--��� ������
	
	if window:GetValueByColName(row, 'test_sell').image == 'true' then
		setVal(row, 'test_sell', 'false')
		return true
	end
	
	if tonumber(TableEMA[row][TableEMAlastCandle[row]-1]) ~= 0 
	and tonumber(TableEMA[row][TableEMAlastCandle[row]-2])  ~= 0 
	and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-2)) ~= 0
	and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-1)) ~= 0
	and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-2)) > tonumber(TableEMA[row][TableEMAlastCandle[row]-2]) --�������������� ��� ���� �������
	and tonumber(TableDS[row]:C(TableEMAlastCandle[row]-1)) < tonumber(TableEMA[row][TableEMAlastCandle[row]-1]) --���������� ��� ���� �������
	then
		return true
	else
		return false
	end

end

--������� ��� ��������� �������� �� ������� ������ ������� �������
function getVal(row, colName)
	return window:GetValueByColName(row, colName).image
end

function setVal(row, colName, val)
	window:SetValueByColName(row, colName, val)
end