local sqlite3 = require("lsqlite3")

local helper = {}
local settings = {}
--local sqlitework = {}
local logs = {}


local math_abs = math.abs

--этот флаг включается при возникновении нового сигнала и выключается после его полной обработки
local new_signal = false
local sig_id = nil
local waitForPosUpdate = false --глобальный флаг,при котором заявки не шлем,а ждем пока обновится позиция
 
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
  
  self.logstoscreen = nil
  
	
  self.db = nil --сюда передадим коннект к базе данных sqlite из главного файла робота 
  
  settings = Settings()
  settings:Init()  
	
  --sqlitework = SQLiteWork()
  --sqlitework:Init()  
	
	--message(settings.dbpath)
	
  logs = Logs()
  logs:Init()  
  
  helper = Helper()
  helper:Init()  


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

--вызывается из этого же файла. Strategy:DoBisness()
function Strategy:CalcLevels()
	--self.CurClose = tonumber(self.PriceSeries[0].close)
	if self.Ma1Series[1] ~= nil then
		self.Ma1 = self.Ma1Series[1].close						--предыдущая свеча
	end
	if self.Ma1Series[0] ~= nil then
		self.Ma1Pred = self.Ma1Series[0].close 	--ENS		--предпредыдущая свеча
	end
end

--********************************************************************************
--похоже, это основная функция. она вызывается из файла робота, из функции OnParam().
--********************************************************************************
function Strategy:DoBisness(test)

	--получить текущие значения цены и предыдущих свечей
	self:CalcLevels()
 
	-- self.logstoscreen:add('DoBisness: sig_id = '..tostring(sig_id))
	  
	  --пока включен этот глобальный флаг, проверяем результаты выставления заявок и совершения сделок
	if new_signal == true and sig_id ~= nil then
		--нужно посмотреть, на сколько лотов/контрактов нужно открыть позицию - это в настройках робота
		local LotsToPosition = tonumber(settings.LotSizeBox)
		
		--получим актуальную позицию	
		local realPos = trader:GetCurrentPosition(settings.SecCodeBox, settings.ClientBox)
		
		self.logstoscreen:add('DoBisness: real position is '..tostring(realPos))
		
		--после окончания добора в поле processed пишем число 1
		if math_abs( realPos ) >= LotsToPosition then
		
		--self.logstoscreen:add('DoBisness test 1:  sig_id is '..tostring(sig_id))
		
			self:updateSignalStatus(sig_id, 1)
			
			if self:checkSignalStatus(sig_id, 1) == 1 then
				--it is OK
				--выключаем флаг и ждем следующего сигнала
				new_signal = false
				sig_id = nil
			else
				--update failed. что делать???
				self.logstoscreen:add('fail to update signal status')
			end
		else
			--просто ждем окончания набора позиции
		end
		self.logstoscreen:add('new_signal = '..tostring(new_signal))
		
		
	else

		self.logstoscreen:add('new_signal is false ')
		
		 if test == true then
			sig_id = self:findSignal2()
				if sig_id  == false then
					sig_id = self:saveSignal('sell')
					self.logstoscreen:add('сохранили новый сигнал '..tostring(sig_id))
				else
					self.logstoscreen:add('нашли необработанный сигнал '..tostring(sig_id))
				end
				
				self:processSignal('sell')
				
				--включаем флаг, который выключим лишь после обработки сигнала
				new_signal = true
				self.logstoscreen:add('new_signal = '..tostring(new_signal))
		 else
		
		end
		
	end	
		
		

  
end

function Strategy:enterToPosition()
end

function checkSignal()


end

function Strategy:insert_positions(sig_id, direction, trade)

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


		''..k..tostring(settings.DepoBox)..k..''..
		','..k..settings.ClientBox..k..''..
		','..tostring(trade.trade_num)..
		','..k..settings.SecCodeBox..k..''..
		','..k..settings.ClassCode..k..''..
		','..tostring(trade.price)..
		','..tostring(trade.qty)..

		','..k..helper:get_trade_date_sql(trade.datetime)..k..''..
		','..k..helper:getHRTime2(trade.datetime)..k..''..
		','..k..settings.robot_id..k..''..
		','..k..sig_id..k..''..

		','..k..direction..k..''..
		 
		','..tostring(trade.order_num)..
		','..k..trade.brokerref..k..''..
		','..k..trade.userid..k..''..
		','..k..trade.firmid..k..''..
		','..k..trade.account..k..''..
		
		','..tostring(trade.value)..
		','..tostring(flags)..
		','..k..trade.trade_currency..k..
		','..tostring(trade.trans_id)..
		');'
          --message(sql)                     
           self.db:exec(sql)  
		   
		  -- logs:add(sql)
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


		''..k..tostring(settings.DepoBox)..k..''..
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

--вызывается из этого же файла. Strategy:DoBisness()
function Strategy:Buy(LotToTrade, trans_id)
  self.logstoscreen:add("Buy " .. settings.SecCodeBox)
  --transactions:order(settings.SecCodeBox, settings.ClassCode, "B", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) + 60 * security.minStepPrice), LotToTrade)
  transactions:orderWithId(settings.SecCodeBox, settings.ClassCode, "B", settings.ClientBox, tostring(settings.DepoBox), tostring(tonumber(security.last) + 60 * security.minStepPrice), LotToTrade, trans_id)
self.logstoscreen:add("transaction was sent "..helper:getMiliSeconds())
end

