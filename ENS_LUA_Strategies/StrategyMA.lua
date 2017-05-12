--������� ������������ ��� ������� DoBusiness()
 --������� waiter ����� ��� ����, ����� �� ���������� ���� ������ ��������� ���.
 --��������� ������� ��������� �� ��������� ����� �������� ������ �� ������
 --(��� ��� ������� "self.Position <= 0"), �� ����� ��� �����-�� �������, �����
 --�� ���������� ��� ����� � ����� ������ �� ������� ����������� ��������� 
 --������� ��������� �������.
 --waiter � ���� ����� �������.
 --����� ������� ����������� ������� ������ self.Waiter = 1
 --����� ����������� waiter �� ����, ������ ������ ��������� ���������, ������ ����
--��������� ����� �������, �� �������, ��� �� 5 �������� OnParam ������ ���������� �
--������� �� ����������� ���������.
--���� �� ������ �� ���������� �� ��� �����, �� ������� ��������� � ���� � ��� ���� ����
-- - ����� ���������� ��� ���� ������.
--������, ��������� �������� ����� ���� ������. 
--�� ������� �������� �� ����� � ����. ��� ����� ����������, ������ ���� ����� � "������/������" ����� ����������
--1. ������ �� ����������� ������
--2. ������ ����������� ��������, ���������� �������� ������ ���� (��� �����)
--3. ������ ����������� ��������, ���������� ����� ������ ����, �� �� �������� ����������
--4. ������ ����������� ��������� - ��� �� ������
--��������� ��������, ��� ������� ����� � ������ ��������
--1. �������� ��� ���� ������ � ��� �� �����������
--		����� (� ����) ���������� ��� ������, ������� ����� ������ ��������� � n ���
--2. �������� ��� ���� ������. ���������� ������� �� ������� ������������ �������
--3. �� ����� ���������� ����� ������, �.�. ��������� ������� "self.Position <= 0"
--		������ ������� ����� ������ ����������
--������ ����� �� ����������� (�� ��������� �����������) ������?
--1. ������ ��������� � ����������� �����. ��������� �� ���� �, � �� ���� ����������� ���� �������� ������ �����/����
--2. ����������� ������. ��� ������������ ���������� �����/����� �� ������ ����
--3. ����������� ����������. ������� ���� ������.

--

--buy RIH7 at 18:04:58
--values of MA at this moment:
--Ma1Pred = 106735.67411281
--Ma2Pred = 106736.30168594
--Ma1 = 106750.53929025
--Ma2 = 106740.28537859

--**********************************************************************
Strategy = class(function(acc)
end)

--**********************************************************************
function Strategy:Init()
  self.FractalSeries = {}
  self.PriceSeries = {}
  self.Range = 0
  self.Stop = 0
  self.SetStop = 0
  self.Position = 0
  self.PredPosition = 0
  self.Reversed = 0
  self.Waiter = 0
  self.TimeToClose = 0
  self.Level = 0
  self.High = 0
  self.CurBar = ""
  self.PredBar = ""
  self.Diff = 0
  self.TimeFrame = 0
  self.NextBar = 0
  self.Close = 0
  self.Seconds = 0
  self.LastCandle = {}
  self.predTime = 0
  self.BuyLevel = 0
  self.SellLevel = 0
  self.Resultat = 0
  self.NextLot = 0
  self.CurTime = 0
  self.CurTimeStr = 0
  self.Resultat = 0
  self.Second = 0
  self.PredSecond = 0
  self.stopLevel = 0
  self.N = 0
  self.CurClose = 0
  self.LotToTrade = 0
  self.perm = 1
  self.BarEnter = 0
  self.Ma1 = 0 --������� (��������) ������� ����������
  self.Ma2 = 0 --������ (���������) ������� ����������
  self.Macd = 0
  self.Sar = 0
  self.Ma1Pred = 0 --������� (��������) ������� ����������
  self.Ma2Pred = 0 --������ (���������) ������� ����������
  self.MacdPred = 0
  self.SarPred = 0
  self.ClosePred = 0
  self.Ma1Series = {} --������� (��������) ������� ����������
  self.Ma2Series = {} --������ (���������) ������� ����������
  self.MacdSeries = {}
  self.SarSeries = {}
  self.Exit = ""
  self.NumCandles = 0
  self.FractalUp1Price = 0
  self.FractalUp1Time = 0
  self.FractalUp2Price = 0
  self.FractalUp2Time = 0
  self.FractalDown1Price = 0
  self.FractalDown1Time = 0
  self.FractalDown2Price = 0
  self.FractalDown2Time = 0
  self.UpCounter = 0
  self.DownCounter = 0
  self.UpCurCounter = 0
  self.DownCurCounter = 0
  self.DeltaDownTrend = 0
  self.DeltaUpTrend = 0
  self.DeltaDownKoef = 0
  self.DeltaUpKoef = 0
  self.UpTrend = 0
  self.DownTrend = 0
  self.PredLast = 0
  self.BBUp = 0
  self.BBDown = 0
 
