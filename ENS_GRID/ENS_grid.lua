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
--window:SetValueByColName(row, 'LastPrice', tostring(security.last))
--��������� �������� �� ������
--local acc = window:GetValueByColName(row, 'Account').image

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

logs={}

local is_run = true	--���� ������ �������, ���� ������ - ������ ��������

local signals = {} --������� ������������ ��������.	
local orders = {} --������� ������

--��� ������� ����� ��� ����, ����� �� ������������ ��������� ������� �� ���� � �� �� ������/������
local processed_trades = {} --������� ������������ ������
local processed_orders = {} --������� ������������ ������

local db = nil --����������� � ���� SQLite



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
		
end

--��� �� ���������� �������, � ������ ������� �������/�������
function buySell(row)

	local SecCodeBox= window:GetValueByColName(row, 'Ticker').image
	local ClassCode 	= window:GetValueByColName(row, 'Class').image
	local ClientBox 	= window:GetValueByColName(row, 'Account').image
	local DepoBox 	= window:GetValueByColName(row, 'Depo').image
	--������������� ���������� ����� �����������, ����� ����� ����� ���� ������, �� ����� ���������� ������ �����
	local trans_id 		= tonumber(window:GetValueByColName(row, 'trans_id').image)
	--
	local dir 			= window:GetValueByColName(row, 'sig_dir').image
	--���������� ��� ������ ����� �� "����������" - ���� qty � ������� ������� � ������ �� ��������� row
	local qty 			= tonumber(window:GetValueByColName(row, 'qty').image)
	
	--�������� ���� ��������� ������, ����� �������� ���������� �����������
	security.class = ClassCode
	security.code = SecCodeBox
	security:Update()
	
	--local minStepPrice = tonumber(window:GetValueByColName(row, 'minStepPrice').image)

	logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() ���� Last '..tostring(security.last))
	logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() minStepPrice '..tostring(security.minStepPrice))
	
	security:GetEdgePrices()--������ ��� ������
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() pricemax '..tostring(security.pricemax))--������ ��� ������
	logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() pricemin '..tostring(security.pricemin))--������ ��� ������
	
	
	--�������� ���� �� ���������� �������
	local price = 0
	
    if dir == 'buy' then
		price = tonumber(security.last) + 150 * security.minStepPrice
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() price = last + 150 * minStepPrice =  '..tostring(price))
		if security.pricemax~=0 and price > security.pricemax then
			--������ ��� ������
			price = security.pricemax
			logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() ���� ���� ��������������� ��-�� ������ �� ������� ���������. ����� �������� '..tostring(price))
		end
	elseif dir == 'sell' then
		price = tonumber(security.last) - 150 * security.minStepPrice
		logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() price = last - 150 * minStepPrice =  '..tostring(price))
		if security.pricemin~=0 and price < security.pricemin then
			--������ ��� ������
			price = security.pricemin
			logstoscreen:add2(window, row, nil,nil,nil,nil,'BuySell() ���� ���� ��������������� ��-�� ������ �� ������� ���������. ����� �������� '..tostring(price))
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
	window:SetValueByColName(row, 'qty', tostring(0))
	
end



--���������� ��������� �� ������ Buy. �.�. ������ �������/������� �� �����
function buySell_no_trans_id(row, dir)

	local SecCodeBox 	= window:GetValueByColName(row, 'Ticker').image
	local ClassCode 	= window:GetValueByColName(row, 'Class').image
	local ClientBox 	= window:GetValueByColName(row, 'Account').image
	local DepoBox 		= window:GetValueByColName(row, 'Depo').image
	local qty 			= window:GetValueByColName(row, 'Lot').image
	
	security.class = ClassCode
	security.code = SecCodeBox
	security:Update()
	
	
	
	--�������� ���� �� ���������� �������
	local price = 0
	security:getEdgePrices()
    if dir == 'buy' then
		price = tonumber(security.last) + (150 * security.minStepPrice)
		if price > security.pricemax then
			price = security.pricemax
		end
	elseif dir == 'sell' then
		price = tonumber(security.last) - (150 * security.minStepPrice)
		if price < security.pricemin then
			price = security.pricemin
			
		end
	end	
	
    if dir == 'buy' then
		transactions:order(SecCodeBox, ClassCode, "B", ClientBox, DepoBox, tostring(price), qty)
	elseif dir == 'sell' then
		transactions:order(SecCodeBox, ClassCode, "S", ClientBox, DepoBox, tostring(price), qty)
	end
	
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
--[[
function StartRow(r, c)

	Red(window.hID, r, c)
	SetCell(window.hID, r, c, 'stop')
	window:SetValueByColName(r, 'current_state', 'waiting for a signal')
	
end
--]]

