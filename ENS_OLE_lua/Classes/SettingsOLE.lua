helper = {}
Settings = class(function(acc)
end)
function Settings:Init()
  self.DepoBox 			= 'NL0011100043'
  self.ClientBox 			= '10902'
  self.ClassCode 			= 'QJSIM'
  self.SecCodeBox 		= 'GAZP' --example for FORTS: RIM7 (RTS-6.17)
  self.LotSizeBox 			= 2	--сколько контрактов/лотов торгует робот
  self.TypeLimitCombo 	= 'T0' --FORTS T0, MICEX T2, SELT T0 for TOD, T1 for TOM
  self.IdPriceCombo 		= 'robot_01_ARQA_GAZP_M1_price' 	--идентификатор графика цены
  self.IdMA 					= 'robot_01_ARQA_GAZP_M1_MA60'		--идентификатор графика средней скользящей
  
  self.TableCaption 		= 'ENS OLE LUA - GAZP M1'
  self.rejim 					= 'revers' -- available options are 'long' / 'short' / 'revers'
  
  self.dbpath=getScriptPath().."\\positions.db"
  
  self.logFile = getScriptPath()..'\\log.txt'
  
  self.robot_id = 'ENS_OLE_LUA_GAZP_ARQA_M1_MA60'
  
  --message(getScriptPath())
  
  helper = Helper()
  helper:Init()
end

function Settings:Load(path)
end