--ENS 
   --������� ������, ������������ �� ������. ���� ������ ���� � �������, ������ ��� ��� �� ����������
 --��������� ������ ����������� � OnTransReply(), OnTrade()
 --������� ������� - ���� �������, � ������
 --signal_id - ����. �� �������. �� ����������, �.�. ������ ����� ������ ����� ���� �������������
 --trans_id - ���������������� �� ����������
 --qty - �����, ����������� �� LotToTrade - ���������� � ������
 --order_num - ����� ������, ������� �������� � ������� � ������� ����� ����� ������ � ������. ����������� � OnTransReply
 --result - ���� �����, ����� �� ������� �����. ����������� � OnTransReply
 --�������� ����
 --direction - ������, buy/sell
 --filled_qty - ����� - ����������, �� ������� ����������� ������
 --nil
 --nil
 --nil
 --nil
 --nil
 --������ 
 --self.sentOrders[signal_id]={trans_id = trans_id, qty= LotToTrade, order_num = nil, result = nil, direction = 'sell',nil,nil,nil,nil,nil,nil}  
 
 self.sentOrders={}
 
 
 
end

--**********************************************************************
--��� �������� �������. ��� ���������� �� ����� ������, �� ������� OnParam().
function Strategy:DoBisness()
  
  self:CalcLevels()
  
	--������ � ������� ����� �� ������������ ������ �� QPILE
	local enter_quantity= 0
	local exit_quantity	= 0
  
    if settings.rejim == "revers" then
        enter_quantity	= self.LotToTrade 	- self.Position
        exit_quantity	= self.LotToTrade	+ self.Position
    end
 
	if settings.rejim == "long" then
        enter_quantity	= self.LotToTrade	- self.Position
        exit_quantity	= self.Position
    end
 
    if settings.rejim == "short" then
        enter_quantity	= -self.Position
        exit_quantity	= self.LotToTrade	+ self.Position
    end
 

 
 --������� ����� �������������� ������ ���� ������� waiter ����� ����.
 --� ��������� ������ (�� ������ ����) ��� ��������, ��� ������ ������ ��� �������� � �� ��� ����������
 
	local s_signal_buy=false
	local s_signal_sell=false
	local signal_buy_id = nil
	local signal_sell_id = nil
  
  --����������� ����� ����� - �������
  s_signal_buy, signal_buy_id = self:signal_buy()
  
  if s_signal_buy == true 
	and self.Position <= 0 
	and self.Waiter == 0 
	--ENS ������� ��� �������. ���� ����� ����� ����, � ���� �������� � ���� �� ������
	and enter_quantity ~= 0 then 
	
    --�������� ����������� ������� ����� ��������� �������
	self.Waiter = 1

	--������� ������ � �������. ���� ���
    --self:Buy(self.LotToTrade - self.Position)
	--�����
	
	--���� � ������� ������������ ������ ��� ���� ���� ���� (�� �������), �� ������ �� �������� ������� �������
	if self.sentOrders[signal_buy_id] == nil then
		
		logs:add(' �������. ��������� ������� �� ������� (������ ���. ������ ������ ��������� ���� �� ������! ���� ���� - ��� ������ � ���������): '..signal_buy_id)
		
		self:Buy(enter_quantity, signal_buy_id)
		
	else
		--for debug
		logs:add(' �������. ���� ������ �� ������� ��� ���������: '..signal_buy_id)
	end
	
  end
  
  --����������� ������ ���� - �������
  s_signal_sell, signal_sell_id = self:signal_sell()
  if s_signal_sell == true
	and self.Position >= 0 
	and self.Waiter == 0
	--ENS ������� ��� �������. ���� ����� ����� ����, � ���� �������� � ���� �� ������	
    and exit_quantity ~= 0 then 
	
	self.Waiter = 1	--��� ������ ���� ����???
	
    --������� ������ � �������. ���� ���
	--self:Sell(self.LotToTrade + self.Position)
	--�����
	
	--���� � ������� ������������ ������ ��� ���� ���� ���� (�� �������), �� ������ �� �������� ������� �������
	if self.sentOrders[signal_sell_id] == nil then
		logs:add(' �������. ��������� ������� �� ������� (������ ���. ������ ������ ��������� ���� �� ������! ���� ���� - ��� ������ � ���������): '..signal_buy_id)
		self:Sell(exit_quantity, signal_sell_id)
		
	else
		--for debug
		logs:add(' �������. ���� ������ �� ������� ��� ���������: '..signal_sell_id)
	end
	
	
	--message("����. �������."..tostring(self.LotToTrade + self.Position).." �����")
	
  end
  
  --�������� Second ���������� ���� �� ������: strategy.Second=time.sec
  --��� ��������, ��� � ��� ������� ���� ��������� ���� ����������� (����� OnParam)
  
  --���� waiter �� ����, �.�. ��� ���� ��� ���������, � ������� �� ����� ���������� �������, �.�. ��� ���� ������ OnParam �����
  --����������� ������� waiter
  --���������� ������� ������ � �������� PredSecond
  
  if self.Waiter ~= 0 and self.PredSecond ~= self.Second then
    self.Waiter = self.Waiter + 1
    self.PredSecond = self.Second
  end
  
  --���������� �������
  if self.Waiter > 5 then
    self.Waiter = 0
  end
  
  self.PredLast = security.last
  