--�����������. ������ � ������ ������ �����������
function startStopRow(row)

	if window:GetValueByColName(row, 'StartStop').image == 'start' then
		helperGrid:Red(window.hID, row, window:GetColNumberByName('StartStop'))

		window:SetValueByColName(row, 'StartStop', 'stop')
		window:SetValueByColName(row, 'current_state', 'waiting for a signal')
		logstoscreen:add2(window, row, nil,nil,nil,nil,'StartStopRow() ���������� ������� � ������')
	else
		helperGrid:Green(window.hID, row, window:GetColNumberByName('StartStop'))
		window:SetValueByColName(row, 'StartStop', 'start')
		window:SetValueByColName(row, 'current_state', 'stopped')
		logstoscreen:add2(window, row, nil,nil,nil,nil,'StartStopRow() ���������� ����������')
		window:SetValueByColName(row, 'LastPrice', tostring(0))
	end
end


--�������, ����������� ����� �������� ������ �� ������
function OnTransReply(trans_reply)

	--�������� ����� ������ � ������� Orders, � ������ � ������� trans_id
	local s = orders:GetSize()
	local rowNum=nil
	for i = 1, s do
		--����� �������� �������� ��� ������ � ������� ������� - row, �.�. � ��������� ���� ������� ���������� ������, �� ����� ������ ������ ������
		--�� ��� �� ����� ���������, �.�. trans_id ������ ���������� ���������� �� ������ ����������� ���� �����
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trans_reply.trans_id) then
			orders:SetValue(i, 'order', trans_reply.order_num)
			--logstoscreen:add2(window, row, nil,nil,nil,nil,'OnTransReply - trans_id '..tostring(orders:GetValue(i, 'trans_id').image))
			rowNum=tonumber(orders:GetValue(i, 'row').image)
			break
		end
	end
	
  logstoscreen:add2(window, rowNum, nil,nil,nil,nil,'OnTransReply '..helper:getMiliSeconds() ..', trans_id = '..tostring(trans_reply.trans_id) .. ', status = ' ..tostring(trans_reply.status))

	if trans_reply.status == 2 or trans_reply.status > 3 then
		logstoscreen:add2(window, rowNum, nil,nil,nil,nil,  'ERROR trans_id = '..tostring(trans_reply.trans_id) .. ', status = ' ..tostring(trans_reply.status) ..', '..helperGrid:StatusByNumber(trans_reply.status) )
		logstoscreen:add2(window, rowNum, nil,nil,nil,nil,  '��������� ��������� � ���������� ������: '.. trans_reply.result_msg)
		
		--��������� ����������, �� �������� ������ ������
		if rowNum~=nil then
			window:SetValueByColName(rowNum, 'StartStop', 'stop')--turn off
			startStopRow(rowNum)
			logstoscreen:add2(window, rowNum, nil,nil,nil,nil,  'instrument was turned off because of the error code '..tostring(trans_reply.status))
		end
	end
	
end 



