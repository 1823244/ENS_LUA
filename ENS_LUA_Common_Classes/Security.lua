Security = class(function(acc)
end)
function Security:Init(class, code)
  self.minStepPrice = getParamEx(class, code, "SEC_PRICE_STEP").param_value + 0
  self.STEPPRICET = getParamEx(class, code, "STEPPRICET").param_value + 0
  if self.minStepPrice == nil or tonumber(self.minStepPrice) == 0 then
    message("Для инструмента "..code.." нет минимального шага цены в Квике. Добавьте его в таблицу инструментов", 2)
  end
  self.lotSize = getParamEx(class, code, "LOTSIZE").param_value + 0
  if self.lotSize == nil or tonumber(self.lotSize) == 0 then
    message("Для инструмента "..code.." нет размера лота в Квике. Добавьте его в таблицу инструментов", 2)
  end
  self.last = getParamEx(class, code, "LAST").param_value + 0
  self.code = code
  self.class = class
end
function Security:Update()
  self.last = getParamEx(self.class, self.code, "LAST").param_value + 0
end
