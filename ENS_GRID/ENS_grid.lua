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
--dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Security.lua") --���� ����� ������������� ��� ������� ������
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\logs.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\logstoscreen.lua")

--common within one strategy
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Strategies\\StrategyOLE.lua")

--private for each robot
dofile (getScriptPath().."\\Classes\\SettingsGRID.lua")
dofile (getScriptPath().."\\Classes\\Security.lua")--���� ����� ������������� ��� ������� ������

dofile (getScriptPath() .. "\\quik_table_wrapper.lua")

--��� �������:
trader ={}
trans={}
helper={}
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
	transactions:Init()
	
  	logstoscreen = LogsToScreen()
	local position = {x=810,y=420,dx=700,dy=300}
	local extended = true--���� ����������� ������� ����
	logstoscreen:Init(position, extended) 	
end

--��� �� ���������� �������, � ������ ������� �������/�������
function BuySell(row)

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
	
	local minStepPrice = tonumber(window:GetValueByColName(row, 'minStepPrice').image)
    
    if dir == 'buy' then
		transactions:orderWithId(SecCodeBox, ClassCode, "B", ClientBox, DepoBox, tostring(tonumber(security.last) + 150 * minStepPrice), qty, trans_id)
	elseif dir == 'sell' then
		transactions:orderWithId(SecCodeBox, ClassCode, "S", ClientBox, DepoBox, tostring(tonumber(security.last) - 150 * minStepPrice), qty, trans_id)
	end
	
	--�������, �.�. ��� �������� ��������
	window:SetValueByColName(row, 'qty', tostring(0))
	
end



--���������� ��������� �� ������ Buy. �.�. ������ �������/������� �� �����
function BuySell_no_trans_id(row, dir)

	local SecCodeBox 	= window:GetValueByColName(row, 'Ticker').image
	local ClassCode 	= window:GetValueByColName(row, 'Class').image
	local ClientBox 	= window:GetValueByColName(row, 'Account').image
	local DepoBox 		= window:GetValueByColName(row, 'Depo').image
	local qty 			= window:GetValueByColName(row, 'Lot').image
	
	security.class = ClassCode
	security.code = SecCodeBox
	security:Update()
	
	local minStepPrice = tonumber(window:GetValueByColName(row, 'minStepPrice').image)
    if dir == 'buy' then
		transactions:order(SecCodeBox, ClassCode, "B", ClientBox, DepoBox, tostring(tonumber(security.last) + 150 * minStepPrice), qty)
	elseif dir == 'sell' then
		transactions:order(SecCodeBox, ClassCode, "S", ClientBox, DepoBox, tostring(tonumber(security.last) - 150 * minStepPrice), qty)
	end
	
end


--������
function OnStop(s)

	StopScript()
	
end 

--��������� ���� � ��������� ���� ������ �������
function StopScript()

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
function StartStopRow(row)

	local col = window:GetColNumberByName('StartStop')
	if window:GetValueByColName(row, 'StartStop').image == 'start' then
		Red(window.hID, row, col)
		SetCell(window.hID, row, col, 'stop')
		window:SetValueByColName(row, 'current_state', 'waiting for a signal')
	else
		Green(window.hID, row, col)
		SetCell(window.hID, row, col, 'start')
		window:SetValueByColName(row, 'current_state', '')
	end
end


--�������, ����������� ����� �������� ������ �� ������
function OnTransReply(trans_reply)

	--logstoscreen:add2(window, row, nil,nil,nil,nil,'OnTransReply '..helper:getMiliSeconds())

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
	
	if trans_reply.status > 3 then
		logstoscreen:add2(window, row, nil,nil,nil,nil,'error ticker '..window:GetValueByColName(rowNum, 'Ticker').image .. ': '..tostring(trans_reply.status))
		message('error ticker '..window:GetValueByColName(rowNum, 'Ticker').image .. ': '..tostring(trans_reply.status))
		
		--��������� ����������, �� �������� ������ ������
		if rowNum~=nil then
			window:SetValueByColName(rowNum, 'StartStop', 'start')--turn off
			window:SetValueByColName(rowNum, 'current_state', '')--turn off
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
		
	
	--logstoscreen:add2(window, row, nil,nil,nil,nil,'onTrade '..helper:getMiliSeconds())
	
	--������� ���������� �� ������ � ������� qty_fact ������� �������
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
			--logstoscreen:add2(window, row, nil,nil,nil,nil,'OnTrade - trans_id '..tostring(orders:GetValue(i, 'trans_id').image))
			break
		end
	end
	
end

