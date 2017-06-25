--��� ����� ��� ������ ���������������� ������� ����������
MovingAverage = class(function(acc)
end)

local math_ceil = math.ceil
local math_floor = math.floor

function MovingAverage:Init()

  self.EMA_TMP = nil --������ ������������ ������
  self.lastCandleMA = nil --��������� ����������� ����� 
  
end

--���� ������ ������� ���������� (����� �������� ������ ������� ������, �� ����� ��������� �� ������� ��� ��������� ���, � ��������� ��� ����)

--Period - ������ ������� (���������� ������)
--lastCandle - ��������� ������������ ����� (����� �� ������� ��� � ���� �� ������ ������)
function MovingAverage:ema(Period)

	--[1]������� �� �������� ���������� ������. �����: �� ������� ����
	local NumCandles = getNumCandles(settings.IdPriceCombo)	

--[[
� ������� � ����� ���� �������: 
EMAi = (EMAi-1 * (n-1) + 2*Pi) / (n+1), 
��� Pi - �������� ���� � ������� �������, 
EMAi - �������� EMA �������� �������, 
EMAi-1 - �������� EMA ����������� �������,
n - ������ ���������� ������� 
��������� �������� ����� ���������, �� �������� �������������� ���������: EMA0=P0 � ��� ������� �� ���� 
--]]
	local tPrice = {}
	local n = 0
	local s = ''
	tPrice,n,s = getCandlesByIndex(settings.IdPriceCombo,0,0,NumCandles)		
	
	--������ ������ �� �������
	--tPrice[number].datetime.hour
	--PriceSeries[0].close
	
	local answ = 0
	
	local idp = 11 --�������� ���������� (������ ����� �����)
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
--ds - DataSource - ������� ������
--idp - �������� ����������
function MovingAverage:fEMA(Index, Period, ds, idp) 
	
	local Out = 0
	if Index == 0 then
		self.EMA_TMP[Index]=self:round(ds[Index].close,idp)
	else
		local prev_ema = self.EMA_TMP[(Index-1)]
		local candle = ds[Index]
		self.EMA_TMP[Index]=self:round((prev_ema*(Period-1)+2*candle.close) / (Period+1),idp)
	end

	if Index >= Period-1 then -- ����� 1 - ������ ��� ���� �� ����
		Out = self.EMA_TMP[Index]
	end

	return self:round(Out,idp)
	
end

------------------------------------------------------------------
--��������������� ������� ��� EMA
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
    -- ���������:
    -- period - ������ ���������� �������
    -- get - ������� � ����� ���������� (����� � �������), ������������ �������� �������
    -- ���������� ������, ��� ��������� � �������� ����� �������������� ������ ����������� �������
    -- ��� ��������� ��������� ����� ���������� ��� ������������ ��������
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
	--���������, ��� ��� ��������. � �������� ��������� ������ ����� ������ ��������, ������ ���������� ����� ����� ����� 3.
	local data={1,3,5,7,9,2,4,6,8,0}
	local s = ma.ema(3, function(i) return data[i] end)
	-- ������ ����� 7 ������� ��� ��������� � ����������
	message("7".." ------------------- " .. tostring(s[7]))

	-- � ������ ��� ��������
	for i=1,#data do
		message(tostring(i).." ------------------- " .. tostring(s[i]))
	end

end
--]]