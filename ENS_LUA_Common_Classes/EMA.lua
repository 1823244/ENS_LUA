 --��� ����� ��� ������� ���������������� ������� ����������
MovingAverage = class(function(acc)
end)

local math_ceil = math.ceil
local math_floor = math.floor

function MovingAverage:Init()

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

	local EMA_Array = {}
	
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


--ds - DataSource - ������� ������ ���������� �������� CreateDataSource()
--Period - ������ ������� (���������� ������)
--lastCandle - ��������� ������������ ����� (����� �� ������� ��� � ���� �� ������ ������)
function MovingAverage:emaDS(EMA_Array, DataSource, Period, lastCandle)

	local NumCandles = DataSource:Size()	

--[[
� ������� � ����� ���� �������: 
EMAi = (EMAi-1 * (period-1) + 2*Pi) / (period+1), 
��� Pi - �������� ���� � ������� �������, 
EMAi - �������� EMA �������� �������, 
EMAi-1 - �������� EMA ����������� �������,
period - ������ ���������� ������� 
��������� �������� ����� ���������, �� �������� �������������� ���������: EMA0=P0 � ��� ������� �� ���� 
--]]

	
	
	local idp = 11 --�������� ���������� (������ ����� �����)
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
--idp - �������� ����������
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

--ds - DataSource - ������� ������ ���������� �������� CreateDataSource()
--idp - �������� ����������
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
--��������������� ������� ��� EMA
------------------------------------------------------------------
function MovingAverage:round(num, idp)
if idp and num then
   local mult = 10^(idp or 0)
   if num >= 0 then return math_floor(num * mult + 0.5) / mult
   else return math_ceil(num * mult - 0.5) / mult end
else return num end
end

--[[ ��� �� ������ ��� ������ ������� ������� ���������
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


--[[function main()
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