function OnOrder(order)
	
	--���� ������ ��� ���� � ������� ������������, �� ��� ��� �� ���� �� ������������
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
	
	--logstoscreen:add2(window, row, nil,nil,nil,nil,'onOrder '..helper:getMiliSeconds())

	
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
				StartStopRow(par1)
				
			else
				--Stop but not closed
				StartStopRow(par1)
				--[[
				Green(window.hID, par1, par2)
				SetCell(window.hID, par1, par2, 'start')
				window:SetValueByColName(par1, 'current_state', nil)
				--]]
			end
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('BuyMarket') then
			--message('buy')
			BuySell_no_trans_id(par1, 'buy')
		elseif (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('SellMarket') then
			--message('buy')
			BuySell_no_trans_id(par1, 'sell')
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
		StopScript()
	end

	--�������� ���� ������ ������� ESC
	if msg==QTABLE_VKEY then
		--message(par2)
		if par2 == 27 then-- esc
			--window:Close()
			--is_run=false
			--working = false
			StopScript()
		end
	end	

end 

--������ �� �������� ������� ������������ � ��������� ������ � ���� � ������� �������
function AddRowsToMainWindow()

	local List = settings:instruments_list() --��� ��������� ������ (�������)
	
	--��������� ������ � ������������� � ������� ������
	for row=1, #List do
		
		rowNum = InsertRow(window.hID, -1)
		
		window:SetValueByColName(rowNum, 'Account', List[row][7])
		window:SetValueByColName(rowNum, 'Depo', List[row][8])
		window:SetValueByColName(rowNum, 'Name', List[row][1]) 
		window:SetValueByColName(rowNum, 'Ticker', List[row][3]) --��� ������
		window:SetValueByColName(rowNum, 'Class', List[row][6]) --����� ������
		window:SetValueByColName(rowNum, 'Lot', List[row][4]) --������ ���� ��� ��������
		--����� �������� ����, ���� � ���������� start, �� ����� ��������� ������, � � ���� StartStop ��������� �������� stop
		window:SetValueByColName(rowNum, 'StartStop', List[row][9])
		--[[
		if List[row][9] == 'start' then
			window:SetValueByColName(rowNum, 'StartStop', 'stop')
		else
			window:SetValueByColName(rowNum, 'StartStop', 'start')
		end
		--]]
		window:SetValueByColName(rowNum, 'BuyMarket', 'Buy')
		window:SetValueByColName(rowNum, 'SellMarket', 'Sell')
		
		window:SetValueByColName(rowNum, 'MA60name',  List[row][1] ..'_grid_MA60')
		window:SetValueByColName(rowNum, 'PriceName', List[row][1]..'_grid_price')
		
		window:SetValueByColName(rowNum, 'rejim', List[row][5])
		
		--����� �������� ����� ������� ���������� ������� GetColNumberByName()
		Green(window.hID, rowNum, window:GetColNumberByName('StartStop')) 
		Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
		
		local minStepPrice = getParamEx(List[row][6], List[row][3], "SEC_PRICE_STEP").param_value + 0
		window:SetValueByColName(rowNum, 'minStepPrice', tostring(minStepPrice))
		
	end  

end

--������� ������� ������, ������� �������� � �����
function main()

	if settings.invert_deals == true then
		message('�������� �������������� ������!!! ��� ������� � ���� ������ ��-��������� ���������!',3)
		logstoscreen:add2(window, nil, nil,nil,nil,nil,'�������� �������������� ������!!! ��� ������� ���������!')
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
	local position = {x=50,y=105,dx=1300,dy=400}
	window:Init(settings.TableCaption, {'current_state','Account','Depo','Name','Ticker','Class', 'Lot', 'Position','sig_dir','LastPrice','BuyMarket','SellMarket','StartStop','MA60Pred','MA60','PricePred','Price','PriceName','MA60name','minStepPrice','rejim','trans_id','signal_id','test_buy','test_sell','qty','savedPosition'}, position)
	
	--������� ��������������� �������
---------------------------------------------------------------------------	
	if createTableSignals() == false then
		return
	end

	SetWindowPos(signals.t_id, 810, 10, 700, 200)

---------------------------------------------------------------------------	
	if createTableOrders() == false then
		return
	end	
	
	SetWindowPos(orders.t_id, 810, 210, 700, 200)
	
		
	
	--��������� ���� �������� �����!!!!
	
	--��������  (�������, ������, ������)
	
	AddRowsToMainWindow()

	
	--���������� ������� ������� �������
	SetTableNotificationCallback (window.hID, f_cb)

	--��������� ��� �������� ��������	
	local col = window:GetColNumberByName('StartStop')
	for row=1, GetTableSize(window.hID) do
		if settings.invert_deals == true then
			window:SetValueByColName(row, 'StartStop', 'stop')
		end
		StartStopRow(row)
		--[[
		if window:GetValueByColName(row, 'StartStop').image == 'start' then
			StartRow(row, col)
		else
			window:SetValueByColName(row, 'StartStop', 'start')
		end
		--]]
	end
	

	
	--�������� 100 ����������� ����� ���������� 
	while is_run do
	
		for row=1, GetTableSize(window.hID) do
			main_loop(row)
		end
		
		sleep(1000)
	end

end

--- ������� �� ��������� �����/����� �������
function Red(t_id, Line, Col)    -- �������
   -- ���� ������ ������� �� ������, ���������� ��� ������
   if Col == nil then Col = QTABLE_NO_INDEX; end;
   SetColor(t_id, Line, Col, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0));
