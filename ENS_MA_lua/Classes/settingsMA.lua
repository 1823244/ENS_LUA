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
  self.IdMAShort = ""
  self.IdMALong = ""
  self.Path = ""
  self.TableCaption=""
  self.rejim=""
  self.logFile = ''
  
  helper = Helper()
  helper:Init()
end
function Settings:Load(path)
  self.DepoBox = 'SPBFUT009YQ' --BCS Demo
  self.ClientBox = 'SPBFUT009YQ'
  self.ClassCode = 'SPBFUT'
  self.SecCodeBox = 'RIH7' --RTS-3.17
  self.LotSizeBox = '1'
  self.TypeLimitCombo = 'T0'
  self.IdPriceCombo = 'RTS_price' 	--идентификатор графика
  self.IdMAShort = 'RTS_short'		--идентификатор графика
  self.IdMALong = 'RTS_long'			--идентификатор графика
  self.TableCaption = 'ENS MA LUA - RTS-3.17'
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