end

--**********************************************************************
--���������� �� ����� �� �����. Strategy:DoBisness()
function Strategy:CalcLevels()
  --self.CurClose = tonumber(self.PriceSeries[0].close)
  
  localTime  = tostring(helper:getHRTime2())
  
  --for debug
  if self.Ma1 ~= self.Ma1Series[1].close then
	logs:add('Ma1 has changed. Old = '..tostring(self.Ma1) ..', new = ' .. tostring(self.Ma1Series[1].close))
  end
  self.Ma1 = self.Ma1Series[1].close
  
  --for debug
  if self.Ma2 ~= self.Ma2Series[1].close then
	logs:add('Ma2 has changed. Old = '..tostring(self.Ma2) ..', new = ' .. tostring(self.Ma2Series[1].close))
  end
  self.Ma2 = self.Ma2Series[1].close
  
  --for debug
  if self.Ma1Pred ~= self.Ma1Series[0].close then
	logs:add('Ma1Pred has changed. Old = '..tostring(self.Ma1Pred) ..', new = ' .. tostring(self.Ma1Series[0].close))
  end  
  self.Ma1Pred = self.Ma1Series[0].close 	--ENS
  
  --for debug
  if self.Ma2Pred ~= self.Ma2Series[0].close then
	logs:add('Ma2Pred has changed. Old = '..tostring(self.Ma2Pred) ..', new = ' .. tostring(self.Ma2Series[0].close))
  end  
  self.Ma2Pred = self.Ma2Series[0].close	--ENS
  
end

--**********************************************************************
function Strategy:signal_buy()

	--������� ���������� �� �������. ����� ��� ������
	local signal_id = tostring(os.date('%Y%m%d')) ..'_' .. tostring(helper:getHRTime5()) ..'_'.. security.class ..'_'..security.code..'_'..tostring(settings.robot_id)
	
  if self.Ma1 ~= 0 
	and self.Ma1Pred  ~= 0 
	and self.Ma2 ~= 0
	and self.Ma2Pred  ~= 0
	and self.PredLast ~= 0
	and security.last ~= 0
	and self.Ma1Pred < self.Ma2Pred -- previous. short less than long
	and self.Ma1 > self.Ma2 --current. short greater than long
  then
	return true, signal_id
  else
	return false, signal_id
  end
end

