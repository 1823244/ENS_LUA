--��� ������ �������� ����� ������

local bit = require"bit"

--���� � ������� ����� �������� �� ����������, ��� ��� �����
--"c:\\WORK\\lua\\ENS_LUA_Common_Classes"
--"c:\\WORK\\lua\\ENS_LUA_Strategies"

--��������� ����� - ��������� �����, ��� ������� ������ ����.

--common classes
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\class.lua")
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\Window.lua")
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\Helper.lua")
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\Trader.lua")
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\Transactions.lua")
--dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\Security.lua") --���� ����� ������������� ��� ������� ������
dofile ("z:\\WORK\\lua\\ENS_LUA_Common_Classes\\logs.lua")

--common within one strategy
dofile ("z:\\WORK\\lua\\ENS_LUA_Strategies\\StrategyOLE.lua")

--private for each robot
dofile (getScriptPath().."\\Classes\\SettingsGRID.lua")
dofile (getScriptPath().."\\Classes\\Security.lua")--���� ����� ������������� ��� ������� ������


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
--���������
--	row - �����, ����� ������ � �������. �����, ����� �������� ��������� �������� �� ������, ������� ��������� � ������
function OnStart(row)

	--working = true
	--window:InsertValue("�������",tostring(trader:GetCurrentPosition(settings.SecCodeBox,settings.ClientBox)))--��������
	
	

	--�������� ��������
 	OnParam( settings.ClassCode, window:GetValueByColName(row, 'Ticker').image )
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
	
	--����� ���? ��� ���������?
	trans:CalcDateForStop()	--��������� ������ ������ � ���������� �� � �������� dateForStop ������� trans
	
	for row=1, #settings.secList do
		if (tostring(sec) == settings.secList[row][1])  then
			OnParam_one_security( row, class, sec )
		end
    end

end

