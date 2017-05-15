local sqlite3 = require("lsqlite3")

local helper = {}
local settings = {}
--local sqlitework = {}
local logs = {}

Strategy = class(function(acc)
end)

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
  self.Ma1 = 0
  self.Ma2 = 0
  self.Macd = 0
  self.Sar = 0
  self.Ma1Pred = 0
  self.Ma2Pred = 0
  self.MacdPred = 0
  self.SarPred = 0
  self.ClosePred = 0
  self.Ma1Series = {}
  self.Ma2Series = {}
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
  
  self.PredClose = 0
  
  settings = Settings()
  settings:Init()  
	
  --sqlitework = SQLiteWork()
  --sqlitework:Init()  
	
	--message(settings.dbpath)
	
  logs = Logs()
  logs:Init()  
  
  helper = Helper()
  helper:Init()  

  self.db = nil --���� ��������� ������� � ���� ������ sqlite �� �������� ����� ������
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

--���������� �� ����� �� �����. Strategy:DoBisness()
function Strategy:CalcLevels()
  self.CurClose = tonumber(self.PriceSeries[0].close)
  self.Ma1 = self.Ma1Series[1].close						--���������� �����
  self.Ma1Pred = self.Ma1Series[0].close 	--ENS		--�������������� �����
end

--********************************************************************************
--********************************************************************************
--********************************************************************************
--********************************************************************************
--********************************************************************************
--������, ��� �������� �������. ��� ���������� �� ����� ������, �� ������� OnParam().
--********************************************************************************
--********************************************************************************
--********************************************************************************
--********************************************************************************
--********************************************************************************
function Strategy:DoBisness()

	--�������� ������� �������� ���� � ���������� ������
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

 
  --�������� ����� ���� ������� - �������
  if self:signal_buy() == true	then 
	
	if self:findSignal('buy')  == false then
		self:saveSignal('buy')
	end
	
	self:processSignal('buy')
 	
  end
  
  --�������� �������� ���� ������� - �������
  if self:signal_sell() == true	then 
	
	if self:findSignal('sell')  == false then
		self:saveSignal('sell')
	end
	
	self:processSignal('sell')
 	
  end

  --��� ���� ��� ���?
  self.PredLast = security.last
  self.PredClose = security.close
  
  --message('test')
  --self:test_insert_positions()
  
end

function Strategy:test_insert_positions(sig_id, direction, trans_id)

	local k = "'"
				  
	local flags = 64
	if direction == 'sell' then
		flags = 68
	end
	
local sql=' insert into positions ('..
'client_code'..
',depo_code'..
',trade_num'..
',sec_code'..
',class_code'..
',price'..
',qty'..
',date'..
',time'..
',robot_id'..
',signal_id'..
',direction'..
',order_num'..
',brokerref'..
',userid'..
',firmid'..
',account'..
',value'..
',flags'..
',trade_currency'..
',trans_id'..


')  VALUES ( '..


		''..k..settings.DepoBox..k..''..
		','..k..settings.ClientBox..k..''..
		',321654987'..
		','..k..settings.SecCodeBox..k..''..
		','..k..settings.ClassCode..k..''..
		',110800'..
		',2'..

		','..k..'2017-05-15'..k..''..
		','..k..'18:56:00'..k..''..
		','..k..settings.robot_id..k..''..
		','..k..sig_id..k..''..

		','..k..direction..k..''..
		 
		',0'..
		','..k..''..k..''..
		','..k..''..k..''..
		','..k..''..k..''..
		','..k..''..k..''..
		',2889'..
		','..tostring(flags)..
		','..k..'RUR'..k..
		','..tostring(trans_id)..
		');'
          --message(sql)                     
           self.db:exec(sql)  
		   
		  -- logs:add(sql)
end

function Strategy:signal_buy()
  if self.Ma1 ~= 0 
	and self.Ma1Pred  ~= 0 
	and self.PriceSeries[0].close ~= 0
	and self.PriceSeries[1].close ~= 0
	and self.PriceSeries[0].close < self.Ma1Pred --�������������� ��� ���� �������
	and self.PriceSeries[1].close > self.Ma1 --���������� ��� ���� �������
	then
	return true
  else
    return false
  end
end

function Strategy:signal_sell()
  if self.Ma1 ~= 0 
	and self.Ma1Pred  ~= 0 
	and self.PriceSeries[0].close ~= 0
	and self.PriceSeries[1].close ~= 0
	and self.PriceSeries[0].close > self.Ma1Pred --�������������� ��� ���� �������
	and self.PriceSeries[1].close < self.Ma1 --���������� ��� ���� �������
	then
	return true
  else
    return false
  end
end

function Strategy:checkNill(value)
  if value == 0 or value == nil then
    return true
  end
  return false
end

