Security = class(function(acc)
end)

function Security:Init(class, code)
	self.minStepPrice = nil
	self.lotSize = nil
	if class~= nil and code~=nil then
		self.minStepPrice = getParamEx(class, code, "SEC_PRICE_STEP").param_value + 0
		self.STEPPRICET = getParamEx(class, code, "STEPPRICET").param_value + 0
		self.lotSize = getParamEx(class, code, "LOTSIZE").param_value + 0
	end
	if self.minStepPrice == nil or tonumber(self.minStepPrice) == 0 then
	--	message("Для инструмента "..code.." нет минимального шага цены в Квике. Добавьте его в таблицу инструментов", 2)
	end
	
	if self.lotSize == nil or tonumber(self.lotSize) == 0 then
	--	message("Для инструмента "..code.." нет размера лота в Квике. Добавьте его в таблицу инструментов", 2)
	end
  
  self.code = code
  self.class = class
  
  self.pricemax = 0
  self.pricemin = 0
  
end

function Security:Update()
	self.last = getParamEx(self.class, self.code, "LAST").param_value + 0
	self.minStepPrice = getParamEx(self.class, self.code, "SEC_PRICE_STEP").param_value + 0
end

--функция получает "крайние" цены - минимально и максимально возможную. только для фьючерсов!!!
function Security:GetEdgePrices()

	self.pricemax = getParamEx(self.class, self.code, "PRICEMAX").param_value + 0
	self.pricemin = getParamEx(self.class, self.code, "PRICEMIN").param_value + 0


end