end;

function Gray(Line, Col)   -- �����
   -- ���� ������ ������� �� ������, ���������� ��� ������
   if Col == nil then Col = QTABLE_NO_INDEX; end;
   SetColor(t_id, Line, Col, RGB(200,200,200), RGB(0,0,0), RGB(200,200,200), RGB(0,0,0));
end;

function Green(t_id, Line, Col)  -- �������
   -- ���� ������ ������� �� ������, ���������� ��� ������
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

	signals:AddColumn("row", 		QTABLE_INT_TYPE, 5) --����� ������ � ������� �������. ������� ����!!!
	signals:AddColumn("id", 		QTABLE_INT_TYPE, 10)
	signals:AddColumn("dir", 		QTABLE_CACHED_STRING_TYPE, 4)
	signals:AddColumn("account", QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("depo", 	QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("sec_code", QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("class_code", QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("date", 	QTABLE_CACHED_STRING_TYPE, 10) --����� �����, �� ������� ������������� ������
	signals:AddColumn("time", 		QTABLE_CACHED_STRING_TYPE, 10) --����� �����, �� ������� ������������� ������
	signals:AddColumn("price", 	QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("MA",		QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("done", 	QTABLE_STRING_TYPE, 10)
	
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
	
	orders:AddColumn("row", 			QTABLE_INT_TYPE, 5) --����� ������ � ������� �������. ������� ����!!!
	orders:AddColumn("signal_id", 	QTABLE_INT_TYPE, 10)
	orders:AddColumn("sig_dir", 		QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("account", 	QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("depo", 			QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("sec_code", 	QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("class_code", QTABLE_CACHED_STRING_TYPE, 10)
	orders:AddColumn("trans_id", 	QTABLE_INT_TYPE, 10)
	orders:AddColumn("order", 		QTABLE_INT_TYPE, 10)
	orders:AddColumn("trade", 		QTABLE_INT_TYPE, 10)
	orders:AddColumn("qty", 			QTABLE_INT_TYPE, 10) --���������� �� ������
	orders:AddColumn("qty_fact", 	QTABLE_INT_TYPE, 10) --���������� �� ������
	
	orders:SetCaption("orders")
	orders:Show()
	
	return true
	
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
	
	local sec = window:GetValueByColName(row, 'Ticker').image
	local class = window:GetValueByColName(row, 'Class').image
	
	security.code = sec
	security.class = class	
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
	
	local working = window:GetValueByColName(row, 'StartStop').image 
	
	if working=='start'  then --���������� ��������. ����� �������, ��� ����� Stop
		return
	end
		
		
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
	
	logstoscreen:add2(window, row, nil,nil,nil,nil,'plan quantity: ' .. tostring(planQuantity))
	
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
		local newR = orders:AddLine()
		orders:SetValue(newR, "row", 			row)
		orders:SetValue(newR, "trans_id", 		trans_id)
		orders:SetValue(newR, "signal_id", 		signal_id)
		orders:SetValue(newR, "sig_dir", 		signal_direction)
		orders:SetValue(newR, "qty", 			qty)	--���������� � ������, ����� ����� ���������� � ��� ���������� �� ������� qty_fact
		orders:SetValue(newR, "sec_code", 	window:GetValueByColName(row, 'Ticker').image)
		orders:SetValue(newR, "class_code", 	window:GetValueByColName(row, 'Class').image)
		orders:SetValue(newR, "account", 		window:GetValueByColName(row, 'Account').image)
		orders:SetValue(newR, "depo", 			window:GetValueByColName(row, 'Depo').image)
		
		--�������� "������" �������
		window:SetValueByColName(row, 'savedPosition', tostring(factQuantity))
		
		--������������� ������� �������/�������
		BuySell(row)
		
		--����� �������� ���������� �� ����� ������ ��������� ������ �� ��, � ������� �� ���� ������ �� ������������ ������
		window:SetValueByColName(row, 'current_state', 'waiting for a response')

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
	
	local s = orders:GetSize()
	for i = 1, s do
		
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
	
	--��������� � ����� ��������� �������. ������� ��������� ��������� �� ��������� ��������
	window:SetValueByColName(row, 'current_state', 'processing signal')
	
end

--[[���� ������ � ������� ��������. ���������� ��� ����������� ������ �������.
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