function OnParam_one_security( row, class, sec )

	--[[
    if is_run == false or working==false then
        return
    end
	--]]
	
	--����� ���? ��� ���������?
	trans:CalcDateForStop()	--��������� ������ ������ � ���������� �� � �������� dateForStop ������� trans

	time = os.date("*t")

	--��� �����?
	strategy.Second=time.sec	--�������

	security:Update(class, sec)	--��������� ���� ��������� ������ � ������� security (�������� Last)

	window:SetValueByColName(row, 'LastPrice', tostring(security.last))

	--QLUA getNumCandles
	--������� ������������� ��� ��������� ���������� � ���������� ������ �� ���������� ��������������. 
	--������ ������: 
	--NUMBER getNumCandles (STRING tag)
	--���������� ����� � ���������� ������ �� ���������� ��������������. 

	--�������� ��������� [1] - ��� http://robostroy.ru/community/article.aspx?id=796
	--[1]������� �� �������� ���������� ������. �����: �� ������� ����
	
	local IdPrice = window:GetValueByColName(row, 'PriceName').image   --������������� ������� ���� ��������� ������ (�������)
	
	local NumCandles = getNumCandles(IdPrice)	--��� ����� ���������� ������ �� ������� ����. ��� ����� 2 - ����������������� � �������������. ��������� �� �����, ��� �������, ��� �� �������� �����
 
	if NumCandles~=0 then
 
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
		tPrice,n,s = getCandlesByIndex(IdPrice, 0, NumCandles-3, 2)		
		strategy:SetSeries(tPrice)

		IdMA60 = window:GetValueByColName(row, 'MA60name').image  --������������� ������� ������� ����������
		
		--����� ����� ����������� ���� � �������� moving averages
		tPrice,n,s = getCandlesByIndex(IdMA60, 0, NumCandles-3, 2)		
		strategy.Ma1Series=tPrice

		security:Update(class, sec)		--��������� ���� ��������� ������ � ������� security (�������� Last)
		strategy.Position=trader:GetCurrentPosition(sec, settings.ClientBox)
		
		strategy.secCode = sec --ENS ��� �������
		
		strategy.LotToTrade=tonumber(window:GetValueByColName(row, 'Lot').image)
		
		--[[
		if working==true  then
			strategy:DoBisness()
		else
			--ENS ������ ���������� �������� ����������
			strategy:CalcLevels()
		end
		--]]
		--for debug. ����� ��� ������ � �������� �������, ������� ����
		strategy:CalcLevels()
		--������� DoBisness() ����� ��������� ������ �� ������, ��� ���������� � ��������� �������. ������� ��
		strategy.PredPosition=strategy.Position
		
		--��������� ������ � ���������� ������� ������
		window:SetValueByColName(row, 'MA60Pred', strategy.Ma1Pred)
		window:SetValueByColName(row, 'MA60', strategy.Ma1)
		
		window:SetValueByColName(row, 'PricePred', strategy.PriceSeries[0].close)
		window:SetValueByColName(row, 'Price', strategy.PriceSeries[1].close)
		
		window:SetValueByColName(row, 'LastPrice', tostring(security.last))


	end

	
	
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
	
	local x=GetCell(window.hID, par1, par2) 

	--�������
	--QTABLE_LBUTTONDBLCLK � ������� ������� ����� ������ ����, ��� ���� par1 �������� ����� ������, par2 � ����� �������, 
	
	if x~=nil then
		if (msg==QTABLE_LBUTTONDBLCLK) and par2 == window:GetColNumberByName('StartStop') then
			--message("Start",1)
			if x["image"]=="Start" then
				Red(window.hID, par1, par2)
				SetCell(window.hID, par1, par2, 'Stop')
				OnStart(par1)
				working = true
			else
				Green(window.hID, par1, par2)
				SetCell(window.hID, par1, par2, 'Start')
				working = false
			end
			
		end
	end


	if (msg==QTABLE_CLOSE)  then
		window:Close()
		is_run = false
		working = false
	end

	--�������� ���� ������ ������� ESC
	if msg==QTABLE_VKEY then
		--message(par2)
		if par2 == 27 then-- esc
			window:Close()
			is_run=false
			working = false
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
	
	--ENS ����� window �������� ���� columns, ����� ����� ����� ���� �����  ����� ������� �� �����
	--������� 'MA60name','PriceName' �������� �������������� ��������. ��� ������ ������ - ���� �������������
	--������ ��������������: ��������������_grid_MA60, ��������������_grid_price
	--������� 'MA60Pred','MA60' �������� �������� ������� ���������� ��� ��������������� � ����������� ���� ��������������
	--������� 'PricePred','Price' �������� �������� ���� ��� ��������������� � ����������� ���� ��������������
	--������� 'BuyMarket','SellMarket' - ��� "������", �.�. �������, �� ������� ����� ������������, ����� ������/������� �� ����� ���������� ���������� �� ������� Lot
	--'StartStop' - "������", ����������� ���������� ������ ��� ����������� �����������. ���� ����� ��������, �� �� ��� ����� ����������
	--�������� ��������� ����, �������������� � ���������� ���� � ������� ����������
	
	window:Init(settings.TableCaption, {'Account','Ticker', 'Lot', 'Position','LastPrice','BuyMarket','SellMarket','StartStop','MA60Pred','MA60','PricePred','Price','MA60name','PriceName'})
	
	
	
	--message(window.columns[1] )
	
	--��������� ������ � ������������� � ������� ������
	for row=1, #settings.secList do
		--DeleteRow(self.t.t_id, row)
		local secGroup = settings.secList[row][1] --��� ���� �����, �������� BR ��� �����
		local sec = settings.secList[row][2]
		local lot = settings.secList[row][3]
		
		window:AddRow({},'')--��������� ������ ������, ����� ������������� �������� �����
		
		window:SetValueByColName(row, 'Account', settings.ClientBox)
		window:SetValueByColName(row, 'Ticker', sec) --��� ������
		window:SetValueByColName(row, 'Lot', lot) --������ ���� ��� ��������
		window:SetValueByColName(row, 'StartStop', 'Start')
		window:SetValueByColName(row, 'BuyMarket', 'Buy')
		window:SetValueByColName(row, 'SellMarket', 'Sell')
		
		window:SetValueByColName(row, 'MA60name', secGroup ..'_grid_MA60')
		window:SetValueByColName(row, 'PriceName', secGroup..'_grid_price')
		
		--����� �������� ����� ������� ���������� ������� GetColNumberByName()
		Green(window.hID, row, window:GetColNumberByName('StartStop')) 
		Green(window.hID, row, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, row, window:GetColNumberByName('SellMarket')) 
	end  


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

	--��� ������� ���� ��� �������� OnParam, ����� ��������� ��������� ��������
	
	for row=1, #settings.secList do
		--message(settings.secList[row][1])
		OnParam( settings.ClassCode, settings.secList[row][1] )
	end
	
	--�������� 100 ����������� ����� ���������� 
	while is_run do
		sleep(50)
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








