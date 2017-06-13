helper = {}
Settings = class(function(acc)
end)
function Settings:Init()

	--переключить по необходимости. настроено на ARQA
	local forts  = false

	if forts ~= true then
		self:initMICEX('11267', 'NL0011100043')
		self:initSBER()	
	else
		self:initFORTS('SPBFUT00f19')
		self:initSi()
	end
	
  self.rejim 					= 'revers' -- available options are 'long' / 'short' / 'revers'
  
  self.dbpath=getScriptPath().."\\positions.db"
  
  self.logFile = getScriptPath()..'\\log.txt'
  
  self.robot_id = 'ENS_OLE_LUA_MA60_M1'
  
  self.MAPeriod = 60 --период средней скольз€щей дл€ самосто€тельного расчета
    
  self.currency_CETS = '' --дл€ торговли валютами. сюда помещаем валюту валютной пары. так сделано, потому что позицию получаем из таблицы денег money_limits
  
  helper = Helper()
  helper:Init()
end

function Settings:initMICEX(client_code, depo_code)
  
  self.ClientBox 			= client_code
  self.DepoBox 				= depo_code
 
end

function Settings:initFORTS(client_code)

  self.DepoBox 				= client_code
  self.ClientBox 			= client_code
 
end

function Settings:initSBER()
  self.ClassCode 			= 'QJSIM'
  self.SecCodeBox 			= 'SBER' --example for FORTS: RIM7 (RTS-6.17)
  self.LotSizeBox 			= 20	--сколько контрактов/лотов торгует робот
  self.TypeLimitCombo 		= 'T0' --FORTS T0, MICEX T2, SELT T0 for TOD, T1 for TOM
  self.IdPriceCombo 		= 'ens_ole_sber_price' 	--идентификатор графика цены
  self.IdMA 				= 'ens_ole_sber_ma'		--идентификатор графика средней скольз€щей
  
  self.TableCaption 		= 'ENS OLE LUA - SBER M1'

end

function Settings:initSi()
  self.ClassCode 			= 'SPBFUT'
  self.SecCodeBox 			= 'SiM7' --example for FORTS: RIM7 (RTS-6.17)
  self.LotSizeBox 			= 20	--сколько контрактов/лотов торгует робот
  self.TypeLimitCombo 		= 'T0' --FORTS T0, MICEX T2, SELT T0 for TOD, T1 for TOM
  self.IdPriceCombo 		= 'ens_ole_sim7_price' 	--идентификатор графика цены
  self.IdMA 				= 'ens_ole_sim7_ma'		--идентификатор графика средней скольз€щей
  
  self.TableCaption 		= 'ENS OLE LUA - Si 6.17 M1'
end

function Settings:Load(path)
end
