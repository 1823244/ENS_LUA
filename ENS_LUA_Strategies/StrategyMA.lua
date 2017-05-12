--немного комментариев для функции DoBusiness()
 --счетчик waiter нужен для того, чтобы не обработать один сигнал несколько раз.
 --поскольку позиция изменится не мгновенно после отправки заявки на сервер
 --(вот это условие "self.Position <= 0"), то нужен еще какой-то признак, чтобы
 --не отправлять все новые и новые заявки от момента поступления сигналадо 
 --момента изменения позиции.
 --waiter и есть такой признак.
 --после первого поступления сигнала делаем self.Waiter = 1
 --затем увеличиваем waiter до пяти, причем каждый инкремент выполняем, только если
--наступила новая секунда, из расчета, что за 5 сработок OnParam заявка исполнится и
--позиция по инструменту изменится.
--Если же заявка не исполнится за это время, то счетчик сбросится в ноль и нас ждет беда
-- - будет отправлена еще одна заявка.
--Вообще, ошибочных ситуаций может быть больше. 
--на примере перехода из шорта в лонг. для шорта аналогично, только знак числа и "больше/меньше" нужно развернуть
--1. заявка не исполнилась вообще
--2. заявка исполнилась частично, количество осталось меньше нуля (или равно)
--3. заявка исполнилась частично, количество стало больше нуля, но не достигло расчетного
--4. заявка исполнилась полностью - это не ошибка
--Попробуем подумать, что сделает робот в каждой ситуации
--1. отправит еще одну заявку с тем же количеством
--		когда (и если) исполнятся все заявки, позиция будет больше расчетной в n раз
--2. отправит еще одну заявку. количество зависит от размера получившейся позиции
--3. не будет отправлять новую заявку, т.к. сработает условие "self.Position <= 0"
--		размер позиции будет меньше расчетного
--Почему может не исполниться (не полностью исполниться) заявка?
--1. скачок котировок в направлении входа. выставили по цене х, а за пару миллисекунд цена ускакала сильно вверх/вниз
--2. разреженный стакан. нет достаточного количества бидов/асков по нужной цене
--3. неликвидный инструмент. скупили весь стакан.

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
  self.Ma1 = 0 --быстрая (короткая) средняя скользящая
  self.Ma2 = 0 --долгая (медленная) средняя скользящая
  self.Macd = 0
  self.Sar = 0
  self.Ma1Pred = 0 --быстрая (короткая) средняя скользящая
  self.Ma2Pred = 0 --долгая (медленная) средняя скользящая
  self.MacdPred = 0
  self.SarPred = 0
  self.ClosePred = 0
  self.Ma1Series = {} --быстрая (короткая) средняя скользящая
  self.Ma2Series = {} --долгая (медленная) средняя скользящая
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
   --таблица заявок, отправленных на сервер. если заявка есть в таблице, значит она еще не обработана
 --обработка заявки выполняется в OnTransReply(), OnTrade()
 --элемент таблицы - тоже таблица, с полями
 --signal_id - ключ. ид сигнала. он уникальный, т.к. каждый робот должен иметь свой идентификатор
 --trans_id - пользовательский ИД транзакции
 --qty - число, заполняется из LotToTrade - количество в заявке
 --order_num - номер заявки, который вернется с сервера и который затем будет указан в сделке. заполняется в OnTransReply
 --result - пока число, ответ от сервера биржи. заполняется в OnTransReply
 --запасные поля
 --direction - строка, buy/sell
 --filled_qty - число - количество, на которое исполнилась заявка
 --nil
 --nil
 --nil
 --nil
 --nil
 --пример 
 --self.sentOrders[signal_id]={trans_id = trans_id, qty= LotToTrade, order_num = nil, result = nil, direction = 'sell',nil,nil,nil,nil,nil,nil}  
 
 self.sentOrders={}
 
 
 
end

