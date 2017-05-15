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
	
end


function OnStop(s)

	window:Close()
	is_run = false
	
end 

function StopScript()
	window:Close()
	is_run=false
end

--������� ���������� ���������� QUIK ��� ��� ��������� ������� ����������. 
--class - ������, ��� ������
--sec - ������, ��� ������
function OnParam( class, sec )

--[[
    if is_run == false or working==false then
        return
    end
	--]]
	trans:CalcDateForStop()	--��������� ������ ������ � ���������� �� � �������� dateForStop ������� trans
	
    if (tostring(sec) ~= settings.SecCodeBox)  then
		return 0
	end
		
	time = os.date("*t")

	strategy.Second=time.sec	--�������

	security:Update()	--��������� ���� ��������� ������ � ������� security (�������� Last,Close)

	window:InsertValue("����",tostring(security.last))

	--QLUA getNumCandles
	--������� ������������� ��� ��������� ���������� � ���������� ������ �� ���������� ��������������. 
	--������ ������: 
	--NUMBER getNumCandles (STRING tag)
	--���������� ����� � ���������� ������ �� ���������� ��������������. 

	--�������� ��������� [1] - ��� http://robostroy.ru/community/article.aspx?id=796
	--[1]������� �� �������� ���������� ������. �����: �� ������� ����
	NumCandles = getNumCandles(settings.IdPriceCombo)	
 
	if NumCandles==0 then
		return 0
	end
 
	strategy.NumCandles=2

	--QLUA getCandlesByIndex
	--������� ������������� ��� ��������� ���������� � ������� �� �������������� 
	--(����� ������ ��� ���������� ������� ������ �� ������������, ������� ��� ��������� ������� ������ ������ ������ ���� ������). 
	--������ ������: 
	--TABLE t, NUMBER n, STRING l getCandlesByIndex (STRING tag, NUMBER line, NUMBER first_candle, NUMBER count) 
	--���������: 
	--tag � ��������� ������������� ������� ��� ����������, 
	--line � ����� ����� ������� ��� ����������. ������ ����� ����� ����� 0, 
	--first_candle � ������ ������ ������. ������ (����� �����) ������ ����� ������ 0, 
	--count � ���������� ������������� ������.
	--������������ ��������: 
	--t � �������, ���������� ������������� ������, 
	--n � ���������� ������ � ������� t , 
	--l � ������� (�������) �������.

	--[1]������� getCandlesByIndex ������� ���������, � ����� �� ����� ����� �� �������� ������, 
	--� ���� ���������� � ����� ����� ������. ��� ����� ����� 0, � ����� ������, �������, 
	--�������������� N-1 � �� ������� ������ ���������� ������.
	
	--���_��� ��� ����������� 2 ������������� �����. ��������� �� �����, �.�. ��� ��� �� ������������
	tPrice,n,s = getCandlesByIndex(settings.IdPriceCombo,0,NumCandles-3, 2)		
	strategy:SetSeries(tPrice)


		
	--����� ����� ����������� ���� � ������� moving averages
	tPrice,n,s = getCandlesByIndex(settings.IdMA,0,NumCandles-3, 2)		
	strategy.Ma1Series=tPrice	--����� ���� (Ma1Series) ��� � Init, ��� ��������� �����


	security:Update()		--��������� ���� ��������� ������ � ������� security (�������� Last,Close)
	strategy.Position=trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox)
	
	--[[
	local logfile = "c:\\TRAIDING\\ROBOTS\\DEMO\\ENS_MA_lua\\ARQA\\log.txt"
	Helper:AppendInFile(logfile, "----------------------------------------".."\n")
	--Helper:AppendInFile(logfile, "sec code: "..self.secCode.."\n")
	Helper:AppendInFile(logfile, "sec code: "..tostring(settings.SecCodeBox).."\n")
	Helper:AppendInFile(logfile, "Position: "..tostring(strategy.Position).."\n")	
	Helper:AppendInFile(logfile, "settings.LotSizeBox: "..tostring(settings.LotSizeBox).."\n")	
	Helper:AppendInFile(logfile, "strategy.LotToTrade: "..tostring(strategy.LotToTrade).."\n")	
	--Helper:AppendInFile(logfile, "enter_quantity: "..tostring(enter_quantity).."\n")	
	--Helper:AppendInFile(logfile, "exit_quantity: "..tostring(exit_quantity).."\n")	
	Helper:AppendInFile(logfile, "rejim: "..tostring(settings.rejim).."\n")	
	--]]
	
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
	else
		window:InsertValue("������", '')
		
	end
	
	--�������� �������� ���� ������� - �������
	if strategy:signal_sell() == true then
		window:InsertValue("������", 'sell')
		logs:add('signal sell'..'\n')
	else
		window:InsertValue("������", '')
		
	end
	
	--]]
	
end

--�������, ����������� ����� �������� ������ �� ������
function OnTransReply(trans_reply)

	

end 

