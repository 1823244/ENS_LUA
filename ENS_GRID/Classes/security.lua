Security = class(function(acc)
end)

function Security:Init()
  --[[
  self.lotSize = getParamEx(class, code, "LOTSIZE").param_value + 0
  if self.lotSize == nil or tonumber(self.lotSize) == 0 then
    message("Для инструмента "..code.." нет размера лота в Квике. Добавьте его в таблицу инструментов", 2)
  end
  --]]
  self.minStepPrice=0
  self.last = 0
  self.code = ''
  self.class = ''
  --self.testCode = 'testCode 6655'
end

function Security:Update()

	self.last = getParamEx(self.class, self.code, "LAST").param_value + 0
end