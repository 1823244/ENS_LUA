helper = {}
Settings = class(function(acc)
end)
function Settings:Init()
  self.DepoBox = ""
  self.ClientBox = ""
  self.ClassCode = ""
  self.SecCodeBox = ""
  self.LotSizeBox = ""
  self.TypeLimitCombo = ""
  self.IdPriceCombo = ""
  self.IdMA = ""
  self.logFile = ""
  
  self.Path = ""
  self.TableCaption=""
  self.rejim=""
  helper = Helper()
  helper:Init()
end

function Settings:Load(path)
  self.DepoBox = '41105E5'
  self.ClientBox = '41105E5'
  self.ClassCode = 'SPBFUT'
 
  
  self.LotSizeBox 	= '2'
  self.TypeLimitCombo = 'T0'
  self.IdPriceCombo = 'MXI_price_60h' 	--идентификатор графика
  self.IdMA 		= 'MXI_MA_60h'		--идентификатор графика. 60 часов
  
  self.TableCaption = 'ENS OLE LUA - GRID all Futures'
  self.rejim 		= 'revers'
  self.Path 		= path
  
  self.logFile = getScriptPath()..'\\log.txt'
  

end