--�������, ����������� ����� ����������� ������
function OnTrade(trade)
	
	safeIterationsTradesCount = safeIterationsTradesCount + 1
	if safeIterationsTradesCount >= safeIterationsTradesLimit then
		is_run = false
		working = false
		message('safely break script (OnTrade)')
		StopScript()
	end
	
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
	
	--tableOrders = strategy:findOrders(trade.trans_id) --��� ������� ������� ���, ���������� ��������, ���������� � ����
	
	local k = "'"
	local sql = [[
	
		select 
			signal_id,
			robot_id
		from 
			transId
		where
			trans_id	= ]].. tostring(trade.trans_id) .. [[
			and
			order_num	= ]] ..tostring(trade.order_num)
	
	for row in db:nrows(sql) do
		--�������� �������
		strategy:test_insert_positions(row.signal_id, helper:what_is_the_direction(trade), trade.trans_id)
	end
	

		--[[
		--����� ��������� ������ � ���� processed ����� ����� 1
		if realPos == LotsToPosition then
			self:updateSignalStatus(sig_id, 1)
			if self:checkSignalStatus(sig_id, 1) == 1 then
				--it is OK
			else
				--update failed. ��� ������???
				message('fail to update signal status')
			end
		else
			--�������� ����������. � ������, ��� ������ � ���� ��������?
			message('�� ������� ������� ������� ���������� �������')
		end
		--]]	
	
	
end

function OnOrder(order)

	safeIterationsOrdersCount = safeIterationsOrdersCount + 1
	if safeIterationsOrdersCount >= safeIterationsOrdersLimit then
		is_run = false
		working = false
		message('safely break script (OnOrder)')
		StopScript()
	end


	local k = "'"
	--���� ������ � ����� �� trans_id
	local sql = [[
	select
		rownum
	from
		transId
	where
		trans_id = ]] .. tostring(order.trans_id)
	
	--�������� � �� ������ ����� ������
	for row in db:nrows(sql) do
		sql = [[
		update
			transId
		set
			order_num = ]] ..tostring(order.order_num) .. [[
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
			message("�����",1)
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

	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and x["image"]=="���������" then

			message("���������",1)
			window:SetValueWithColor("���������","�����","Green")
			working=false
		end
	end




	if (msg==QTABLE_CLOSE)  then
		window:Close()
		is_run = false
		--message("����",1)
	end

	if msg==QTABLE_VKEY then
		--message(par2)
		if par2 == 27 then-- esc
			window:Close()
			is_run=false
			
		end
	end	

end 

--������� ������� ������, ������� �������� � �����
function main()

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


	
	
	--QLUA SetTableNotificationCallback
	--������� ������� ��������� ������ ��� ��������� ������� � �������. 
	--������ ������: 
	--NUMBER SetTableNotificationCallback (NUMBER t_id, FUNCTION f_cb)
	--���������: 
	--t_id � ������������� �������, 
	--f_cb � ������� ��������� ������ ��� ��������� ������� � �������.
	--� ������ ��������� ���������� ������� ���������� �1�, ����� � �0�. 
	--������ ������ ������� ��������� ������ ��� ��������� ������� � �������: 
	--f_cb = FUNCTION (NUMBER t_id, NUMBER msg, NUMBER par1, NUMBER par2)
	--���������: 
	--t_id � ������������� �������, ��� ������� �������������� ���������, 
	--par1 � par2 � �������� ���������� ������������ ����� ��������� msg, 
	--msg � ��� ���������.
	
	SetTableNotificationCallback (window.hID, f_cb)

	--����������
	
	--��� ��������� ������������ ���� ���� ���� ����� ��������, �.�. ������� �������� ���� ������� �����
	--[[ ��� �������� - ����� ��������� ����������
	if working == false then
		OnStart()
		message("�����",1)
		window:SetValueWithColor("�����","���������","Red")
		working=true
	end
	--]]
	
	--�������� 100 ����������� ����� ���������� 
	while is_run do
		sleep(1000)
	end

end

--��������� ���� ���������
function funcTest()

	--�������� ������� �������� � �������
	--sqlitework:executeSQL('delete from positions')
	--sqlitework:executeSQL('delete from signals')
	
	local k="'"
	local trans_id = helper:getMiliSeconds_trans_id()
	local sql = 'insert into transid (trans_id,signal_id,order_num,robot_id) values ('..tostring(trans_id)..','..tostring(44)..',0,'..k.. settings.robot_id ..k..')'
	ret = db:exec(sql)			
	if ret~=0 then
		message('error on insert to transid. error code is '..tostring(ret))
	end
	--logs:add(sql)	
	
	NumCandles = getNumCandles(settings.IdPriceCombo)	
 
	if NumCandles==0 then
		message('��������, ������� �������������� ���� � ������� ����������!')
		return 0
	end
	
	strategy.db = db
 
	strategy.NumCandles=2
	
	--���_��� ��� ����������� 2 ������������� �����. ��������� �� �����, �.�. ��� ��� �� ������������
	tPrice,n,s = getCandlesByIndex(settings.IdPriceCombo,0,NumCandles-3, 2)		
	strategy:SetSeries(tPrice)
		
	--����� ����� ����������� ���� � ������� moving averages
	tPrice,n,s = getCandlesByIndex(settings.IdMA,0,NumCandles-3, 2)		
	strategy.Ma1Series=tPrice	--����� ���� (Ma1Series) ��� � Init, ��� ��������� �����

	security:Update()		--��������� ���� ��������� ������ � ������� security (�������� Last,Close)
	strategy.Position=trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox)
	
	message('---')
	
	--�������� ������
	
	strategy:CalcLevels()
	if strategy:findSignal('buy')  == false then
		message('run saveSignal')
		strategy:saveSignal('buy')
	end	
	--[[
	if strategy:findSignal('sell')  == false then
		strategy:saveSignal('sell')
	end
	--]]
		

		
	strategy:processSignal('buy')
	
end