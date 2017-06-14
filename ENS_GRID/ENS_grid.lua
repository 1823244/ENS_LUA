--��� ������ �������� ����� ������

local bit = require"bit"

--���� � ������� ����� �������� �� ����������, ��� ��� �����
--"c:\\WORK\\lua\\ENS_LUA_Common_Classes"
--"c:\\WORK\\lua\\ENS_LUA_Strategies"

--��������� ����� - ��������� �����, ��� ������� ������ ����.

--common classes
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\class.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\class.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Window.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Helper.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Trader.lua")
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Transactions.lua")
--dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\Security.lua") --���� ����� ������������� ��� ������� ������
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Common_Classes\\logs.lua")

--common within one strategy
dofile (getScriptPath() .. ".\\..\\ENS_LUA_Strategies\\StrategyOLE.lua")

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
	
	--����� �����������
	--message(tostring(GetTableSize(window.hID)))
	for row=1, GetTableSize(window.hID) do
		
		local class = window:GetValueByColName(row, 'Class').image
		--message(class)
		local ticker = window:GetValueByColName(row, 'Ticker').image
		--message(ticker)
		if (tostring(sec) == ticker)  then
			OnParam_one_security( row, class, ticker )
		end
	end
	
end

function OnParam_one_security( row, class, sec )

	--[[
    if is_run == false or working==false then
        return
    end
	--]]
	
	time = os.date("*t")

	--��� �����?
	strategy.Second=time.sec	--�������

	security:Update(class, sec)	--��������� ���� ��������� ������ � ������� security (�������� Last)

	--message(tostring(security.last))
	
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


function secListFutures()
  
  local secList = {} --������� ������������. 
  --��� 4 �������:
  --��� �����������, ��� ���� �����, ��� ����� � ���������� ����������
  
  --��� ���� ����� ����� ��� ������������� ���������� �������
  
  --��� � ������� ������ ��� ������
  
  --�������
  secList[1]={'RTS','RI', 'RIU7', 2} --RTS
  secList[2]={'MICEX','MX', 'MXU7', 2} --���� �������
  secList[3]={'MCX MINI','MM', 'MMU7', 2} --���� ����
  
  --������
  secList[4]={'SI','Si', 'SiU7',2} --USD/RUB Si
  secList[5]={'EU','Eu', 'EuU7',2} --EUR/RUB Eu
  secList[6]={'ED','ED', 'EDU7',2} --EUR/USD ED
  secList[7]={'UJPY','JP', 'JPU7',2} --USD/JPY UJPY
  secList[8]={'GBPU','GU', 'GUU7',2} --GBP/USD GBPU
  secList[9]={'AUDU','AU', 'AUU7',2} --AUD/USD AUDU
  secList[10]={'UCAD','CA', 'CAU7',2} --USD/CAD UCAD
  secList[11]={'UCHF','CF', 'CFU7',2} --USD/CHF UCHF
  secList[12]={'UTRY','TR', 'TRU7',2} --USD/TRY UTRY
  secList[13]={'UUAH','UH', 'UHU7',2} --USD/UAH UUAH ������
  
  --������
  --brent ���� ��������� ������ �����
  secList[14]={'BRENT','BR', 'BRN7',2} --brent BR-4.17
  
  secList[15]={'GOLD','GD', 'GDU7',2} --gold
  secList[16]={'SILV','SV', 'SVU7',2} --silv
  secList[17]={'PLT','PT', 'PTU7',2} --plt
  secList[18]={'PLD','PD', 'PDU7',2} --pld
  
  return secList

end