function Strategy:KillAll()
  killAllStopOrders(settings.SecCodeBox, settings.ClassCode)
  killAllOrders(settings.SecCodeBox, settings.ClassCode)
end

--���������� �� ����� �� �����. Strategy:DoBisness()
function Strategy:Buy(LotToTrade, trans_id)
  message("Buy " .. settings.SecCodeBox, 1)
  --transactions:order(settings.SecCodeBox, settings.ClassCode, "B", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) + 60 * security.minStepPrice), LotToTrade)
  transactions:orderWithId(settings.SecCodeBox, settings.ClassCode, "B", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) + 60 * security.minStepPrice), LotToTrade, trans_id)
end

--���������� �� ����� �� �����. Strategy:DoBisness()
function Strategy:Sell(LotToTrade, trans_id)
  message("Sell " .. settings.SecCodeBox, 1)
  --transactions:order        (settings.SecCodeBox, settings.ClassCode, "S", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) - 60 * security.minStepPrice), LotToTrade)
  transactions:orderWithId(settings.SecCodeBox, settings.ClassCode, "S", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) - 60 * security.minStepPrice), LotToTrade, trans_id)
  
end

--��������� ������ � ������� ��������.
function Strategy:saveSignal(direction)

	message('saveSignal')
	
	local k = "'"
	local sql = [[
	
		insert into signals (
			client_code,
			depo_code,
			robot_id,
			sec_code,
			class_code,
			price_id,
			MA_id,
			date,
			time,
			direction,
			processed,
			price_value,
			ma_value,
			price_pred_value,
			ma_pred_value
		)
		
		values
		(
		
			]]..k.. settings.ClientBox ..k.. [[ ,
			]]..k.. settings.DepoBox ..k.. [[ ,
			]]..k.. settings.robot_id ..k.. [[ ,
			]]..k.. settings.SecCodeBox ..k..[[,
			]]..k.. settings.ClassCode ..k..[[,
			]]..k.. settings.IdPriceCombo ..k..[[,
			]]..k.. settings.IdMA ..k..[[,
			]]..k.. helper:get_trade_date_sql(self.PriceSeries[1].datetime) ..k.. [[,
			]]..k.. self:GetTimeBar(1) ..k..[[,
			]]..k.. direction ..k..[[,
			0,
			]]..tostring(self.PriceSeries[1].close)..[[,
			]]..tostring(self.Ma1)..[[,
			]]..tostring(self.PriceSeries[0].close)..[[,
			]]..tostring(self.Ma1Pred)..[[
		
		)
		
	]]
	
	
	self.db:exec(sql)

end

--���� ������ � ����. ���� �� ����, ���������� ������
--��������� 
--	direction - ������, buy/sell
function Strategy:findSignal(direction)
	local k = "'"
	local sql = [[
	
		select 
			* 
		from 
			signals
		where

			client_code=	]]..k.. settings.ClientBox ..k.. 	[[ and
			depo_code=	]]..k.. settings.DepoBox ..k.. 		[[ and
			robot_id=		]]..k.. settings.robot_id ..k.. 		[[ and
			sec_code=		]]..k.. settings.SecCodeBox ..k..	[[ and
			class_code=	]]..k.. settings.ClassCode ..k..	[[ and
			price_id=		]]..k.. settings.IdPriceCombo ..k..[[ and
			MA_id=			]]..k.. settings.IdMA ..k..			[[ and
			date=			]]..k.. helper:get_trade_date_sql(self.PriceSeries[1].datetime) ..k.. [[ and
			time=				]]..k.. self:GetTimeBar(1) ..k..	[[ and
			direction = 		]]..k.. direction ..k
	
	local i = 0
	
	for row in self.db:nrows(sql) do
		i=i+1
		break
	end
	--message(tostring(i))
	if i ~= 0 then
		--������ ��� ����
		return true
	else
		return false
	end
		
end

--���� ������� � ����. ���� ��� ����, ���������� ���������� ����� (� �����/����������)
--��������� 
--	direction - ������, buy/sell
function Strategy:findPosition(sec_code, class_code, client_code, depo_code, robot_id)
	local k = "'"
	local sql = [[
	
		select 
			sec_code AS sec_code,
			class_code AS class_code,
			client_code AS client_code,
			depo_code AS depo_code,
			SUM(qty) AS qty
		from 
			positions
		where

			client_code=	]]..k.. client_code ..k.. 	[[ and
			depo_code=	]]..k.. depo_code ..k.. 	[[ and
			robot_id=		]]..k.. robot_id ..k.. 		[[ and
			sec_code=		]]..k.. sec_code ..k..	[[and
			class_code=	]]..k.. class_code ..k..	[[
			
		group by
			client_code,
			depo_code,
			robot_id,
			sec_code,
			class_code
		
		]]
	
	
 	for row in self.db:nrows(sql) do
		return row		
	end
	return nil
		
end

