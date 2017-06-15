--это класс для расчет экспоненциальной средней скользящей
MovingAverage = class(function(acc)
end)

local math_ceil = math.ceil
local math_floor = math.floor

function MovingAverage:Init()

  self.EMA_TMP = nil --массив рассчитанных свечей
  self.lastCandleMA = nil --последняя посчитанная свеча 
  
end

--свой расчет средней скользящей (чтобы терминал меньше занимал памяти, не будем добавлять на графики цен индикатор ЕМА, а посчитаем его сами)

--Period - период средней (количество свечей)
--lastCandle - последняя рассчитанная свеча (чтобы не считать все с нуля на каждом вызове)
function MovingAverage:ema(Period)

	--[1]Сначала мы получаем количество свечей. здесь: на графике цены
	local NumCandles = getNumCandles(settings.IdPriceCombo)	

--[[
В справке к Квику есть формула: 
EMAi = (EMAi-1 * (n-1) + 2*Pi) / (n+1), 
где Pi - значение цены в текущем периоде, 
EMAi - значение EMA текущего периода, 
EMAi-1 - значение EMA предыдущего периода 
Начальное значение равно параметру, по которому рассчитывается индикатор: EMA0=P0 – при расчете по цене 
--]]
	local tPrice = {}
	local n = 0
	local s = ''
	tPrice,n,s = getCandlesByIndex(settings.IdPriceCombo,0,0,NumCandles)		
	
	--пример работы со свечами
	--tPrice[number].datetime.hour
	--PriceSeries[0].close
	
	local answ = 0
	
	local idp = 11 --точность округлений (знаков после точки)
	local start = 0
	if self.lastCandleMA == nil then
		start = 0
	else
		start = self.lastCandleMA
	end
	for i = start, n-1 do
	
		self:fEMA(i, Period, tPrice, idp)
		
	end
	
	self.lastCandleMA = n-1
	
end

--[[Exponential Moving Average (EMA)
EMAi = (EMAi-1*(n-1)+2*Pi) / (n+1)
]]
--ds - DataSource - таблица свечек
--idp - точность округления
function MovingAverage:fEMA(Index, Period, ds, idp) 
	
	local Out = 0
	if Index == 0 then
		self.EMA_TMP[Index]=self:round(ds[Index].close,idp)
	else
		local prev_ema = self.EMA_TMP[(Index-1)]
		local candle = ds[Index]
		self.EMA_TMP[Index]=self:round((prev_ema*(Period-1)+2*candle.close) / (Period+1),idp)
	end

	if Index >= Period-1 then -- минус 1 - потому что идем от нуля
		Out = self.EMA_TMP[Index]
	end

	return self:round(Out,idp)
	
end

------------------------------------------------------------------
--Вспомогательные функции для EMA
------------------------------------------------------------------
function MovingAverage:round(num, idp)
if idp and num then
   local mult = 10^(idp or 0)
   if num >= 0 then return math_floor(num * mult + 0.5) / mult
   else return math_ceil(num * mult - 0.5) / mult end
else return num end
end


