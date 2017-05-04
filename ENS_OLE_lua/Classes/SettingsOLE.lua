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
  
  self.dbpath="d:\\TRADING\\PROJECTS\\ROBOTS\\DEV\\ENS_OLE_lua\\positions.db"
  
  helper = Helper()
  helper:Init()
end
function Settings:Load(path)
  self.DepoBox = 'NL0011100043'
  self.ClientBox = '10902'
  self.ClassCode = 'QJSIM'
  self.SecCodeBox = 'GAZP' --MXI-6.17
  self.LotSizeBox = '2'
  self.TypeLimitCombo = 'T2'
  self.IdPriceCombo = 'ENS_OLE_GAZP_M60_PRICE' 	--идентификатор графика
  self.IdMA = 'ENS_OLE_GAZP_M60_MA'		--идентификатор графика. 60 часов
  
  self.TableCaption = 'ENS OLE LUA - GAZP M60'
  self.rejim = 'revers'
  self.Path = path
  
  
  
  self.logFile = getScriptPath()..'\\log.txt'
  
	--[[
			local logfile = "c:\\TRAIDING\\ROBOTS\\DEMO\\ENS_MA_lua\\ARQA\\log.txt"
			Helper:AppendInFile(logfile, "----------------------------------------".."\n")
			--Helper:AppendInFile(logfile, "sec code: "..self.secCode.."\n")
			Helper:AppendInFile(logfile, "sec code: "..tostring(self.SecCodeBox).."\n")
			
			Helper:AppendInFile(logfile, "LotToTrade: "..tostring(self.LotSizeBox).."\n")	
			Helper:AppendInFile(logfile, "rejim: "..tostring(self.rejim).."\n")	
  --]]  
end