--���������� ������
function Strategy:processSignal(direction)

	message('process signal')
	--����� � ���� �������������� ������� � ��-������� �� ����������
	--���� �������, ��� � ���� ������ ������� ����� ���� ���� �������������� ������
	
	--��� ������ �� ������ ������ ������� ���� ��������� ������ (LIMIT 1)
	
	local k = "'"
	

		
		
			
			
	
	local sql = [[
	
		select 
			* 
		from 
			signals
		where

			client_code=	]]..k.. settings.ClientBox ..k.. 	[[ and
			depo_code=		]]..k.. settings.DepoBox ..k.. 		[[ and
			robot_id=		]]..k.. settings.robot_id ..k.. 		[[ and
			sec_code=		]]..k.. settings.SecCodeBox ..k..	[[ and
			class_code=		]]..k.. settings.ClassCode ..k..	[[ and
			direction = 	]]..k.. direction ..k..	[[ and
			processed=		0
		order by
			rownum DESC
		LIMIT 1
	]]
	
	local i = 0
	
	local safeCount = 0
	
	for row in self.db:nrows(sql) do
		i=i+1
		safeCount = safeCount+1
		if safeCount >= 50 then
			message('safely break loop in fn processSignal()')
			break
		end
		message('was found a signal: '..tostring(row.rownum))
		
		local sig_id = row.rownum
		 
		--����� ����������, �� ������� �����/���������� ����� ������� ������� - ��� � ���������� ������
		local LotsToPosition = tonumber(settings.LotSizeBox)
		
		--����������, ������� ��� �����/���������� ���� � ������� (� ������� �� ����� ������)
		local realPos = 0
		--��� ������ ����������		
		AlreadyInPosition = self:findPosition(settings.SecCodeBox, settings.ClassCode, settings.ClientBox, settings.DepoBox, settings.robot_id)
		if self:checkNill(AlreadyInPosition) then
			--no position
		else
			if AlreadyInPosition.qty < 0 then 
				realPos = -1*AlreadyInPosition.qty
			else
				realPos = AlreadyInPosition.qty
			end
		
		end
		
		local safeCount2 = 0
		
		message('real position is: ' .. tostring(realPos))
		
		--���� ��� �������� ����������, �� �������� ����
		if realPos < LotsToPosition then
			
			safeCount2 = safeCount2+1
			if safeCount2 >= 50 then
				message('safely break loop 2 in fn processSignal()')
				break
			end
			
			--������� ������
			
			local trans_id = helper:getMiliSeconds_trans_id()
			
			if direction == 'buy' then
				self:Buy(LotsToPosition - realPos, trans_id)
			elseif direction == 'sell' then
				self:Sell(LotsToPosition - realPos, trans_id)
			end
			
			--���������� trans_id � ������� transId
			
			sql = [[ 
			insert into transId (trans_id
				,signal_id
				,order_num
				,robot_id
				) 
			values (
			]]..tostring(trans_id)..[[
			,]]..tostring(sig_id)..[[
			,0
			,]]..k.. settings.robot_id ..k..[[
			)
			]]
			self.db:exec(sql)
			--logs:add(sql)
			
			--� �������� ������ ����� ��������� ������� �������
			--��� ����� ������ �� ������� OnTrade, ���������� ������ �� TRANSID
			
			--��� �������. �������� ������ � ���� positions
			--self:test_insert_positions(sig_id, direction, trans_id)
			
			--��� �������, ����� ������������ �� ����������
			--realPos = LotsToPosition
			
		end
		

		
		
		
	end
	
	if i==0 then
		message('no signals was found!')
	end
	
end

--�������� ������ �������
function Strategy:updateSignalStatus(sig_id, newStatus)

	local sql = 'update signals set processed = '..tostring(newStatus)..' where rownum = ' .. tostring(sig_id)
	
	self.db:exec(sql)

end

--��������� ������ �������, ��������� ��� ���
function Strategy:checkSignalStatus(sig_id)

	local sql = 'select processed from signals  where rownum = ' .. tostring(sig_id)
	
	for row in self.db:nrows(sql) do
		return row.processed
	end
	return nil
end

--���������� ������� ������� ���, ����: order_num, trans_id, qty
--����� ���� ���� ���������, ��� ������ � ������� ����� ����, �.�. trans_id ����� �������������� ���������� �� ������ ������
function Strategy:findOrders(trans_id)
	
local k = "'"
	local sql = [[
	
		select 
			order_num,
			qty
		from 
			orders
		where
			trans_id=	]].. tostring(trans_id)
			
	local i = 0
	
	returnTable = {}
	
	for row in self.db:nrows(sql) do
		returnTable[i]={}
		returnTable[i]['order_num']=row.order_num
		returnTable[i]['trans_id']=trans_id
		returnTable[i]['qty']=row.qty
		
		i=i+1
	end
	
	return returnTable
	
end