--������� ��������
--�������� ���� ���� 60-� ��������� ���������� - ������� � ���������� ������ �� �����
--�������� ���� ���� 60-� ��������� ���������� - ������� � ���������� ������ �� �����

local bit = require"bit"

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
--from examples arqa
dofile (getScriptPath() .. "\\quik_table_wrapper.lua")

--��� ������:
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

local is_run = true	--���� ������ �������, ���� ������ - ������ ��������
local working = false	--���� ����������. ����� �� �������� ���� ����� ���� ��������/��������� ������
local count_animation=0--��������� ����� ��� ����������� �������� � ���� ������,����� ��������,��� �� �������� 
local math_abs = math.abs --����������� ����������� ����������
local math_ceil = math.ceil
local math_floor = math.floor
local signal_direction = ''			--����������� ������� buy/sell
local signals = {} --������� ������������ ��������.	
local orders = {} --������� ������
local trans_id = nil --����� ����� ��������� ����� ����������, �� ����� ������� � ������� orders
local signal_id = nil
--for debug
local test_signal_buy = false -- ����, ���� ������, �� ������� ������� ������ ������. ��� �����
local test_signal_sell = false -- ����, ���� ������, �� ������� ������� ������ ������. ��� �����

local current_state = 'waiting for a signal' --������ ���������, ���� �������
--more options:
--'processing signal' -- �������� ������, ������������, �.�. ���������� ������
--'waiting for a response' --���� ������ � ����� � ���������� ����������� ������. ���� ������ ������, �� ������ ��������� �� 'waiting for a signal'

--���� ������ �������
local EMA_TMP={} --������ ��� �������� �������� ������� ����������, ����������� �������������� �� ������ ����
--����� �������� ����� �������, ������ ����� ����� ������ 0, ��������� #EMA_TMP
local lastCandleMA = nil -- ��������� ����������� �����
--���� ������ ������� �����

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


	logs=Logs()
	logs:Init()

	
	--����� ������ � ������ �������
	security=Security()
	security:Init(settings.ClassCode,settings.SecCodeBox)

	strategy=Strategy()
	strategy:Init()


	transactions=Transactions()
	transactions:Init(settings.ClientBox,settings.DepoBox, settings.SecCodeBox,settings.ClassCode)

	sqlitework = SQLiteWork()
	sqlitework:Init()  
	
  	logstoscreen = LogsToScreen()
	local position = {x=300,y=10,dx=500,dy=400}
	logstoscreen:Init(position) 


  
  db = sqlite3.open(settings.dbpath)
  

end

--���������� ������ "buy �� �����"
function BuyMarket()
    if working  then
      trans:order(settings.SecCodeBox,settings.ClassCode,"B",settings.ClientBox,settings.DepoBox,tostring(security.last+100*security.minStepPrice),settings.LotSizeBox)
	end 
end

--���������� ������ "sell �� �����"
function SellMarket()
	if working then
		trans:order(settings.SecCodeBox,settings.ClassCode,"S",settings.ClientBox,settings.DepoBox,tostring(security.last-100*security.minStepPrice),settings.LotSizeBox)
	end
end

--��� �� ����� �����, � ������ ������� ��� �������!
function OnStart()

	current_state = 'waiting for a signal'
	
	window:InsertValue("�������",tostring(trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox,settings.currency_CETS)))
	settings:Load(trader.Path)
	strategy.LotToTrade=tonumber(settings.LotSizeBox)

	
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
	DestroyTable(signals.t_id)
	DestroyTable(orders.t_id)
end

--�������, ����������� ����� �������� ������ �� ������
function OnTransReply(trans_reply)
	if working == false then
		return
	end
	--message('OnTransReply '..helper:getMiliSeconds())
	logstoscreen:add('OnTransReply '..helper:getMiliSeconds())
	
	local s = orders:GetSize()
	logstoscreen:add('size of orders = '..tostring(s))
	for i = 1, s do
		
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trans_reply.trans_id) then
			orders:SetValue(i, 'order', trans_reply.order_num)
			logstoscreen:add('OnTransReply - trans_id '..tostring(orders:GetValue(i, 'trans_id').image))
			break
		end
	end
	
