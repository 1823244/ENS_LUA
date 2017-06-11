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
local new_signal = false --��� ���������� ���� ���������. ����� ������ - ����� ���� ��������� ������ �������
local we_are_waiting_result = false
local signal_direction = ''			--����������� ������� buy/sell
local state_process_signal = false
local signals = nil --������� ������������ ��������.	
local orders = nil --������� ������
local trans_id = nil --����� ����� ��������� ����� ����������, �� ����� ������� � ������� orders
local signal_id = nil
--for debug
local test_signal_buy = false -- ����, ���� ������, �� ������� ������� ������ ������. ��� �����
local test_signal_sell = false -- ����, ���� ������, �� ������� ������� ������ ������. ��� �����


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

	window:InsertValue("�������",tostring(trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox)))
	settings:Load(trader.Path)
	strategy.LotToTrade=tonumber(settings.LotSizeBox)

	--��������� ��������, �� ��������� ��������� ���������� �����������
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
	DestroyTable(signals.t_id)
	DestroyTable(orders.t_id)
end

--������� ���������� ���������� QUIK ��� ��� ��������� ������� ����������. 
--class - ������, ��� ������
--sec - ������, ��� ������
function OnParam( class, sec )

	trans:CalcDateForStop()	--��������� ������ ������ � ���������� �� � �������� dateForStop ������� trans
	
    if (tostring(sec) ~= settings.SecCodeBox)  then
		return 0
	end
		
	
	--main_loop()
	
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
	
	--������� ����� ������ � �������, �� ��������� �������� ��� �������
	--add_order_num_to_signal(trade.trans_id, trade.order_num)
	
	
	local robot_id=''	--dummy
	
	--��� ������� - ����� ID �������, �� �������� ������ ������
	
	--��� ����������� ����
	--trade.trans_id
	--trade.order_num
	
	--����� ����� � ������� ������ ���� trans_id. ����� ���� ��������� ������ (����� ��?)
	--�������� ���������� � ������ � ���������� � ������
	--���� ����� - ������ ��������� �������, �����:
	--		������� �� ������
	--		��������� ������� (���� � ����). ���� ����� - ��������� ��������� ������ � �������
	--����� - ��������� �������� � ���� ������
	--��� ��������� ����������� �������������, ��� ������ �������� ������ ������� �� ���� ����������
	
	
	local s = orders:GetSize()
	for i = 1, s do
		if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trade.trans_id) 
			and tostring(orders:GetValue(i, 'order').image) == tostring(trade.order_num) then
			orders:SetValue(i, 'trade', trade.trade_num)
			logstoscreen:add('OnTrade - trans_id '..tostring(orders:GetValue(i, 'trans_id').image))
			break
		end
	end
	
	
end

function OnOrder(order)
	if working == false then
		return
	end
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

	--������� ����� ������ � �������, �� ��������� �������� ��� �������
	-- 27 05 17. ������ ���������� �������� ��� �������, �.�. ������ OnOrder ��������� �����,��� OnTrade :(
	-- add_order_num_to_signal(order.trans_id, order.order_num)
	
	
end

function add_order_num_to_signal(trans_id, order_num)


	--���� ������ � ����� �� trans_id
	local sql = [[
	select
		rownum
	from
		transId
	where
		trans_id = ]] .. tostring(trans_id)
	
	--�������� � ��������� ������ ����� ������
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
	
	strategy.db = db
	
	--������� ������� �������� � ����
	sqlitework.db = db
	sqlitework:createTableSignals()
	--������� ������� ������� � ����
	sqlitework:createTablePositions()
	
	sqlitework:createTableOrders()
	
	--� ���� ������� ���� ����: rownum | trans_id | signal_id | order_num | robot_id
	--� ��� ����� ������� �� ������ strategy
	--� ����� ��������� order_num �� ������� OnOrder()
	sqlitework:createTableTransId()

	
	
	--������� ���� ������ � �������� � ��������� � ��� ������� ������
	local position = {x=10,y=10,dx=285,dy=400}
	
	create_window(position)
	
	SetTableNotificationCallback (window.hID, f_cb)

	
	strategy.logstoscreen = logstoscreen  --��� ����� 
	
	strategy.secCode = sec --ENS ��� ������� --����� ������ ��� �����?
	
	--��� �������� �� ������� ���� ��������
	--strategy.Position=trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox)
	