function OnTrade(trade)

	--���� ������ ��� ���� � ������� ������������, �� ��� ��� �� ���� �� ������������
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
		
	
	
	--������� ���������� �� ������ � ������� qty_fact ������� �������
 
	for i = orders:GetSize(),1,-1 do
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trade.trans_id) 
			and tostring(orders:GetValue(i, 'order').image) == tostring(trade.order_num) then

        logstoscreen:add2(window, i, nil,nil,nil,nil,'OnTrade() '..helper:getMiliSeconds() ..', trans_id = '..tostring(trade.trans_id) .. ', number = ' ..tostring(trade.trade_num).. ', order number = ' ..tostring(trade.order_num))


			orders:SetValue(i, 'trade', trade.trade_num)
			local qty_fact = orders:GetValue(i, 'qty_fact').image
			if qty_fact == nil or qty_fact == '' then
				qty_fact = 0
			else
				qty_fact = tonumber(qty_fact)
			end
			orders:SetValue(i, 'qty_fact', qty_fact + tonumber(trade.qty))
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
	for i = 1, #processed_orders do
		
		if tostring(processed_orders[i]) == tostring(order.order_num) then
			found = true
			break
		end
	end
	if found == true then
		--return
	else
		processed_orders[#processed_orders+1] = order.order_num
	end
	
  for i = orders:GetSize(),1,-1 do
    if tostring(orders:GetValue(i, 'trans_id').image) == tostring(order.trans_id) 
      and tostring(orders:GetValue(i, 'order').image) == tostring(order.order_num) then

        logstoscreen:add2(window, i, nil,nil,nil,nil,'OnOrder() '..helper:getMiliSeconds() ..', trans_id = '..tostring(order.trans_id) .. ', number = ' ..tostring(order.order_num))

      break
    end
  end
	
	
end

local f_cb = function( t_id,  msg,  par1, par2)
	
--f_cb � ������� ��������� ������ ��� ��������� ������� � �������. ���������� �� main()
--(���, ������� �������, ���������� ����� �� ������� ������)
--���������:
--	t_id - ����� �������, ���������� �������� AllocTable()
--	msg - ��� �������, ������������ � �������
--	par1 � par2 � �������� ���������� ������������ ����� ��������� msg, 
--	
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
			buySell_no_trans_id(par1, 'buy')
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('SellMarket') then
			--message('buy')
			buySell_no_trans_id(par1, 'sell')
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('test_buy') then
			--message('buy')
			window:SetValueByColName(par1, 'test_buy', 'true')
			
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('test_sell') then
			--message('buy')
			window:SetValueByColName(par1, 'test_sell', 'true')
			
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
		
		window:SetValueByColName(rowNum, 'Account', 	List[row][7])
		window:SetValueByColName(rowNum, 'Depo', 		List[row][8])
		window:SetValueByColName(rowNum, 'Name', 		List[row][1]) 
		window:SetValueByColName(rowNum, 'Ticker', 		List[row][3]) --��� ������
		window:SetValueByColName(rowNum, 'Class', 		List[row][6]) --����� ������
		window:SetValueByColName(rowNum, 'Lot', 		List[row][4]) --������ ���� ��� ��������
		--����� �������� ����, ���� � ���������� start, �� ����� ��������� ������, � � ���� StartStop ��������� �������� stop
		window:SetValueByColName(rowNum, 'StartStop', 	List[row][9])
		--[[
		if List[row][9] == 'start' then
			window:SetValueByColName(rowNum, 'StartStop', 'stop')
		else
			window:SetValueByColName(rowNum, 'StartStop', 'start')
		end
		--]]
		window:SetValueByColName(rowNum, 'BuyMarket', 'Buy')
		window:SetValueByColName(rowNum, 'SellMarket', 'Sell')
		
		window:SetValueByColName(rowNum, 'MA60name',  	List[row][1] ..'_grid_MA60')
		window:SetValueByColName(rowNum, 'PriceName', 	List[row][1]..'_grid_price')
		
		window:SetValueByColName(rowNum, 'rejim', 		List[row][5])
		
		--����� �������� ����� ������� ���������� ������� GetColNumberByName()
		
		helperGrid:Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		helperGrid:Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
		
		local minStepPrice = getParamEx(List[row][6], 	List[row][3], "SEC_PRICE_STEP").param_value + 0
		window:SetValueByColName(rowNum, 'minStepPrice', tostring(minStepPrice))
		
		
	end  

end




  


--������� ������� ������, ������� �������� � �����
function main()





	if settings.invert_deals == true then
		message('�������� �������������� ������!!!',3)
		logstoscreen:add2(window, nil, nil,nil,nil,nil,'�������� �������������� ������!!!')
	end
	--������� ���� ������ � �������� � ��������� � ��� ������� ������
	window = Window()									--������� Window() ����������� � ����� Window.luac � ������� �����
	
	--{'A','B'} - ��� ������ � ������� �������
	--�������: http://smart-lab.ru/blog/291666.php
	--����� ������� ������, ���������� ����������� � �������� ������� �������� ��� ���������:
	--t = {��������, ��������, ������}
	--��� ��������� ������������ ���������� ����:
	--t = {[1]=��������, [2]=��������, [3]=������}	
	
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

	window:Init(settings.TableCaption, {'current_state','Account','Depo','Name','Ticker','Class', 'Lot', 'Position','sig_dir','LastPrice','BuyMarket','SellMarket','StartStop','MA60Pred','MA60','PricePred','Price','PriceName','MA60name','minStepPrice','rejim','trans_id','signal_id','test_buy','test_sell','qty','savedPosition'}, settings.main_position)
	
	--������� ��������������� �������
---------------------------------------------------------------------------	
	if helperGrid:createTableSignals() == false then
		return
	end

	signals = helperGrid.signals
	
	if settings.signals_position ~= nil then
		if settings.signals_position.x ~= nil and settings.signals_position.y ~= nil and settings.signals_position.dx~=nil and settings.signals_position.dy ~= nil then
			SetWindowPos(signals.t_id, settings.signals_position.x, settings.signals_position.y, settings.signals_position.dx, settings.signals_position.dy)
		end 
	end
---------------------------------------------------------------------------	
	if helperGrid:createTableOrders() == false then
		return
	end	
	
	orders = helperGrid.orders
	
	if settings.orders_position ~= nil then
		if settings.orders_position.x ~= nil and settings.orders_position.y ~= nil and settings.orders_position.dx~=nil and settings.orders_position.dy ~= nil then
			SetWindowPos(orders.t_id, settings.orders_position.x, settings.orders_position.y, settings.orders_position.dx, settings.orders_position.dy)
		end 
	end
	
		
	
	--��������� ���� �������� �����!!!!
	
	--��������� ������ � ������������� � ������� �������
	addRowsToMainWindow()

	
	--���������� ������� ������� �������
	SetTableNotificationCallback (window.hID, f_cb)

	--��������� ��� �������� ��������	
	local col = window:GetColNumberByName('StartStop')
	for row=1, GetTableSize(window.hID) do
		if settings.start_all == true then
			startStopRow(row)
    
		end
	end
	

	
	--�������� 100 ����������� ����� ���������� 
	while is_run do
	
		for row=1, GetTableSize(window.hID) do
			main_loop(row)
		end
		
		sleep(1000)
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
  
	  --[[ �������� ��������� � �������� ����
	  local serv_time=tonumber(HelperGrid:timeformat(getInfoParam("SERVERTIME"))) -- ��������� � ���������� ������� ������� � ������� HHMMSS
	  if not (serv_time>=10000 and serv_time<235000) then
		return false
	  end 	
		--]]
		
	
	if window:GetValueByColName(row, 'StartStop').image =='start'  then --���������� ��������. ����� �������, ��� ����� Stop
		return
	end


	
	local sec = window:GetValueByColName(row, 'Ticker').image
	local class = window:GetValueByColName(row, 'Class').image
	
	security.class = class
	security.code = sec
	security:Update()	--��������� ���� ��������� ������ � ������� security (�������� Last,Close)

	--�������� ���� � ���� ������. ������ ��� ����������� ����������		
	window:SetValueByColName(row, 'LastPrice', tostring(security.last))

	local IdPriceCombo = window:GetValueByColName(row, 'PriceName').image   --������������� ������� ���� ��������� ������ (�������)
	
	--�������� ��������� [1] - ��� http://robostroy.ru/community/article.aspx?id=796
	--[1]������� �� �������� ���������� ������. �����: �� ������� ����
	NumCandles = getNumCandles(IdPriceCombo)	

	if NumCandles==0 then
		return 0
	end

	--���_��� ��� ����������� 2 ������������� �����. ��������� �� �����, �.�. ��� ��� �� ������������
	local tPrice,n,s = getCandlesByIndex(IdPriceCombo,0,NumCandles-3, 2)		
	strategy:SetSeries(tPrice)

	local IdMA = window:GetValueByColName(row, 'MA60name').image
	
	--����� ����� ����������� ���� � ������� moving averages
	local tMA,n,s = getCandlesByIndex(IdMA,0,NumCandles-3, 2)		
	strategy.Ma1Series=tMA	--����� ���� (Ma1Series) ��� � Init, ��� ��������� �����

	--������� ���������� �����

	strategy:CalcLevels() --������� �������� ���� � ������� ����������
	
	--message(IdPriceCombo)
	
	--���� ���������, ����� � ������� �����, � ��� ���� ��� �����������
	--EMA(60, IdPriceCombo)--������������ ������� ���������� (����������������)

	
	
	local acc = window:GetValueByColName(row, 'Account').image
	--��������. ��� ����� ���� �������� ������� �� ������� �������� �������, ����� ���� ��������
	local currency_CETS='USD'

	--��������� ������ � ������� � ���������� ������� ������
	window:SetValueByColName(row, 'Position', tostring(trader:GetCurrentPosition(sec, acc, class, currency_CETS)))
	
	--window:SetValueByColName(row, 'MA60Pred', tostring(EMA_TMP[#EMA_TMP-2]))
	--window:SetValueByColName(row, 'MA60', tostring(EMA_TMP[#EMA_TMP-1]))

	window:SetValueByColName(row, 'MA60Pred', tostring(strategy.Ma1Pred))
	window:SetValueByColName(row, 'MA60', tostring(strategy.Ma1))
	
	window:SetValueByColName(row, 'PricePred', strategy.PriceSeries[0].close)
	window:SetValueByColName(row, 'Price', strategy.PriceSeries[1].close)
	
	--

		
		
	-------------------------------------------------------------------
	--			�������� ��������
	-------------------------------------------------------------------
	local current_state = window:GetValueByColName(row, 'current_state').image
	
	if current_state == 'waiting for a signal' then
		--������� ����� ������� 
		wait_for_signal(row)
		
	elseif current_state == 'processing signal' then
		--� ���� ��������� ����� ���� ������ �� ������, ���� �� ������� ������� ��� �� �������� ����� ��� ���������� �������
		processSignal(row)
		
	elseif current_state == 'waiting for a response' then
		--������ ���������, ���� ���� ������ �����, ����� ��������� �����
		wait_for_response(row)
		
	end

end

--���������� ������
function processSignal(row)
	
	--����� ����������, �� ������� �����/���������� ����� ������� ������� - ��� � ���������� ������ ������ � ������������
	
	local planQuantity = tonumber(window:GetValueByColName(row, 'Lot').image)
	
	local signal_direction = window:GetValueByColName(row, 'sig_dir').image
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'processing signal: '..signal_direction)
	
	if signal_direction == 'sell' then
		planQuantity = -1*planQuantity --������� �������������
	end
	
	
	
	--����������, ������� ��� �����/���������� ���� � ������� (������ ��� ���� ���� ������� ������, ������� - ������� ������� ����������)
	local factQuantity = trader:GetCurrentPosition(window:GetValueByColName(row, 'Ticker').image, window:GetValueByColName(row, 'Account').image, window:GetValueByColName(row, 'Class').image)
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'fact quantity: ' .. tostring(factQuantity))
	
	if window:GetValueByColName(row, 'rejim').image == 'revers' then
		--��� ���������
		
	elseif window:GetValueByColName(row, 'rejim').image == 'long' then
		--������ � ����. ������� ������� ������� � ����
		if signal_direction == 'sell' and factQuantity>=0 then
			planQuantity = 0
		end
		
	elseif window:GetValueByColName(row, 'rejim').image == 'short' then
		--������ � ����. �������� ������� �������� � ����
		if signal_direction == 'buy' and factQuantity<=0 then
			planQuantity = 0
		end
	end
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'plan quantity: ' .. tostring(planQuantity))
	
	local signal_id = window:GetValueByColName(row, 'signal_id').image
	
	--���� ��� �������� ����������, �� �������� ����
	if (signal_direction == 'buy' and factQuantity < planQuantity )
		or (signal_direction == 'sell' and factQuantity > planQuantity)
		then
		
		--������� ������
		local trans_id = helper:getMiliSeconds_trans_id()
		
		window:SetValueByColName(row, 'trans_id', tostring(trans_id))
		
		local qty = planQuantity - factQuantity
		
		if qty == 0 then
			logstoscreen:add2(window, row, nil,nil,nil,nil,'������! qty = 0')
			--��������� � �������� ������ �������
			 
			window:SetValueByColName(row, 'current_state', 'waiting for a signal')
			window:SetValueByColName(row, 'sig_dir', '')
			return
		end
		
		
		
		if signal_direction == 'sell' then --�������� � ��������������
			qty = -1*qty
		end
		
		
		logstoscreen:add2(window, row, nil,nil,nil,nil,'qty: ' .. tostring(qty))
		
		
		--!!!!!!!!!!!!��� �������. ���� ��������� ��� ����� ������������ �������� ������ ������� 
		--qty = 5
		
		
		window:SetValueByColName(row, 'qty', tostring(qty))
		
		--��� ����������� �������� ����� ���������� � ������ �� ��������������� �������
		--������� ��� � �������� �� ����� �������
		helperGrid:addRowToOrders(row, trans_id, signal_id, signal_direction, qty, window) 
		--[[
		local newR = orders:AddLine()
		orders:SetValue(newR, "row", 			row)
		orders:SetValue(newR, "trans_id", 		trans_id)
		orders:SetValue(newR, "signal_id", 		signal_id)
		orders:SetValue(newR, "sig_dir", 		signal_direction)
		orders:SetValue(newR, "qty", 			qty)	--���������� � ������, ����� ����� ���������� � ��� ���������� �� ������� qty_fact
		orders:SetValue(newR, "sec_code", 		window:GetValueByColName(row, 'Ticker').image)
		orders:SetValue(newR, "class_code", 	window:GetValueByColName(row, 'Class').image)
		orders:SetValue(newR, "account", 		window:GetValueByColName(row, 'Account').image)
		orders:SetValue(newR, "depo", 			window:GetValueByColName(row, 'Depo').image)
		--]]
		
		--�������� "������" �������
		window:SetValueByColName(row, 'savedPosition', tostring(factQuantity))
		
		--������������� ������� �������/�������
		buySell(row)
		
		--����� �������� ���������� �� ����� ������ ��������� ������ �� ��, � ������� �� ���� ������ �� ������������ ������
		window:SetValueByColName(row, 'current_state', 'waiting for a response')
		logstoscreen:add2(window, row, nil,nil,nil,nil,'after buySell')

	else
		--logstoscreen:add2(window, row, nil,nil,nil,nil,'��� ������� ��� �������, ������ �� ����������!')
		
		window:SetValueByColName(row, 'current_state', 'waiting for a signal')
		
		--������� ��������� ������� � ������� ��������
		local rows=0
		local cols=0
		rows,cols = signals:GetSize()
		for j = 1 , rows do --� ����� �������� ��������� ���������� � �������
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

--����� ������ �� ������������ ������
function wait_for_response(row)
	--logstoscreen:add2(window, row, nil,nil,nil,nil,'we are waiting the result of sending order')

	---[[
	
	for i = orders:GetSize(),1,-1 do
		
		local trans_id = window:GetValueByColName(row, 'trans_id').image
		
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trans_id)
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
				
				local curPosition = trader:GetCurrentPosition(window:GetValueByColName(row, 'Ticker').image, window:GetValueByColName(row, 'Account').image, window:GetValueByColName(row, 'Class').image)
				local savedPosition = tonumber(window:GetValueByColName(row, 'savedPosition').image)
				
				--��������. ����� �������� ������� ����������� ����������, ����� � ����������� ���� �� ����
				if curPosition ~= savedPosition then
					
					--����������� ��������� ������ �� ������� ����������� - ����� ��������� � ��������� �������, �.�. �������� ������� �������� ���
					window:SetValueByColName(row, 'current_state', 'processing signal')
					window:SetValueByColName(row, 'savedPosition', tostring(curPosition))--���� ��� ����� �� ������, ��� ����� � processSignal() ���������
					
				end
				
			end
		end
	end
	--]]
		
end

--����� ����� �������
function wait_for_signal(row)

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
	local dt=strategy.PriceSeries[1].datetime--���������� �����
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
		
	elseif signal_sell == true	then 
		--�������� �������� ���� ������� - �������
		if settings.invert_deals == false then
			sig_dir='sell'
		else
			sig_dir='buy'
		end
		
	end
	
	window:SetValueByColName(row, 'sig_dir', sig_dir)
	
	--������� � ������� ���, ��������� �����
	local signal_id = helper:getMiliSeconds_trans_id()
	window:SetValueByColName(row, 'signal_id', tostring(signal_id))
	
	--��� ���� � �������� ������� �� ���� ����� �������
	helperGrid:addRowToSignals(row, trans_id, signal_id, sig_dir, window, candle_date, candle_time, strategy.PriceSeries[1].close, strategy.Ma1, false) 
	--[[
	local newR = signals:AddLine()
	signals:SetValue(newR, "row", row)
	signals:SetValue(newR, "id", 	signal_id)
	signals:SetValue(newR, "dir", 	sig_dir)
	
	signals:SetValue(newR, "account", 	window:GetValueByColName(row, 'Account').image)
	signals:SetValue(newR, "depo", 	window:GetValueByColName(row, 'Depo').image)

	signals:SetValue(newR, "sec_code", 	window:GetValueByColName(row, 'Ticker').image)
	signals:SetValue(newR, "class_code", 	window:GetValueByColName(row, 'Class').image)
	
	signals:SetValue(newR, "date", candle_date)
	signals:SetValue(newR, "time", 	candle_time) 
	signals:SetValue(newR, "price", strategy.PriceSeries[1].close)
	--signals:SetValue(newR, "MA", 	EMA_TMP[#EMA_TMP-1])
	signals:SetValue(newR, "price", strategy.Ma1)
	signals:SetValue(newR, "done", false)
	--]]
	
	--��������� � ����� ��������� �������. ������� ��������� ��������� �� ��������� ��������
	window:SetValueByColName(row, 'current_state', 'processing signal')
	
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


function signal_buy(row)

--  Ma1 = Ma1Series[1].close						--���������� �����
--  Ma1Pred = Ma1Series[0].close 	--ENS		--�������������� �����

	--��� ������
    
	if window:GetValueByColName(row, 'test_buy').image == 'true' then
		window:SetValueByColName(row, 'test_buy', 'false')
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
	if EMA_TMP[#EMA_TMP-1]  ~= 0 		--���������� �����
	and EMA_TMP[#EMA_TMP-2]  ~= 0 		--�������������� �����
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
	and strategy.PriceSeries[0].close < EMA_TMP[#EMA_TMP-2] --�������������� ��� ���� �������
	and strategy.PriceSeries[1].close > EMA_TMP[#EMA_TMP-1] --���������� ��� ���� �������
	then
		return true
	else
		return false
	end
--]]	
end





function signal_sell(row)

--  Ma1 = Ma1Series[1].close						--���������� �����
--  Ma1Pred = Ma1Series[0].close 	--ENS		--�������������� �����


	--��� ������
	
	if window:GetValueByColName(row, 'test_sell').image == 'true' then
		window:SetValueByColName(row, 'test_sell', 'false')
		return true
	end
	
	if strategy.Ma1 ~= 0 
	and strategy.Ma1Pred  ~= 0 
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
--	and strategy.PriceSeries[0].close > EMA_TMP[#EMA_TMP-2] --�������������� ��� ���� �������
--	and strategy.PriceSeries[1].close < EMA_TMP[#EMA_TMP-1] --���������� ��� ���� �������
	and strategy.PriceSeries[0].close > strategy.Ma1Pred --�������������� ��� ���� �������
	and strategy.PriceSeries[1].close < strategy.Ma1 --���������� ��� ���� �������
	then
		return true
	else
		return false
	end

end




