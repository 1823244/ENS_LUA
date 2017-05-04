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
  self.DepoBox = ''
  self.ClientBox = '41105E5'
  self.ClassCode = 'SPBFUT'
  self.SecCodeBox = 'MMH7' --MXI-3.17
  self.LotSizeBox = '2'
  self.TypeLimitCombo = 'T0'
  self.IdPriceCombo = 'MXI_price_60h' 	--идентификатор графика
  self.IdMA = 'MXI_MA_60h'		--идентификатор графика. 60 часов
  
  self.TableCaption = 'ENS OLE LUA - '
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
