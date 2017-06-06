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
  self.ClientBox = '1234567'
  self.ClassCode = 'SPBFUT'
  
  
  self.secList = {} --таблица инструментов. там 3 колонки, код вида фьюча, код фьюча и количество контрактов
  --код вида фьюча нужен дл€ идентификации скольз€щей средней
  
  --раз в квартал мен€ть код мес€ца
  
  --индексы
  self.secList[1]={'RI', 'RIM7', 2} --RTS
  self.secList[2]={'MX', 'MXM7', 2} --ћћ¬Ѕ обычный
  self.secList[3]={'MM', 'MMM7', 2} --ћћ¬Ѕ мини
  
  --валюты
  self.secList[4]={'Si', 'SiM7',2} --USD/RUB Si
  self.secList[5]={'Eu', 'EuM7',2} --EUR/RUB Eu
  self.secList[6]={'ED', 'EDM7',2} --EUR/USD ED
  self.secList[7]={'JP', 'JPM7',2} --USD/JPY UJPY
  self.secList[8]={'GU', 'GUM7',2} --GBP/USD GBPU
  self.secList[9]={'AU', 'AUM7',2} --AUD/USD AUDU
  self.secList[10]={'CA', 'CAM7',2} --USD/CAD UCAD
  self.secList[11]={'CF', 'CFM7',2} --USD/CHF UCHF
  self.secList[12]={'TR', 'TRM7',2} --USD/TRY UTRY
  self.secList[13]={'UH', 'UHM7',2} --USD/UAH UUAH гривна
  
  --комоды
  --brent надо обновл€ть каждый мес€ц
  self.secList[14]={'BR', 'BRJ7',2} --brent BR-4.17
  self.secList[15]={'GD', 'GDM7',2} --gold
  self.secList[16]={'SV', 'SVM7',2} --silv
  self.secList[17]={'PT', 'PTM7',2} --plt
  self.secList[18]={'PD', 'PDM7',2} --pld
  
  --[[
  --shares futures
  self.secList[19]={'SR', 'SRM7',2} --SBRF
  self.secList[20]={'GZ', 'GZM7',2} --GAZR
  self.secList[21]={'VB', 'VBM7',2} --VTBR
  self.secList[22]={'LK', 'LKM7',2} --LKOH
  self.secList[23]={'RN', 'RNM7',2} --ROSN
  self.secList[24]={'SP', 'SPM7',2} --SBPR sber pref
  self.secList[25]={'FS', 'FSM7',2} --FEES
  self.secList[26]={'HY', 'HYM7',2} --HYDR
  self.secList[27]={'GM', 'GMM7',2} --GMKR
  self.secList[28]={'MN', 'MNM7',2} --MGNT
  self.secList[29]={'SN', 'SNM7',2} --SNGR
  self.secList[30]={'ME', 'MEM7',2} --MOEX
  self.secList[31]={'SG', 'SGM7',2} --SNGP
  self.secList[32]={'AL', 'ALM7',2} --ALRS
  self.secList[33]={'NM', 'NMM7',2} --NLMK
  self.secList[34]={'TT', 'TTM7',2} --TATN
  self.secList[35]={'MT', 'MTM7',2} --MTSI
  self.secList[36]={'RT', 'RTM7',2} --RTKM
  self.secList[37]={'CH', 'CHM7',2} --CHMF --северсталь
  self.secList[38]={'TN', 'TNM7',2} --TRNF
  self.secList[39]={'NK', 'NKM7',2} --NOTK --новатэк
  self.secList[40]={'UK', 'UKM7',2} --URKA
  
  --]]
  
  --self.secList[]={'',2}
  
  
  self.LotSizeBox 	= '2'
  self.TypeLimitCombo = 'T0'
  self.IdPriceCombo = 'MXI_price_60h' 	--идентификатор графика
  self.IdMA 		= 'MXI_MA_60h'		--идентификатор графика. 60 часов
  
  self.TableCaption = 'ENS OLE LUA - GRID all Futures'
  self.rejim 		= 'revers'
  self.Path 		= path
  
  self.logFile = getScriptPath()..'\\log.txt'
  

end