---------------------------------------------------------------------------	
	signals = QTable.new()
	if not signals then
		message("error creation table Signals!", 3)
		return
	else
		--message("table with id = " ..signals.t_id .. " created", 1)
	end

	signals:AddColumn("id", QTABLE_INT_TYPE, 15)
	signals:AddColumn("date", QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("time", QTABLE_CACHED_STRING_TYPE, 10)
	signals:AddColumn("price", QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("MA", QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("trans_id", QTABLE_DOUBLE_TYPE, 10)
	signals:AddColumn("done", QTABLE_STRING_TYPE, 10)
	
	signals:SetCaption("Signals")
	signals:Show()

	SetWindowPos(signals.t_id, 810, 10, 500, 200)

---------------------------------------------------------------------------	
	orders = QTable.new()
	if not orders then
		message("error creation table orders!", 3)
		return
	else
		--message("table with id = " ..orders.t_id .. " created", 1)
	end

	orders:AddColumn("order", QTABLE_INT_TYPE, 20)
	orders:AddColumn("trade", QTABLE_INT_TYPE, 20)
	orders:AddColumn("trans_id", QTABLE_INT_TYPE, 20)
	
	orders:SetCaption("orders")
	orders:Show()
	
	SetWindowPos(orders.t_id, 810, 220, 500, 200)
	
	
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
	window:AddRow({"",""},"")
	window:AddRow({"TEST BUY",""},"Green")
	window:AddRow({"",""},"")
	window:AddRow({"TEST SELL",""},"Green")
	window:AddRow({"",""},"")	

end

--��� ������� ������ ���������� �� ������������ ����� � ������� main()
function main_loop()

	
	security:Update()	--��������� ���� ��������� ������ � ������� security (�������� Last,Close)

	window:InsertValue("����",tostring(security.last)) --�������� ���� � ���� ������. ������ ��� ����������� ����������		

	--�������� ��������� [1] - ��� http://robostroy.ru/community/article.aspx?id=796
	--[1]������� �� �������� ���������� ������. �����: �� ������� ����
	NumCandles = getNumCandles(settings.IdPriceCombo)	

	if NumCandles==0 then
		--return 0
	end

	strategy.NumCandles=2

	--���_��� ��� ����������� 2 ������������� �����. ��������� �� �����, �.�. ��� ��� �� ������������
	tPrice,n,s = getCandlesByIndex(settings.IdPriceCombo,0,NumCandles-3, 2)		
	strategy:SetSeries(tPrice)

	--����� ����� ����������� ���� � ������� moving averages
	tPrice,n,s = getCandlesByIndex(settings.IdMA,0,NumCandles-3, 2)		
	strategy.Ma1Series=tPrice	--����� ���� (Ma1Series) ��� � Init, ��� ��������� �����


	--������� ���������� �����

		
	strategy:CalcLevels() --������� �������� ���� � ������� ����������
	

	if working==true  then
		--logstoscreen:add('----------------------------------')
		--logstoscreen:add('...main loop...')
		
	else
		return
		
	end
		
	if new_signal == false then
		--����� ������� ������� ������ ����� ��������� ������ �� ����� "��������� ������ �������"
		local signal_buy =  signal_buy()
		local signal_sell =  signal_sell()
		if signal_buy == true or signal_sell == true then
			logstoscreen:add('we have got a signal: ')
			--���� ���� ������, ����� ���������, � ����� �� ��� ��� ����������.-
			--��������� ��� ����������� 1 ���, ������� ������� ���� ����� ������ ������
			--��� ����� ��� ����� ���������
			local rows=0
			local cols=0
			rows,cols = signals:GetSize()
			local price_cell = {}
			local ma_cell = {}
			for i = 1 , rows do
				price_cell = signals:GetValue(i, "price")--����� �������� ����� �� ��������� �����
				ma_cell = signals:GetValue(i, "MA")--����� �������� ����� �� ��������� �����

				if tonumber(price_cell.image) == strategy.PriceSeries[1].close and tonumber(ma_cell.image) == strategy.Ma1 then 
					--��� ���� ������, ������� ������������ �� ����
					return
				end
			end
			
			--������� � ������� ���, ��������� �����
			
			signal_id = helper:getMiliSeconds_trans_id()
			
			local row = signals:AddLine()
			
			signals:SetValue(row, "id", signal_id)
			signals:SetValue(row, "date", os.date())
			signals:SetValue(row, "time", os.time()) --����� �����, ����� ����������, � ���� ������� ����� �������
			signals:SetValue(row, "price", strategy.PriceSeries[1].close)
			signals:SetValue(row, "MA", strategy.Ma1)
			--signals:SetValue(row, "trans_id", )
			signals:SetValue(row, "done", false)
			
		end
		
		--�������� ����� ���� ������� - �������
		if signal_buy == true then 

			--if self:findSignal2()  == false then
			--	sig_id = self:saveSignal('buy')
			--end

			--�������� ����, ������� �������� ���� ����� ���������� �������� �������
			new_signal = true
			logstoscreen:add('new_signal = '..tostring(new_signal))
			--processSignal('buy')
			signal_direction = 'buy'
			state_process_signal = true
			
		elseif signal_sell == true	then 

			--�������� �������� ���� ������� - �������
			
			--if self:findSignal2()  == false then
			--	sig_id = self:saveSignal('sell')
			--end

			--�������� ����, ������� �������� ���� ����� ��������� �������
			new_signal = true
			logstoscreen:add('new_signal = '..tostring(new_signal))
			--processSignal('sell')
			signal_direction = 'sell'
			state_process_signal = true
			
		end
	
	else
	
		--���� ������ ����� new_signal ����� ����� true
		
		if state_process_signal == true then
		
			if we_are_waiting_result == false then
			
				processSignal(signal_direction)
		
			else
				--������ ���������, ���� ���� ������ �����, ����� ��������� �����
				logstoscreen:add('we are waiting the result of sending order')
				
				local s = orders:GetSize()
				for i = 1, s do
					--logstoscreen:add('trans_id = '..tostring(trans_id))
					if tostring(orders:GetValue(i, 'trans_id').image) == tostring(trans_id) then
						--logstoscreen:add('trade = '..orders:GetValue(i, 'trade').image)
						if orders:GetValue(i, 'trade')~=nil and( orders:GetValue(i, 'trade').image~='0' or 
							orders:GetValue(i, 'trade').image~='') then
							--���� � ������� orders �������� ����� ������, ��� ������ ��� ������ ������������.
							we_are_waiting_result = false
							logstoscreen:add('order '..orders:GetValue(i, 'order').image..' processed')
							break
						end
					end
				end
				
				--a=1/0
				
			end
		end
	
	
	end	
		
		
	--��������� ������ � ���������� ������� ������
	window:InsertValue("MA (60)",tostring(strategy.Ma1))
	window:InsertValue("Close",tostring(strategy.PriceSeries[1].close))
	
	window:InsertValue("MA pred (60)",tostring(strategy.Ma1Pred))
	window:InsertValue("PredClose",tostring(strategy.PriceSeries[0].close))
	
	window:InsertValue("�������",tostring(strategy.Position))

		
end

--���������� ������
function processSignal(direction)
	
	logstoscreen:add('processing signal: '..direction)
	
	--����� ����������, �� ������� �����/���������� ����� ������� ������� - ��� � ���������� ������
	local planQuantity = tonumber(settings.LotSizeBox)
	if direction == 'sell' then
		planQuantity = -1*planQuantity
	end
	logstoscreen:add('plan quantity: ' .. tostring(planQuantity))
	
	--����������, ������� ��� �����/���������� ���� � ������� (� ������� �� ����� ������)
	local factQuantity = trader:GetCurrentPosition(settings.SecCodeBox, settings.ClientBox)
	logstoscreen:add('fact quantity: ' .. tostring(factQuantity))
	
	--���� ��� �������� ����������, �� �������� ����
	if (direction == 'buy' and factQuantity < planQuantity )
		or (direction == 'sell' and factQuantity > planQuantity)
		then
		
	
		--������� ������
		
		trans_id = helper:getMiliSeconds_trans_id() --���������� ��� ������� ����������
		
		local qty = planQuantity - factQuantity
		
		logstoscreen:add('qty: ' .. tostring(qty))
		
		if direction == 'sell' then
			qty = -1*qty
		end
		
		--!!!!!!!!!!!!��� �������. ���� ��������� ��� ����� ������������ �������� ������ ������� 
		--qty = 1
		
		local row = orders:AddLine()
		orders:SetValue(row, "trans_id", trans_id)
		
		if direction == 'buy' then
			Buy(qty, trans_id)
		elseif direction == 'sell' then
			Sell(qty, trans_id)
		end
		
		--�������� ����, ������� ����, ��� ����� ���� ������ �� ������������ ������
		--���� ���������� � ������� OnTrade()
		we_are_waiting_result = true
		
	else
		logstoscreen:add('��� ������� ��� �������, ������ �� ����������!')
		new_signal = false
		state_process_signal = false
	end
	
end

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

	--��� ������
	if working == true then
		if test_signal_buy == true then
			test_signal_buy = false
			return true
		end
	end
	
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
end

function signal_sell()

	--��� ������
	if working == true then
		if test_signal_sell == true then
			test_signal_sell = false
			return true
		end
	end
	
	if strategy.Ma1 ~= 0 
	and strategy.Ma1Pred  ~= 0 
	and strategy.PriceSeries[0].close ~= 0
	and strategy.PriceSeries[1].close ~= 0
	and strategy.PriceSeries[0].close > strategy.Ma1Pred --�������������� ��� ���� �������
	and strategy.PriceSeries[1].close < strategy.Ma1 --���������� ��� ���� �������
	then
		return true
	else
		return false
	end

end


--���������� �� ����� �� �����. Strategy:DoBisness()
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