--**********************************************************************
function Strategy:signal_sell()

	--������� ���������� �� �������. ����� ��� ������
	local signal_id = tostring(os.date('%Y%m%d')) ..'_' .. tostring(helper:getHRTime5()) ..'_'.. security.class ..'_'..security.code..'_'..tostring(settings.robot_id)

  if self.Ma1 ~= 0 
	and self.Ma1Pred  ~= 0 
	and self.Ma2 ~= 0
	and self.Ma2Pred  ~= 0
	and self.PredLast ~= 0
	and security.last ~= 0
	and self.Ma1Pred > self.Ma2Pred -- previous. short greater than long
	and self.Ma1 < self.Ma2 --current. short less than long
	then
	return true, signal_id
  else
	return false, signal_id
  end
end

--**********************************************************************
function Strategy:checkNill(value)
  if value == 0 or value == nil then
    return true
  end
  return false
end

function Strategy:SetSeries(priceSeries)
  if self:checkNill(priceSeries) then
    logMemo:Add("No data!")
  end
  self.PriceSeries = priceSeries
end

function AddZero(value)
  if string.len(tostring(value)) < 10 then
    value = "0" .. value
  end
  return tostring(value)
end

function Strategy:CheckNewCandle(lastCandle)
  if LastCandle ~= {} and LastCandle ~= nil and LastCandle.day * LastCandle.hour * LastCandle.min ~= lastCandle.day * lastCandle.hour * lastCandle.min then
    LastCandle = lastCandle
    return true
  end
  LastCandle = lastCandle
  return false
end

function Strategy:CheckIfNotEntryBar()
  if self.BarEnter == self.PriceSeries[0].datetime.hour * 100 + self.PriceSeries[0].datetime.min then
    return false
  end
  return true
end

function Strategy:GetTimeBar(number)
  hour = self.PriceSeries[number].datetime.hour
  minute = self.PriceSeries[number].datetime.min
  if hour < 10 then
    hour = "0" .. hour
  end
  if minute < 10 then
    minute = "0" .. minute
  end
  return tostring(hour) .. ":" .. tostring(minute)
end

function Strategy:addLog(mess)
  logMemo:Add(self.CurTimeStr .. " " .. mess)
end

function Strategy:KillAll()
  killAllStopOrders(settings.SecCodeBox, settings.ClassCode)
  killAllOrders(settings.SecCodeBox, settings.ClassCode)
end

--���������� �� ����� �� �����. Strategy:DoBisness()
function Strategy:Buy(LotToTrade, signal_id)
  message("Buy " .. settings.SecCodeBox, 1)
  
  logs:add('buy '.. settings.SecCodeBox)
  
  --transactions:order(settings.SecCodeBox, settings.ClassCode, "B", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) + 60 * security.minStepPrice), LotToTrade)
  
  local trans_id = transactions:CalcId()
  
  --transactions:orderWithId(settings.SecCodeBox, settings.ClassCode, "B", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) + 60 * security.minStepPrice), LotToTrade, trans_id)
  
  --������� ������ � ������� ��������������
  
  self.sentOrders[signal_id]={trans_id = trans_id, qty= LotToTrade, order_num = nil, result = nil, direction = 'buy',filled_qty=0,nil,nil,nil,nil,nil}  
  
  logs:add('order sent. trans_id = '..tostring(trans_id)..', qty = '..tostring(LotToTrade))
  
 end

--���������� �� ����� �� �����. Strategy:DoBisness()
function Strategy:Sell(LotToTrade, signal_id)
  
  message("Sell " .. settings.SecCodeBox, 1)
  
  logs:add('sell '.. settings.SecCodeBox)
  
  --transactions:order(settings.SecCodeBox, settings.ClassCode, "S", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) - 60 * security.minStepPrice), LotToTrade)
  
  local trans_id = transactions:CalcId()
  
  --transactions:orderWithId(settings.SecCodeBox, settings.ClassCode, "S", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) - 60 * security.minStepPrice), LotToTrade, trans_id)
  
  --������� ������ � ������� ��������������
  
  self.sentOrders[signal_id]={trans_id = trans_id, qty= LotToTrade, order_num = nil, result = nil, direction = 'sell',filled_qty=0,nil,nil,nil,nil,nil}  
  
  logs:add('order sent. trans_id = '..tostring(trans_id)..', qty = '..tostring(LotToTrade))
  
end