function secListFuturesOnShares()
  
  local secList = {} --������� ������������. 
  --��� 3 �������:
  --��� ���� �����, ��� ����� � ���������� ����������
  
  --��� ���� ����� ����� ��� ������������� ���������� �������
  
  --��� � ������� ������ ��� ������
  
  --shares futures
  secList[1]={'SBRF','SR', 'SRU7',2} --SBRF
  secList[2]={'GAZR','GZ', 'GZU7',2} --GAZR
  secList[3]={'VTBR','VB', 'VBU7',2} --VTBR
  secList[4]={'LKOH','LK', 'LKU7',2} --LKOH
  secList[5]={'ROSN','RN', 'RNU7',2} --ROSN
  secList[6]={'SBPR','SP', 'SPU7',2} --SBPR sber pref
  secList[7]={'FEES','FS', 'FSU7',2} --FEES
  secList[8]={'HYDR','HY', 'HYU7',2} --HYDR
  secList[9]={'GMKR','GM', 'GMU7',2} --GMKR
  secList[10]={'MGNT','MN', 'MNU7',2} --MGNT
  secList[11]={'SNGR','SN', 'SNU7',2} --SNGR
  secList[12]={'MOEX','ME', 'MEU7',2} --MOEX
  secList[13]={'SNGP','SG', 'SGU7',2} --SNGP
  secList[14]={'ALRS','AL', 'ALU7',2} --ALRS
  secList[15]={'NLMK','NM', 'NMU7',2} --NLMK
  secList[16]={'TATN','TT', 'TTU7',2} --TATN
  secList[17]={'MTSI','MT', 'MTU7',2} --MTSI
  secList[18]={'RTKM','RT', 'RTU7',2} --RTKM
  secList[19]={'CHMF','CH', 'CHU7',2} --CHMF --����������
  secList[20]={'TRNF','TN', 'TNU7',2} --TRNF
  secList[21]={'NOTK','NK', 'NKU7',2} --NOTK --�������
  secList[22]={'URKA','UK', 'UKU7',2} --URKA
  
  return secList
end

