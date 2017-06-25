--это класс дл€ расчет экспоненциальной средней скольз€щей
MovingAverage = class(function(acc)
end)

local math_ceil = math.ceil
local math_floor = math.floor

function MovingAverage:Init()

  self.EMA_TMP = nil --массив рассчитанных свечей
  self.lastCandleMA = nil --последн€€ посчитанна€ свеча 
  
end

--свой расчет средней скольз€щей (чтобы терминал меньше занимал пам€ти, не будем добавл€ть на графики цен индикатор ≈ћј, а посчитаем его сами)

--Period - период средней (количество свечей)
--lastCandle - последн€€ рассчитанна€ свеча (чтобы не считать все с нул€ на каждом вызове)
function MovingAverage:ema(Period)

	--[1]—начала мы получаем количество свечей. здесь: на графике цены
	local NumCandles = getNumCandles(settings.IdPriceCombo)	

--[[
¬ справке к  вику есть формула: 
EMAi = (EMAi-1 * (n-1) + 2*Pi) / (n+1), 
где Pi - значение цены в текущем периоде, 
EMAi - значение EMA текущего периода, 
EMAi-1 - значение EMA предыдущего периода,
n - период скольз€щей средней 
Ќачальное значение равно параметру, по которому рассчитываетс€ индикатор: EMA0=P0 Ц при расчете по цене 
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

--Exponential Moving Average (EMA)
--EMAi = (EMAi-1*(n-1)+2*Pi) / (n+1)
--ds - DataSource - таблица свечек
--idp - точность округлени€
function MovingAverage:fEMA(Index, Period, ds, idp) 
	
	local Out = 0
	if Index == 0 then
		self.EMA_TMP[Index]=self:round(ds[Index].close,idp)
	else
		local prev_ema = self.EMA_TMP[(Index-1)]
		local candle = ds[Index]
		self.EMA_TMP[Index]=self:round((prev_ema*(Period-1)+2*candle.close) / (Period+1),idp)
	end

	if Index >= Period-1 then -- минус 1 - потому что идем от нул€
		Out = self.EMA_TMP[Index]
	end

	return self:round(Out,idp)
	
end

------------------------------------------------------------------
--¬спомогательные функции дл€ EMA
------------------------------------------------------------------
function MovingAverage:round(num, idp)
if idp and num then
   local mult = 10^(idp or 0)
   if num >= 0 then return math_floor(num * mult + 0.5) / mult
   else return math_ceil(num * mult - 0.5) / mult end
else return num end
end

--[[
MovingAverage.ma =
{
    -- Exponential Moving Average (EMA)
    -- EMA[i] = (EMA[i]-1*(per-1)+2*X[i]) / (per+1)
    -- ѕараметры:
    -- period - ѕериод скольз€щей средней
    -- get - функци€ с одним параметром (номер в выборке), возвращающа€ значение выборки
    -- ¬озвращает массив, при обращению к которому будет рассчитыватьс€ только необходимый элемент
    -- ѕри повторном обращении будет возвращено уже рассчитанное значение
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


--[[

function main()
	--ѕопробуем, как оно работает. ¬ качестве источника данных берем массив значений, период усреднени€ пусть будет равен 3.
	local data={1,3,5,7,9,2,4,6,8,0}
	local s = ma.ema(3, function(i) return data[i] end)
	-- ¬водим сразу 7 элемент без обращени€ к предыдущим
	message("7".." ------------------- " .. tostring(s[7]))

	-- ј теперь все значени€
	for i=1,#data do
		message(tostring(i).." ------------------- " .. tostring(s[i]))
	end

end
--]]