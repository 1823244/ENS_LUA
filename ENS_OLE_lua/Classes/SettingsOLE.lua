helper = {}
Settings = class(function(acc)
end)
function Settings:Init()
  self.DepoBox 			= '28216G8'
  self.ClientBox 			= '28216G8'
  self.ClassCode 			= 'SPBFUT'
  self.SecCodeBox 		= 'RIM7' --example for FORTS: RIM7 (RTS-6.17)
  self.LotSizeBox 			= '2'	--сколько контрактов/лотов торгует робот
  self.TypeLimitCombo 	= 'T0' --FORTS T0, MICEX T2, SELT T0 for TOD, T1 for TOM
  self.IdPriceCombo 		= 'RTS_price_20170512' 	--идентификатор графика цены
  self.IdMA 					= 'RTS_MA_TEST_20170512'		--идентификатор графика средней скользящей
  
  self.TableCaption 		= 'ENS OLE LUA - RIM7 M1'
  self.rejim 					= 'revers' -- available options are 'long' / 'short' / 'revers'
  
  self.dbpath=getScriptPath().."\\positions.db"
  
  self.logFile = getScriptPath()..'\\log.txt'
  
  self.robot_id = 'ENS_OLE_LUA_RTS_M1_MA60'
  
  --message(getScriptPath())
  
  helper = Helper()
  helper:Init()
end

function Settings:Load(path)
end