--**********************************************************************
--это основная функция. она вызывается из файла робота, из функции OnParam().
function Strategy:DoBisness()
  
  self:CalcLevels()
  
	--работа с режимом взята из аналогичного робота на QPILE
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
 

 
 --сигналы будут обрабатываться только если счетчик waiter равен нулю.
 --в противном случае (не равено нулю) это означает, что данный сигнал уже поступал и мы его обработали
 
	local s_signal_buy=false
	local s_signal_sell=false
	local signal_buy_id = nil
	local signal_sell_id = nil
  
  --пересечение снизу вверх - покупка
  s_signal_buy, signal_buy_id = self:signal_buy()
  
  if s_signal_buy == true 
	and self.Position <= 0 
	and self.Waiter == 0 
	--ENS Добавил это условие. Если будет режим шорт, с этим условием в лонг не зайдем
	and enter_quantity ~= 0 then 
	
    --начинаем увеличивать счетчик после обработки сигнала
	self.Waiter = 1

	--добавил работу с режимом. было так
    --self:Buy(self.LotToTrade - self.Position)
	--стало
	
	--если в таблице отправленных заявок уже есть этот ключ (ид сигнала), то больше не вызываем функцию покупки
	if self.sentOrders[signal_buy_id] == nil then
		
		logs:add(' Отладка. Обработка сигнала на покупку (первый раз. больше такого сообщения быть не должно! если есть - это ошибка в алгоритме): '..signal_buy_id)
		
		self:Buy(enter_quantity, signal_buy_id)
		
	else
		--for debug
		logs:add(' Отладка. Этот сигнал на покупку уже обработан: '..signal_buy_id)
	end
	
  end
  
  --пересечение сверху вниз - продажа
  s_signal_sell, signal_sell_id = self:signal_sell()
  if s_signal_sell == true
	and self.Position >= 0 
	and self.Waiter == 0
	--ENS Добавил это условие. Если будет режим лонг, с этим условием в шорт не зайдем	
    and exit_quantity ~= 0 then 
	
	self.Waiter = 1	--что делает этот флаг???
	
    --добавил работу с режимом. было так
	--self:Sell(self.LotToTrade + self.Position)
	--стало
	
	--если в таблице отправленных заявок уже есть этот ключ (ид сигнала), то больше не вызываем функцию продажи
	if self.sentOrders[signal_sell_id] == nil then
		logs:add(' Отладка. Обработка сигнала на продажу (первый раз. больше такого сообщения быть не должно! если есть - это ошибка в алгоритме): '..signal_buy_id)
		self:Sell(exit_quantity, signal_sell_id)
		
	else
		--for debug
		logs:add(' Отладка. Этот сигнал на продажу уже обработан: '..signal_sell_id)
	end
	
	
	--message("тест. продажа."..tostring(self.LotToTrade + self.Position).." лотов")
	
  end
  
  --свойство Second передается сюда из робота: strategy.Second=time.sec
  --оно означает, что в эту секунду было изменение цены инструмента (вызов OnParam)
  
  --Если waiter не ноль, т.е. уже были его изменения, и секунда не равна предыдущей секунде, т.е. уже были вызовы OnParam Тогда
  --увеличиваем счетчик waiter
  --запоминаем секунду вызова в свойстве PredSecond
  
  if self.Waiter ~= 0 and self.PredSecond ~= self.Second then
    self.Waiter = self.Waiter + 1
    self.PredSecond = self.Second
  end
  
  --сбрасываем счетчик
  if self.Waiter > 5 then
    self.Waiter = 0
  end
  
  self.PredLast = security.last
  
end

--**********************************************************************
--вызывается из этого же файла. Strategy:DoBisness()
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

	--создаем уникальный ИД сигнала. время без секунд
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

	--создаем уникальный ИД сигнала. время без секунд
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

--вызывается из этого же файла. Strategy:DoBisness()
function Strategy:Buy(LotToTrade, signal_id)
  message("Buy " .. settings.SecCodeBox, 1)
  
  logs:add('buy '.. settings.SecCodeBox)
  
  --transactions:order(settings.SecCodeBox, settings.ClassCode, "B", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) + 60 * security.minStepPrice), LotToTrade)
  
  local trans_id = transactions:CalcId()
  
  --transactions:orderWithId(settings.SecCodeBox, settings.ClassCode, "B", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) + 60 * security.minStepPrice), LotToTrade, trans_id)
  
  --добавим заявку в таблицу необработанных
  
  self.sentOrders[signal_id]={trans_id = trans_id, qty= LotToTrade, order_num = nil, result = nil, direction = 'buy',filled_qty=0,nil,nil,nil,nil,nil}  
  
  logs:add('order sent. trans_id = '..tostring(trans_id)..', qty = '..tostring(LotToTrade))
  
 end

--вызывается из этого же файла. Strategy:DoBisness()
function Strategy:Sell(LotToTrade, signal_id)
  
  message("Sell " .. settings.SecCodeBox, 1)
  
  logs:add('sell '.. settings.SecCodeBox)
  
  --transactions:order(settings.SecCodeBox, settings.ClassCode, "S", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) - 60 * security.minStepPrice), LotToTrade)
  
  local trans_id = transactions:CalcId()
  
  --transactions:orderWithId(settings.SecCodeBox, settings.ClassCode, "S", settings.ClientBox, settings.DepoBox, tostring(tonumber(security.last) - 60 * security.minStepPrice), LotToTrade, trans_id)
  
  --добавим заявку в таблицу необработанных
  
  self.sentOrders[signal_id]={trans_id = trans_id, qty= LotToTrade, order_num = nil, result = nil, direction = 'sell',filled_qty=0,nil,nil,nil,nil,nil}  
  
  logs:add('order sent. trans_id = '..tostring(trans_id)..', qty = '..tostring(LotToTrade))
  
end