function secListETS()
  
  local secList = {} --������� ������������. 
  --��� 4 �������:
  --��� �����������, ��� ���� �����, ��� ����������� � ���������� �����
  
  secList[1]={'USD','USD', 'USD000UTSTOM', 2}
  
  
  return secList

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
	
	window:Init(settings.TableCaption, {'Account','Depo','Name','Ticker','Class', 'Lot', 'Position','LastPrice','BuyMarket','SellMarket','StartStop','MA60Pred','MA60','PricePred','Price','MA60name','PriceName'})
	
	
	
	--��������� ���� �������� �����!!!!
	
	--��������  (�������, ������, ������)
	
	local futuresList = secListFutures() --��� ��������� ������
	
	--��������� ������ � ������������� � ������� ������
	for row=1, #futuresList do
		--DeleteRow(self.t.t_id, row)
		local secGroup = futuresList[row][1] --��� ���� �����, �������� BR ��� �����
		
		rowNum = window:AddRow({},'')--��������� ������ ������, ����� ������������� �������� �����
		
		window:SetValueByColName(rowNum, 'Account', '41105E5')
		window:SetValueByColName(rowNum, 'Depo', '41105E5')
		window:SetValueByColName(rowNum, 'Name', futuresList[row][1]) 
		window:SetValueByColName(rowNum, 'Ticker', futuresList[row][3]) --��� ������
		window:SetValueByColName(rowNum, 'Class', 'SPBFUT') --����� ������
		window:SetValueByColName(rowNum, 'Lot', futuresList[row][4]) --������ ���� ��� ��������
		window:SetValueByColName(rowNum, 'StartStop', 'Start')
		window:SetValueByColName(rowNum, 'BuyMarket', 'Buy')
		window:SetValueByColName(rowNum, 'SellMarket', 'Sell')
		
		window:SetValueByColName(rowNum, 'MA60name', secGroup ..'_grid_MA60')--��� ��� �� ����, �.�. � �������� ��������� ������� ���������� ���
		window:SetValueByColName(rowNum, 'PriceName', secGroup..'_grid_price')
		
		--����� �������� ����� ������� ���������� ������� GetColNumberByName()
		Green(window.hID, rowNum, window:GetColNumberByName('StartStop')) 
		Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
	end  

	--�������� �� �����
	
	futuresList = secListFuturesOnShares() --��� ��������� ������
	
	--��������� ������ � ������������� � ������� ������
	for row=1, #futuresList do
		--DeleteRow(self.t.t_id, row)
		local secGroup = futuresList[row][1] --��� ���� �����, �������� BR ��� �����
		
		rowNum = window:AddRow({},'')--��������� ������ ������, ����� ������������� �������� �����
		
		window:SetValueByColName(rowNum, 'Account', '41105E5')
		window:SetValueByColName(rowNum, 'Depo', '41105E5')
		window:SetValueByColName(rowNum, 'Name', futuresList[row][1]) 
		window:SetValueByColName(rowNum, 'Ticker', futuresList[row][3]) --��� ������
		window:SetValueByColName(rowNum, 'Class', 'SPBFUT') --����� ������
		window:SetValueByColName(rowNum, 'Lot', futuresList[row][4]) --������ ���� ��� ��������
		window:SetValueByColName(rowNum, 'StartStop', 'Start')
		window:SetValueByColName(rowNum, 'BuyMarket', 'Buy')
		window:SetValueByColName(rowNum, 'SellMarket', 'Sell')
		
		window:SetValueByColName(rowNum, 'MA60name', secGroup ..'_grid_MA60')--��� ��� �� ����, �.�. � �������� ��������� ������� ���������� ���
		window:SetValueByColName(rowNum, 'PriceName', secGroup..'_grid_price')
		
		--����� �������� ����� ������� ���������� ������� GetColNumberByName()
		Green(window.hID, rowNum, window:GetColNumberByName('StartStop')) 
		Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
	end  

	--������

	local ETSList = secListETS() --��� ��������� ������
	
	--��������� ������ � ������������� � ������� ������
	for row=1, #ETSList do
		--DeleteRow(self.t.t_id, row)
		local secGroup = ETSList[row][1] --��� ���� �����, �������� BR ��� �����
		
		rowNum = window:AddRow({},'')--��������� ������ ������, ����� ������������� �������� �����
		
		window:SetValueByColName(rowNum, 'Account', '41105E5')
		window:SetValueByColName(rowNum, 'Depo', '41105E5')
		window:SetValueByColName(rowNum, 'Name', ETSList[row][1]) 
		window:SetValueByColName(rowNum, 'Ticker', ETSList[row][3]) --��� ������
		window:SetValueByColName(rowNum, 'Class', 'CETS') --����� ������
		window:SetValueByColName(rowNum, 'Lot', ETSList[row][4]) --������ ���� ��� ��������
		window:SetValueByColName(rowNum, 'StartStop', 'Start')
		window:SetValueByColName(rowNum, 'BuyMarket', 'Buy')
		window:SetValueByColName(rowNum, 'SellMarket', 'Sell')
		
		window:SetValueByColName(rowNum, 'MA60name', secGroup ..'_grid_MA60')--��� ��� �� ����, �.�. � �������� ��������� ������� ���������� ���
		window:SetValueByColName(rowNum, 'PriceName', secGroup..'_grid_price')
		
		--����� �������� ����� ������� ���������� ������� GetColNumberByName()
		Green(window.hID, rowNum, window:GetColNumberByName('StartStop')) 
		Green(window.hID, rowNum, window:GetColNumberByName('BuyMarket')) 
		Red(window.hID, rowNum, window:GetColNumberByName('SellMarket')) 
	end  
	
	
	
	
	
	SetTableNotificationCallback (window.hID, f_cb)

	--��� ������� ���� ��� �������� OnParam, ����� ��������� ��������� ��������
	
	for row=1, GetTableSize(window.hID) do
		--message(settings.secList[row][1])
		local class = window:GetValueByColName(row, 'Class').image
		local ticker = window:GetValueByColName(row, 'Ticker').image
		--message(tostring(ticker))
		OnParam( class, ticker )
	end
	
	--�������� 100 ����������� ����� ���������� 
	while is_run do
		sleep(5000)
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








