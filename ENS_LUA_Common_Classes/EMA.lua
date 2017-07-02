 --это класс для расчета экспоненциальной средней скользящей
MovingAverage = class(function(acc)
end)

local math_ceil = math.ceil
local math_floor = math.floor

function MovingAverage:Init()

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
EMAi-1 - значение EMA предыдущего периода,
n - период скользящей средней 
Начальное значение равно параметру, по которому рассчитывается индикатор: EMA0=P0 – при расчете по цене 
--]]

	local EMA_Array = {}
	
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


--ds - DataSource - таблица свечек полученная функцией CreateDataSource()
--Period - период средней (количество свечей)
--lastCandle - последняя рассчитанная свеча (чтобы не считать все с нуля на каждом вызове)
function MovingAverage:emaDS(EMA_Array, DataSource, Period, lastCandle)

	local NumCandles = DataSource:Size()	

--[[
В справке к Квику есть формула: 
EMAi = (EMAi-1 * (period-1) + 2*Pi) / (period+1), 
где Pi - значение цены в текущем периоде, 
EMAi - значение EMA текущего периода, 
EMAi-1 - значение EMA предыдущего периода,
period - период скользящей средней 
Начальное значение равно параметру, по которому рассчитывается индикатор: EMA0=P0 – при расчете по цене 
--]]

	
	
	local idp = 11 --точность округлений (знаков после точки)
	local start = 1
	if lastCandle == nil or lastCandle == 0 or lastCandle == 1 then
		start = 1
	else
		start = lastCandle
	end
	for i = start, DataSource:Size() do
	
		self:fEMAds(EMA_Array, i, Period, DataSource, idp)
		
	end
	
	lastCandle = DataSource:Size()
	
	return EMA_Array, lastCandle
	
end



--ds - DataSource - getCandlesByIndex()
--idp - точность округления
function MovingAverage:fEMA(EMA_Array, Index, Period, ds, idp) 
	
	local Out = 0
	if Index == 0 then
		EMA_Array[Index]=self:round(ds[Index].close,idp)
	else
		local prev_ema = EMA_Array[(Index-1)]
		EMA_Array[Index]=self:round((prev_ema*(Period-1)+2*ds[Index].close) / (Period+1),idp)
	end

	if Index >= Period then
		Out = EMA_Array[Index]
	end

	return self:round(Out,idp)
	
end

--ds - DataSource - таблица свечек полученная функцией CreateDataSource()
--idp - точность округления
function MovingAverage:fEMAds(EMA_Array, Index, Period, ds, idp) 
	
	local Out = 0
	if Index == 0 or Index == 1 then
		EMA_Array[1]=self:round(ds:C(1),idp)
	else
		local prev_ema = EMA_Array[(Index-1)]
		EMA_Array[Index]=self:round((prev_ema*(Period-1)+2*ds:C(Index)) / (Period+1),idp)
	end

	if Index >= Period then
		Out = EMA_Array[Index]
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

--[[ это из статьи про расчет средней методом кофеварки
MovingAverage.ma =
{
    -- Exponential Moving Average (EMA)
    -- EMA[i] = (EMA[i]-1*(per-1)+2*X[i]) / (per+1)
    -- Параметры:
    -- period - Период скользящей средней
    -- get - функция с одним параметром (номер в выборке), возвращающая значение выборки
    -- Возвращает массив, при обращению к которому будет рассчитываться только необходимый элемент
    -- При повторном обращении будет возвращено уже рассчитанное значение
    ema =
        function(period,get) 
            return setmetatable( 
                        {},
                        { __index = function(tbl,indx)
                                              if indx == 1 then
                                                  tbl[indx] = get(1)
                                              else
                                                  tbl[indx] = (tbl[indx-1] * (period-1) + 2 * get(indx)) / (period + 1)
                                              end
                                              return tbl[indx]
                                            end
                        })
       end
}
--]]


--[[function main()
	--Попробуем, как оно работает. В качестве источника данных берем массив значений, период усреднения пусть будет равен 3.
	local data={1,3,5,7,9,2,4,6,8,0}
	local s = ma.ema(3, function(i) return data[i] end)
	-- Вводим сразу 7 элемент без обращения к предыдущим
	message("7".." ------------------- " .. tostring(s[7]))

	-- А теперь все значения
	for i=1,#data do
		message(tostring(i).." ------------------- " .. tostring(s[i]))
	end

end
--]]