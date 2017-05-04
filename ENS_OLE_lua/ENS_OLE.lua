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

logs={}




is_run = true	--���� ������ �������, ���� ������ - ������ ��������

working = false	--���� ����������. ����� �� �������� ���� ����� ���� ��������/��������� ������

Waiter=0		--�����-�� ����, ����� ������ �� ������������, ���� ���� � ��������� ������ StrategyBollinger

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
	--� ���� ���������� � ����� ����� ������. ��� ����� ����� 0, � ����� �����, �������, 
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