--вызывается из этого же файла. Strategy:DoBisness()
function Strategy:Sell(LotToTrade, trans_id)
  self.logstoscreen:add("Sell " .. settings.SecCodeBox)
  --transactions:order        (settings.SecCodeBox, settings.ClassCode, "S", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) - 60 * security.minStepPrice), LotToTrade)
  transactions:orderWithId(settings.SecCodeBox, settings.ClassCode, "S", settings.ClientBox, tostring(settings.DepoBox), tostring(tonumber(security.last) - 60 * security.minStepPrice), LotToTrade, trans_id)
  self.logstoscreen:add("transaction was sent "..helper:getMiliSeconds())
end

--сохраняет сигнал в таблицу сигналов.
function Strategy:saveSignal(direction)

	self.logstoscreen:add('saveSignal')
	
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

sql = [[
	
		select 
			rownum 
		from 
			signals
		order by
			rownum DESC
		limit 1		
		]]	
	for row in self.db:nrows(sql) do
		return row.rownum
		
	end
	return nil
end

--ищет сигнал в базе. если он есть, возвращает ИСТИНА
--параметры 
--	direction - строка, buy/sell
function Strategy:findSignal(direction)
	local k = "'"
	local sql = [[
	
		select 
			* 
		from 
			signals
		where

			client_code=	]]..k.. settings.ClientBox ..k.. 	[[ and
			depo_code=	]]..k.. tostring(settings.DepoBox) ..k.. 		[[ and
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
		--сигнал уже есть
		return true
	else
		return false
	end
		
end

--выбирает последний необработанный сигнал в базе
--параметры 
function Strategy:findSignal2()
	local k = "'"
	local sql = [[
	
		select 
			rownum 
		from 
			signals
		where

			client_code=	]]..k.. settings.ClientBox ..k.. 	[[
			and depo_code=	]]..k.. settings.DepoBox ..k.. 		[[
			and robot_id=		]]..k.. settings.robot_id ..k.. 		[[
			and sec_code=		]]..k.. settings.SecCodeBox ..k..	[[
			and class_code=	]]..k.. settings.ClassCode ..k..	[[
			and price_id=		]]..k.. settings.IdPriceCombo ..k..[[
			and MA_id=			]]..k.. settings.IdMA ..k..			[[
			and processed = 0
		order by
			rownum DESC
		limit 1
		
		]]
	
	for row in self.db:nrows(sql) do
		return row.rownum
	end
	return false
		
end

--обработать сигнал
function Strategy:processSignal(sig_id)
	
	self.logstoscreen:add('process signal')

	local k = "'"	
	local sql = [[
		select 
			rownum,
			direction
		from 
			signals
		where
			rownum=	]]..k.. tostring(sig_id) ..k.. 	[[
			and processed=		0
	]]
	
	local i = 0
	
	local safeCount = 0
	
	local direction = nil
	
	for row in self.db:nrows(sql) do
		i=i+1
		safeCount = safeCount+1
		if safeCount >= 50 then
			self.logstoscreen:add('safely break loop in fn processSignal()')
			logs:add('safely break loop in fn processSignal()')
			break
		end
		self.logstoscreen:add('was found a signal: '..tostring(row.rownum)..', direction '..row.direction)
		direction=row.direction
	end
	
	--нужно посмотреть, на сколько лотов/контрактов нужно открыть позицию - это в настройках робота
	local LotsToPosition = tonumber(settings.LotSizeBox)
	
	--посмотреть, сколько уже лотов/контрактов есть в позиции (с отбором по этому роботу)
	local realPos = trader:GetCurrentPosition(settings.SecCodeBox, settings.ClientBox)
	self.logstoscreen:add('real position is: ' .. tostring(realPos))
	
	local safeCount2 = 0
	
	
	--если эти значения отличаются, то добираем позу
	if math_abs(realPos) < LotsToPosition then
		
		--послать заявку
		
		local trans_id = helper:getMiliSeconds_trans_id()
		
		qty = LotsToPosition - math_abs(realPos)
		
		--!!!!!!!!!!!!для отладки. хочу проверить как будет отрабатывать ожидание добора позиции 
		qty = 1
		
		if row.direction == 'buy' then
			self:Buy(qty, trans_id)
		elseif row.direction == 'sell' then
			self:Sell(qty, trans_id)
		end
		
		--запоминаем trans_id в таблице transId
		
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
		
	else
		self.logstoscreen:add('вся позиция уже набрана, заявка не отправлена!')
		new_signal = false
	end
		
	
	if i==0 then
		self.logstoscreen:add('no signals was found!')
		new_signal = false
	end
	
end

--обновить статус сигнала
function Strategy:updateSignalStatus(sig_id, newStatus)

--message(sig_id)
	local sql = 'update signals set processed = '..tostring(newStatus)..' where rownum = ' .. tostring(sig_id)
	
	self.db:exec(sql)

end

--проверить статус сигнала, обработан или нет
function Strategy:checkSignalStatus(sig_id)

	--message(sig_id)
	local sql = 'select processed from signals  where rownum = ' .. tostring(sig_id)
	
	for row in self.db:nrows(sql) do
		return row.processed
	end
	return nil
end

--возвращает обычную таблицу луа, поля: order_num, trans_id, qty
--вроде пока есть понимание, что заявка в таблице будет одна, т.к. trans_id будет генерироваться уникальный на каждую заявку
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