end 

--�������, ����������� ����� ����������� ������
function OnTrade(trade)
	if working == false then
		return
	end
	
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
		
	
	logstoscreen:add('onTrade '..helper:getMiliSeconds())
	
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
			--logstoscreen:add('OnTrade - trans_id '..tostring(orders:GetValue(i, 'trans_id').image))
			break
		end
	end
	
end

function OnOrder(order)
	if working == false then
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
		return
	else
		processed_orders[#processed_orders+1] = order.order_num
	end
	
	logstoscreen:add('onOrder '..helper:getMiliSeconds())

	
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
	
	x=GetCell(window.hID, par1, par2) 

	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="Buy �� �����" then
			message("Buy",1)
			BuyMarket()
		elseif (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="Sell �� �����" then
			message("Sell",1)
			SellMarket()
		elseif (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="�����" then
			OnStart()
			--message("�����",1)
			window:SetValueWithColor("�����","���������","Red")
			working=true
		elseif (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="TEST BUY" then
			--message("TEST",1)
			TestBuy()
			--window:SetValueWithColor("�����","���������","Red")
			--working=true
		elseif (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="TEST SELL" then
			--message("TEST",1)
			TestSell()
			--window:SetValueWithColor("�����","���������","Red")
			--working=true
		elseif (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="TEST EMA" then
			--message("TEST",1)
			EMA(60)
			--window:SetValueWithColor("�����","���������","Red")
			--working=true
		elseif (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="���������" then
			--message("���������",1)
			window:SetValueWithColor("���������","�����","Green")
			working=false
		end
	end
	
	--������� � ����
	if (msg==QTABLE_CLOSE)  then
		StopScript()
	end

	--������ �� ����������
	if msg==QTABLE_VKEY then
		if par2 == 27 then-- esc
			StopScript()
		end
	end	

end 

--������� ������� ������, ������� �������� � �����
function main()
	
	--strategy.db = db
	
	--������� ������� �������� � ����
	--sqlitework.db = db
	--sqlitework:createTableSignals()
	--������� ������� ������� � ����
	--sqlitework:createTablePositions()
	
	--sqlitework:createTableOrders()
	
	--� ���� ������� ���� ����: rownum | trans_id | signal_id | order_num | robot_id
	--� ��� ����� ������� �� ������ strategy
	--� ����� ��������� order_num �� ������� OnOrder()
	--sqlitework:createTableTransId()

	
	
	--������� ���� ������ � �������� � ��������� � ��� ������� ������
	local position = {x=10,y=10,dx=285,dy=400}
	
	--������� ������� ���� ������
	create_window(position)
	
	SetTableNotificationCallback (window.hID, f_cb)

	
	strategy.logstoscreen = logstoscreen  --��� ����� 
	
	strategy.secCode = sec --ENS ��� ������� --����� ������ ��� �����?
	
	
	
	
---------------------------------------------------------------------------	
	if createTableSignals() == false then
		return
	end

	SetWindowPos(signals.t_id, 810, 10, 600, 200)

---------------------------------------------------------------------------	
	if createTableOrders() == false then
		return
	end
	
	SetWindowPos(orders.t_id, 810, 220, 600, 200)
	
	--�������� 100 ����������� ����� ���������� 
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

function createTableSignals()
	
	signals = QTable.new()
	if not signals then
		message("error creation table Signals!", 3)
		return false
	else
		--message("table with id = " ..signals.t_id .. " created", 1)
	end

	signals:AddColumn("id", QTABLE_INT_TYPE, 10)
	signals:AddColumn("dir", QTABLE_STRING_TYPE, 4)
	signals:AddColumn("account", QTABLE_STRING_TYPE, 10)
	signals:AddColumn("depo", QTABLE_STRING_TYPE, 10)
	signals:AddColumn("sec_code", QTABLE_STRING_TYPE, 10)
	signals:AddColumn("class_code", QTABLE_STRING_TYPE, 10)
	signals:AddColumn("date", QTABLE_CACHED_STRING_TYPE, 10) --����� �����, �� ������� ������������� ������
	signals:AddColumn("time", QTABLE_CACHED_STRING_TYPE, 10) --����� �����, �� ������� ������������� ������
	signals:AddColumn("price", QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("MA", QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("done", QTABLE_STRING_TYPE, 10)
	
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
	
	orders:AddColumn("signal_id", QTABLE_INT_TYPE, 10)
	orders:AddColumn("account", QTABLE_STRING_TYPE, 10)
	orders:AddColumn("depo", QTABLE_STRING_TYPE, 10)
	orders:AddColumn("sec_code", QTABLE_STRING_TYPE, 10)
	orders:AddColumn("class_code", QTABLE_STRING_TYPE, 10)
	orders:AddColumn("trans_id", QTABLE_INT_TYPE, 10)
	orders:AddColumn("order", QTABLE_INT_TYPE, 10)
	orders:AddColumn("trade", QTABLE_INT_TYPE, 10)
	
	orders:AddColumn("qty", QTABLE_INT_TYPE, 10) --���������� �� ������
	orders:AddColumn("qty_fact", QTABLE_INT_TYPE, 10) --���������� �� ������
	
	orders:SetCaption("orders")
	orders:Show()
	
	return true
	
end

function create_window(position)

	
	--������� ���� ������ � �������� � ��������� � ��� ������� ������
	window = Window()									--������� Window() ����������� � ����� Window.luac � ������� �����
	
	--{'A','B'} - ��� ������ � ������� �������
	--�������: http://smart-lab.ru/blog/291666.php
	--����� ������� ������, ���������� ����������� � �������� ������� �������� ��� ���������:
	--t = {��������, ��������, ������}
	--��� ��������� ������������ ���������� ����:
	--t = {[1]=��������, [2]=��������, [3]=������}	
	
	--window:Init("ENS MovingAverages", {'A','B'})	--�������� ����� init ������ window
	window:Init(settings.TableCaption, {'A','B'}, position)	--�������� ����� init ������ window
	window:AddRow({"���","����"},"")
	window:AddRow({settings.SecCodeBox,"0"},"Grey")
	
	window:AddRow({"Lot to trade",""},"")
	window:AddRow({settings.LotSizeBox,"0"},"Grey")
	
	
	window:AddRow({"�������",""},"")
	window:AddRow({"",""},"Grey")
	
	window:AddRow({"MA (60)","Close"},"")
	window:AddRow({"",""},"Grey")
	
	window:AddRow({"MA pred (60)","PredClose"},"")
	window:AddRow({"",""},"Grey")

	window:AddRow({"������",""},"")
	window:AddRow({"",""},"Grey")
	
	window:AddRow({"",""},"")
	window:AddRow({"Buy �� �����",""},"Green")
	window:AddRow({"Sell �� �����",""},"Red")
	window:AddRow({"",""},"")
	window:AddRow({"�����",""},"Green")
	
	window:AddRow({"TEST BUY",""},"Grey")
	window:AddRow({"TEST SELL",""},"Grey")
	window:AddRow({"TEST EMA",""},"Grey")
	

end

--+-----------------------------------------------
--|			�������� ��������
--+-----------------------------------------------

--��� ������� ������ ���������� �� ������������ ����� � ������� main()
function main_loop()

	if isConnected() == 0 then
		window:InsertValue("������", "Not connected")
		return
	end
	
	security:Update()	--��������� ���� ��������� ������ � ������� security (�������� Last,Close)

	window:InsertValue("����",tostring(security.last)) --�������� ���� � ���� ������. ������ ��� ����������� ����������		

	--�������� ��������� [1] - ��� http://robostroy.ru/community/article.aspx?id=796
	--[1]������� �� �������� ���������� ������. �����: �� ������� ����
	NumCandles = getNumCandles(settings.IdPriceCombo)	

	if NumCandles==0 then
		return 0
	end

	--���_��� ��� ����������� 2 ������������� �����. ��������� �� �����, �.�. ��� ��� �� ������������
	tPrice,n,s = getCandlesByIndex(settings.IdPriceCombo,0,NumCandles-3, 2)		
	strategy:SetSeries(tPrice)

	--����� ����� ����������� ���� � ������� moving averages
	--tPrice,n,s = getCandlesByIndex(settings.IdMA,0,NumCandles-3, 2)		
	--strategy.Ma1Series=tPrice	--����� ���� (Ma1Series) ��� � Init, ��� ��������� �����

	--������� ���������� �����

	--strategy:CalcLevels() --������� �������� ���� � ������� ����������
	
	EMA(settings.MAPeriod)--������������ ������� ���������� (����������������)

	
	--��������� ������ � ���������� ������� ������
	window:InsertValue("�������",tostring(trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox,settings.currency_CETS)))
	
	--window:InsertValue("MA (60)",tostring(strategy.Ma1))
	window:InsertValue("MA (60)",tostring(EMA_TMP[#EMA_TMP-1]))
	window:InsertValue("Close",tostring(strategy.PriceSeries[1].close))
	
	--window:InsertValue("MA pred (60)",tostring(strategy.Ma1Pred))
	window:InsertValue("MA pred (60)",tostring(EMA_TMP[#EMA_TMP-2]))
	window:InsertValue("PredClose",tostring(strategy.PriceSeries[0].close))
	
	
	if working==false  then
		return
	end
		
		
	-------------------------------------------------------------------
	--			�������� ��������
	-------------------------------------------------------------------
	
	if current_state == 'waiting for a signal' then
		--������� ����� ������� 
		wait_for_signal()
		
	elseif current_state == 'processing signal' then
		--� ���� ��������� ����� ���� ������ �� ������, ���� �� ������� ������� ��� �� �������� ����� ��� ���������� �������
		processSignal()
		
	elseif current_state == 'waiting for a response' then
		--������ ���������, ���� ���� ������ �����, ����� ��������� �����
		wait_for_response()
		
	end

end

--���������� ������
function processSignal()
	
	logstoscreen:add('processing signal: '..signal_direction)
	
	--����� ����������, �� ������� �����/���������� ����� ������� ������� - ��� � ���������� ������
	local planQuantity = tonumber(settings.LotSizeBox)
	if signal_direction == 'sell' then
		planQuantity = -1*planQuantity --������� �������������
	end
	logstoscreen:add('plan quantity: ' .. tostring(planQuantity))
	
	--����������, ������� ��� �����/���������� ���� � ������� (� ������� �� ����� ������)
	local factQuantity = trader:GetCurrentPosition(settings.SecCodeBox, settings.ClientBox, settings.currency_CETS)
	logstoscreen:add('fact quantity: ' .. tostring(factQuantity))
	
	if settings.rejim == 'revers' then
		--��� ���������
		
	elseif settings.rejim == 'long' then
		--������ � ����. ������� ������� ������� � ����
		if signal_direction == 'sell' and factQuantity>=0 then
			planQuantity = 0
		end
		
	elseif settings.rejim == 'short' then
		--������ � ����. �������� ������� �������� � ����
		if signal_direction == 'buy' and factQuantity<=0 then
			planQuantity = 0
		end
	end
	
	--���� ��� �������� ����������, �� �������� ����
	if (signal_direction == 'buy' and factQuantity < planQuantity )
		or (signal_direction == 'sell' and factQuantity > planQuantity)
		then
		
		--������� ������
		
		trans_id = helper:getMiliSeconds_trans_id() --���������� ��� ������� ����������
		
		local qty = planQuantity - factQuantity
		
		if qty == 0 then
			logstoscreen:add('������! qty = 0')
			--��������� � �������� ������ �������
			current_state = 'waiting for a signal'
			return
		end
		
		logstoscreen:add('qty: ' .. tostring(qty))
		
		if signal_direction == 'sell' then --�������� � ��������������
			qty = -1*qty
		end
		
		
		--!!!!!!!!!!!!��� �������. ���� ��������� ��� ����� ������������ �������� ������ ������� 
		--qty = 5
		
		local row = orders:AddLine()
		orders:SetValue(row, "trans_id", trans_id)
		orders:SetValue(row, "signal_id", signal_id)
		orders:SetValue(row, "qty", qty)
		
		if signal_direction == 'buy' then
			Buy(qty, trans_id)
		elseif signal_direction == 'sell' then
			Sell(qty, trans_id)
		end
		
		--�������� ����, ������� ����, ��� ����� ���� ������ �� ������������ ������
		--���� ���������� � ������� OnTrade()
		--we_are_waiting_result = true
		current_state = 'waiting for a response'

	else
		logstoscreen:add('��� ������� ��� �������, ������ �� ����������!')
		
		current_state = 'waiting for a signal'
		
		--������� ��������� ������� � ������� ��������
		local rows=0
		local cols=0
		rows,cols = signals:GetSize()
		for j = 1 , rows do --� ����� �������� ��������� ���������� � �������
			if tostring(signal_id) == tostring(signals:GetValue(j, "id").image) then
			
				signals:SetValue(j, "done", true) 
				break
			end
		end		
		
		signal_id = nil
		trans_id = nil
	end
	
end

--����� ������ �� ������������ ������
function wait_for_response()
	logstoscreen:add('we are waiting the result of sending order')

	local s = orders:GetSize()
	for i = 1, s do
		
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trans_id) then
			
			if orders:GetValue(i, 'trade')~=nil and( orders:GetValue(i, 'trade').image~='0' or orders:GetValue(i, 'trade').image~='') then
				--���� � ������� orders �������� ����� ������, ��� ������ ��� ������ ������������.
				
				--� ��� � �� ����. ����� �������� ���������� � ������ � � ������. ���� ������ ��������� �������������, �� ������ ����� ��� ������, ��� ��� ������������
				--���� ��� ������� � 10 ����� �������� ����� ������� ����� ���������...
				
				--���� �� ����� ������������ �� ���. ������ ������ � ���
				local qty_fact = orders:GetValue(i, 'qty_fact').image
				if qty_fact == nil or qty_fact == '' then
					qty_fact = 0
				else
					qty_fact = tonumber(qty_fact)
				end
			
				if tonumber(orders:GetValue(i, 'qty').image) == qty_fact then
					
					logstoscreen:add('order '..orders:GetValue(i, 'order').image..': qty = qty_fact - order is processed')
					
				end
				
				logstoscreen:add('order '..orders:GetValue(i, 'order').image..' processed')
				
				current_state = 'processing signal'
				
			
			end
		end
	end
		
end

--����� ����� �������
function wait_for_signal()

	--����� ������ ���, ������� ��������� ������� � ����������, ����� �������� � �����������
	--��� ����, ����� ������� ���� �������� - ����� ���������� �������� ����, ������� ������� ���������� ������, � ����� ���� ��������� ����
	--�.�. ����� ������ ���� ������� ������� ������� � ������ ����� �� ���������
	local signal_buy =  signal_buy()
	local signal_sell =  signal_sell()
	
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
	if find_signal(candle_date, candle_time) == true then
		return
	end
		
	--logstoscreen:add('we have got a signal: ')
	
	if signal_buy == true then 
		--�������� ����� ���� ������� - �������
		signal_direction = 'buy'
	elseif signal_sell == true	then 
		--�������� �������� ���� ������� - �������
		signal_direction = 'sell'
	end
	
	--������� � ������� ���, ��������� �����
	
	signal_id = helper:getMiliSeconds_trans_id()
	
	local row = signals:AddLine()
	signals:SetValue(row, "id", 	signal_id)
	signals:SetValue(row, "dir", 	signal_direction)
	signals:SetValue(row, "date", candle_date)
	signals:SetValue(row, "time", 	candle_time) 
	signals:SetValue(row, "price", strategy.PriceSeries[1].close)
	signals:SetValue(row, "MA", 	EMA_TMP[#EMA_TMP-1])
	signals:SetValue(row, "done", false)
	
	--��������� � ����� ��������� �������. ������� ��������� ��������� �� ��������� ��������
	current_state = 'processing signal'

end

--[[���� ������ � ������� ��������. ���������� ��� ����������� ������ �������.
������ ����� ��������� ��� ��������� ����� ����� ������������, �������� ���������� ���������� ������� ����
�.�. ����� �� �������� � ������ ������������ ����� �����, �� ��� ����� ��������� ��� ��������� �����--]]
function find_signal(candle_date, candle_time)
	local rows=0
	local cols=0
	rows,cols = signals:GetSize()
	for i = 1 , rows do --� ����� �������� ��������� ���������� � �������
		if signals:GetValue(i, "date").image == candle_date and
			signals:GetValue(i, "time").image == candle_time then
			--��� ���� ������, �������� ������������ �� ����
			--logstoscreen:add('the signal is already processed: '..tostring(signals:GetValue(i, "id").image))
			return true
		end
	end
	return false
end
--+-----------------------------------------------
--|			�������� �������� - �����
--+-----------------------------------------------


function animation()
	  
	if working==false then
		return false
	end
	
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
	window:InsertValue("������", symb)
end




function signal_buy()

--  Ma1 = Ma1Series[1].close						--���������� �����
--  Ma1Pred = Ma1Series[0].close 	--ENS		--�������������� �����

	--��� ������
	if working == true then
		if test_signal_buy == true then
			test_signal_buy = false
			return true
		end
	end
	
	--[[
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
end

function signal_sell()

--  Ma1 = Ma1Series[1].close						--���������� �����
--  Ma1Pred = Ma1Series[0].close 	--ENS		--�������������� �����


	--��� ������
	if working == true then
		if test_signal_sell == true then
			test_signal_sell = false
			return true
		end
	end
	
	if EMA_TMP[#EMA_TMP-1]  ~= 0 		--���������� �����
	and EMA_TMP[#EMA_TMP-2]  ~= 0 		--�������������� �����
--	if strategy.Ma1 ~= 0 
--	and strategy.Ma1Pred  ~= 0 
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
	and strategy.PriceSeries[0].close > EMA_TMP[#EMA_TMP-2] --�������������� ��� ���� �������
	and strategy.PriceSeries[1].close < EMA_TMP[#EMA_TMP-1] --���������� ��� ���� �������
--	and strategy.PriceSeries[0].close > strategy.Ma1Pred --�������������� ��� ���� �������
--	and strategy.PriceSeries[1].close < strategy.Ma1 --���������� ��� ���� �������
	then
		return true
	else
		return false
	end

end



--
function Buy(LotToTrade, trans_id)
	logstoscreen:add("Buy " .. settings.SecCodeBox)
	--transactions:order(settings.SecCodeBox, settings.ClassCode, "B", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) + 60 * security.minStepPrice), LotToTrade)
	transactions:orderWithId(settings.SecCodeBox, settings.ClassCode, "B", settings.ClientBox, tostring(settings.DepoBox), tostring(tonumber(security.last) + 150 * security.minStepPrice), LotToTrade, trans_id)
	logstoscreen:add("transaction was sent "..helper:getMiliSeconds())
end

--���������� �� ����� �� �����. Strategy:DoBisness()
function Sell(LotToTrade, trans_id)
	logstoscreen:add("Sell " .. settings.SecCodeBox)
	--transactions:order        (settings.SecCodeBox, settings.ClassCode, "S", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) - 60 * security.minStepPrice), LotToTrade)
	transactions:orderWithId(settings.SecCodeBox, settings.ClassCode, "S", settings.ClientBox, tostring(settings.DepoBox), tostring(tonumber(security.last) - 150 * security.minStepPrice), LotToTrade, trans_id)
	logstoscreen:add("transaction was sent "..helper:getMiliSeconds())
end




--��������� ���� ���������. ������ ��������� ������, � ��������� ������� DoBusiness
function TestBuy()

	--�������� ����. �������� ��� ����� � ������� signal_buy()
	test_signal_buy = true
	
end

--��������� ���� ���������. ������ ��������� ������, � ��������� ������� DoBusiness
function TestSell()

	--�������� ����. �������� ��� ����� � ������� signal_sell()
	test_signal_sell = true
	
end


--���� ������ ������� ���������� (����� �������� ������ ������� ������, �� ����� ��������� �� ������� ��� ��������� ���, � ��������� ��� ����)

--N - ������ ������� (���������� ������)
--lastCandle - ��������� ������������ ����� (����� �� ������� ��� � ���� �� ������ ������)
function EMA(N)

	--[1]������� �� �������� ���������� ������. �����: �� ������� ����
	local NumCandles = getNumCandles(settings.IdPriceCombo)	

--[[
� ������� � ����� ���� �������: 
EMAi = (EMAi-1 * (n-1) + 2*Pi) / (n+1), 
��� Pi - �������� ���� � ������� �������, 
EMAi - �������� EMA �������� �������, 
EMAi-1 - �������� EMA ����������� ������� 
��������� �������� ����� ���������, �� �������� �������������� ���������: EMA0=P0 � ��� ������� �� ���� 
--]]
	local tPrice = {}
	local n = 0
	local s = ''
	tPrice,n,s = getCandlesByIndex(settings.IdPriceCombo,0,0,NumCandles)		
	
	--������ ������ �� �������
	--tPrice[number].datetime.hour
	--PriceSeries[0].close
	
	local answ = 0
	
	local idp = 11 --�������� ���������� (������ ����� �����)
	local start = 0
	if lastCandleMA == nil then
		start = 0
	else
		start = lastCandleMA
	end
	for i = start, n-1 do
	
		fEMA(i, N, tPrice, idp)
		
	end
	
	lastCandleMA = n-1
	
end

--[[Exponential Moving Average (EMA)
EMAi = (EMAi-1*(n-1)+2*Pi) / (n+1)
]]
--ds - DataSource - ������� ������
--idp - �������� ����������
function fEMA(Index, Period, ds, idp) 
	
	--logstoscreen:add('candle '..tostring(Index)..' close = '..tostring(ds[Index].close))
	local Out = 0
	if Index == 0 then
		EMA_TMP[Index]=round(ds[Index].close,idp)
		--logstoscreen:add('index = 0 and EMA = '..tostring(EMA_TMP[Index]))
	else
		local prev_ema = EMA_TMP[(Index-1)]
		local candle = ds[Index]
		EMA_TMP[Index]=round((prev_ema*(Period-1)+2*candle.close) / (Period+1),idp)
	end

	if Index >= Period-1 then -- ����� 1 - ������ ��� ���� �� ����
		Out = EMA_TMP[Index]
		--logstoscreen:add('Index '..tostring(Index)..' EMA = '..tostring(EMA_TMP[Index]))
	end

	return round(Out,idp)
	
end

------------------------------------------------------------------
--��������������� ������� ��� EMA
------------------------------------------------------------------
function round(num, idp)
if idp and num then
   local mult = 10^(idp or 0)
   if num >= 0 then return math_floor(num * mult + 0.5) / mult
   else return math_ceil(num * mult - 0.5) / mult end
else return num end
end


