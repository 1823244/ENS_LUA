MA="SMA"
 EMA="EMA"
 SMMA="SMMA"

Settings= {
Name = "!LUA_ADX",
Period=14,
Metod = EMA, --Metod: SMA, EMA, SMMA
MetodADX = EMA, --Metod: SMA, EMA, SMMA
Round = "0", --округление
line = {
   {
   Name = "LINE_ADX",
   Type = TYPE_LINE,
   Width  = 1,
   Color = RGB(0, 0, 255)
   },
   {
   Name = "LINE_ADX +DI",
   Type = TYPE_LINE,
   Width  = 1,
   Color = RGB(0, 255, 0)
   },
   {
   Name = "LINE_ADX -DI",
   Type = TYPE_LINE,
   Width  = 1,
   Color = RGB(255, 0, 0)
   }
   }
} 

function Init()
   F=ADX()
   return #Settings.line
end

function OnCalculate(Index)
   return F(Index, Settings)
end

--Average Directional Movement Index (ADX)
function ADX()
   local pDM_MA=MA()
   local mDM_MA=MA()
   local ATR_MA=MA()
   local ADX_MA=MA()
   local pDM={}
   local mDM={}
   local TR={}
   local DX={}
return function (Index, Settings)
local Settings=(Settings or {})
local N = (Settings.Period or 14)
local M = (Settings.Metod or EMA)
local MetodADX = (Settings.MetodADX or M)
if (Settings.Round=="") or (tonumber(Settings.Round)<0) then idp=nil else idp=tonumber(Settings.Round) end

if Index>1 then
   local dHigh = H(Index) - H(Index-1)
   local dLow = L(Index-1) - L(Index)
   if ((dHigh < 0) and (dLow < 0)) or (dHigh==dLow) then 
      pDM[Index-1] = 0
      mDM[Index-1] = 0
   end
   if (dHigh > dLow) then 
      pDM[Index-1] = dHigh
      mDM[Index-1] = 0
   end
   if (dHigh < dLow) then 
      pDM[Index-1] = 0
      mDM[Index-1] = dLow
   end

   --Average Directional Move Indicator
   local pAMD = pDM_MA(Index-1, {Period=N, Metod=M}, pDM, idp)
   local mADM = mDM_MA(Index-1, {Period=N, Metod=M}, mDM, idp)
   
   --True Range
   TR[Index-1] = math.max(math.abs(H(Index) - L(Index)), math.abs(H(Index) - C(Index-1)), math.abs(C(Index-1) - L(Index)))
   
   --Average True Range
   local ATR = ATR_MA(Index-1, {Period=N, Metod=M}, TR, idp)
   
   if Index > N then
      --Directional Index
      local pDI = round(100 * pAMD / ATR, idp)
      local mDI = round(100 * mADM / ATR, idp)

      --Directional Movement Index
      DX[Index-N] = 100 * math.abs(pDI-mDI) / (pDI+mDI)
      
      return ADX_MA(Index-N, {Period=N, Metod=MetodADX}, DX, idp),pDI,mDI
   else
      return nil,nil,nil
   end
else
   return nil,nil,nil
end
end
end

function MA()
local t_SMA=fSMA()
local t_EMA=fEMA()
local t_SMMA=fSMMA()
return function(Index, Settings, ds, idp)
   local Settings=(Settings or {})
   local P = (Settings.Period or 9)
   local M = (Settings.Metod or EMA)
   if M == SMA then
      return t_SMA(Index, P, ds, idp)
   elseif M == EMA then
      return t_EMA(Index, P, ds, idp)
   elseif M == SMMA then
      return t_SMMA(Index, P, ds, idp)
   else
      return nil
   end
end
end

------------------------------------------------------------------
--Скользящие средние (SMA, EMA, VMA, SMMA)
------------------------------------------------------------------
--[[Simple Moving Average (SMA)
SMA = sum(Pi) / n
]]
function fSMA()
return function (Index, Period, ds, idp) 
local Out = nil
   if Index >= Period then
      local sum = 0
      for i = Index-Period+1, Index do
         sum = sum +ds[i]
      end
      Out = sum/Period
   end 
   return round(Out,idp)
end
end

--[[Exponential Moving Average (EMA)
EMAi = (EMAi-1*(n-1)+2*Pi) / (n+1)
]]
function fEMA() 
local EMA_TMP={}
return function(Index, Period, ds, idp)
local Out = nil
   if Index == 1 then
      EMA_TMP[Index]=round(ds[Index],idp)
   else
      EMA_TMP[Index]=round((EMA_TMP[Index-1]*(Period-1)+2*ds[Index]) / (Period+1),idp)
      EMA_TMP[Index-2]=nil
   end
   
   if Index >= Period then
      Out = EMA_TMP[Index]
   end
   
   return round(Out,idp)
end
end

--[[Smoothed Moving Average (SMMA)
SMMAi = (sum(Pi) - SMMAi-1 + Pi) / n
]]
function fSMMA()
local SMMA_TMP={}
return function(Index, Period, ds, idp)
local Out = nil
   if Index >= Period then
      local sum = 0
      for i = Index-Period+1, Index do
         sum = sum +ds[i]
      end
      
      if Index == Period then
         SMMA_TMP[Index]=round(sum / Period, idp)
      else
         SMMA_TMP[Index]=round((sum - SMMA_TMP[Index-1] + ds[Index]) / Period, idp)
      end
      SMMA_TMP[Index-2]=nil
      Out = SMMA_TMP[Index]
   end
   return round(Out,idp)
end
end
------------------------------------------------------------------
--Вспомогательные функции
------------------------------------------------------------------
function round(num, idp)
if idp and num then
   local mult = 10^(idp or 0)
   if num >= 0 then return math.floor(num * mult + 0.5) / mult
   else return math.ceil(num * mult - 0.5) / mult end
else return num end
end
