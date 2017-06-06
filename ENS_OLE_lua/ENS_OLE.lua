--������� ��������
--�������� ���� ���� 60-� ��������� ���������� - ������� � ���������� ������ �� �����
--�������� ���� ���� 60-� ��������� ���������� - ������� � ���������� ������ �� �����

local sqlite3 = require("lsqlite3")
local db = sqlite3.open(getScriptPath() .. "..\\positions.db")

local bit = require"bit"

--��������� ���� � ������ �������
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

--��� �������:
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


is_run = true	--���� ������ �������, ���� ������ - ������ ��������

working = false	--���� ����������. ����� �� �������� ���� ����� ���� ��������/��������� ������

Waiter=0		--�����-�� ����, ����� ������ �� ������������, ���� ���� � ��������� ������ StrategyBollinger

--������ � �������� ����������� ���������� ���������� ��������. ���� ����� � ����������� ����, �� �� ���������� ������ ������� ���
safeIterationsOrdersLimit = 5
safeIterationsOrdersCount = 0
safeIterationsTradesLimit = 5
safeIterationsTradesCount = 0

--local hID=0		--����� �� �� ������������, ����� �� ��� �����?

--��������� ����� ��� ����������� �������� � ���� ������,����� ��������,��� �� �������� 
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
	logstoscreen:Init() 


  
  db = sqlite3.open(settings.dbpath)
  

end

--��� �� ���������� �������, � ������ ������� �������
function OnBuy()
    if working  then
      trans:order(settings.SecCodeBox,settings.ClassCode,"B",settings.ClientBox,settings.DepoBox,tostring(security.last+100*security.minStepPrice),settings.LotSizeBox)
	end 
end

--��� �� ���������� �������, � ������ ������� �������
function OnSell()
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

	--message('OnTransReply '..helper:getMiliSeconds())
	logstoscreen:add('OnTransReply '..helper:getMiliSeconds())

end 

--�������, ����������� ����� ����������� ������
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
	
	--������� ����� ������ � �������, �� ��������� �������� ��� �������
	add_order_num_to_signal(trade.trans_id, trade.order_num)
	
	
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

--f_cb � ������� ��������� ������ ��� ��������� ������� � �������. ���������� �� main()
--(���, ������� �������, ���������� ����� �� ������� ������)
--���������:
--	t_id - ����� �������, ���������� �������� AllocTable()
--	msg - ��� �������, ������������ � �������
--	par1 � par2 � �������� ���������� ������������ ����� ��������� msg, 
--
local f_cb = function( t_id,  msg,  par1, par2)
	
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
			OnBuy()
		end
	end

	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="Sell �� �����" then
			message("Sell",1)
			OnSell()
		end
	end


	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="�����" then
			OnStart()
			--message("�����",1)
			window:SetValueWithColor("�����","���������","Red")
			working=true
		end
	end

	--��� �������
	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="TEST" then
			message("TEST",1)
			funcTest()
			--window:SetValueWithColor("�����","���������","Red")
			--working=true
		end
	end
	
	--��� �������
	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="check position" then
			--message("TEST",1)
			checkPositionTest()
			--window:SetValueWithColor("�����","���������","Red")
			--working=true
		end
	end	

	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="���������" then

			--message("���������",1)
			window:SetValueWithColor("���������","�����","Green")
			working=false
		end
	end




	if (msg==QTABLE_CLOSE)  then
		--[[window:Close()
		is_run = false
		--message("����",1)
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

--������� ������� ������, ������� �������� � �����
function main()


	--��� ������� - ���������
	--working = true
	
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
	create_window()
	
	SetTableNotificationCallback (window.hID, f_cb)

	strategy.logstoscreen = logstoscreen
	
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


function create_window()

	
	--������� ���� ������ � �������� � ��������� � ��� ������� ������
	window = Window()									--������� Window() ����������� � ����� Window.luac � ������� �����
	
	--{'A','B'} - ��� ������ � ������� �������
	--�������: http://smart-lab.ru/blog/291666.php
	--����� ������� ������, ���������� ����������� � �������� ������� �������� ��� ���������:
	--t = {��������, ��������, ������}
	--��� ��������� ������������ ���������� ����:
	--t = {[1]=��������, [2]=��������, [3]=������}	
	
	--window:Init("ENS MovingAverages", {'A','B'})	--�������� ����� init ������ window
	window:Init(settings.TableCaption, {'A','B'})	--�������� ����� init ������ window
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
	window:AddRow({"TEST",""},"Green")
	window:AddRow({"",""},"")
	window:AddRow({"check position",""},"Green")
end


function main_loop()

		security:Update()	--��������� ���� ��������� ������ � ������� security (�������� Last,Close)

		window:InsertValue("����",tostring(security.last))		

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

		security:Update()		--��������� ���� ��������� ������ � ������� security (�������� Last,Close)
		strategy.Position=trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox)
		
		strategy.secCode = sec --ENS ��� �������
		if working==true  then
			strategy:DoBisness()
		else
			--ENS ������ ���������� �������� ����������
			strategy:CalcLevels()
			
		end
		strategy.PredPosition=strategy.Position

		
		--��������� ������ � ���������� ������� ������
		window:InsertValue("MA (60)",tostring(strategy.Ma1))
		window:InsertValue("Close",tostring(strategy.PriceSeries[1].close))
		
		window:InsertValue("MA pred (60)",tostring(strategy.Ma1Pred))
		window:InsertValue("PredClose",tostring(strategy.PriceSeries[0].close))
		
		window:InsertValue("�������",tostring(strategy.Position))

		--��� �������
		--������� ������: buy/sell
		
		--strategy.PriceSeries[0].close - �������� ��������������� ���� (������ ������� �� ����)
		--strategy.PriceSeries[1].close - �������� ����������� ����
		

		---[[
		--�������� �������� ���� ������� - �������
		
	  
		if strategy:signal_buy() == true then
			window:InsertValue("������", 'buy')
			logs:add('signal buy'..'\n')
		elseif strategy:signal_sell() == true then
		--�������� �������� ���� ������� - �������
			window:InsertValue("������", 'sell')
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
			window:InsertValue("������", symb)
end


--��������� ���� ���������. ������ ��������� ������, � ��������� ������� DoBusiness
function funcTest()

	strategy:DoBisness(true)
	
end

--��� �������. ��������� ������� ��������� ������� �������
function checkPositionTest()

a = strategy:findPosition2(settings.SecCodeBox, settings.ClassCode, settings.ClientBox, settings.DepoBox, settings.robot_id)
message(tostring(a))
end