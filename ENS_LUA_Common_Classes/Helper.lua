Helper = class(function(acc)
end)

function Helper:Init()
end
function Helper:LoadFromFile(fileName)
  file = io.open(fileName, "r")
  if file ~= nil then
    value = file:read()
    file:close()
    if value ~= nil then
      return value
    end
  end
  return ""
end
function Helper:printTable(tbl, fileName)
  for k, v in pairs(tbl) do
    self:AppendInFile(fileName, k .. " " .. v)
  end
end
function Helper:writeInFile(fileName, text)
  file = io.open(fileName, "w+t")
  if file ~= nil then
    file:write(text)
    file:close()
  end
end
function Helper:AppendInFile(fileName, text)
  file = io.open(fileName, "a")
  if file ~= nil then
    file:write(text)
    file:close()
  end
end
function Helper:getValueFromTable2(table_name, key1, value1, key2, value2, key3)
  local i
  for i = getNumberOf(table_name), 0, -1 do
    if getItem(table_name, i)[key1] ~= nil and tostring(getItem(table_name, i)[key1]) == tostring(value1) and tostring(getItem(table_name, i)[key2]) == tostring(value2) then
      return getItem(table_name, i)[key3]
    end
  end
  return nil
end
function Helper:InsertDot(str)
  return string.gsub(str, ",", ".")
end
function Helper:checkNill(value)
  if value == nil then
    logMemo:Add("No data!")
    return true
  end
  return false
end
function Helper:getHRTime()
  local now = os.clock()
  return string.format("%s,%3d", os.date("%X", now), select(2, math.modf(now)) * 1000)
end
function Helper:getMiliSeconds()
  local now = os.clock()
  return string.format("%s,%3d", os.date("%X", now), select(2, math.modf(now)) * 1000)
end

--ENS for trans_id. эта функция создает trans_id на основе текущего времени с миллисекундами
function Helper:getMiliSeconds_trans_id()
  local now = os.clock()
  local ms = select(2, math.modf(now)) * 1000
  ms = self:round(ms, 0)
  local ms2 = ''
  if ms < 10 then
	ms2 = '00'..tostring(ms)
  elseif ms < 100 then 
	ms2 = '0'..tostring(ms)
  else
	ms2 = ''..tostring(ms)
  end
  return string.format("%s", tostring(self:getHRTime4()) .. ms2)
end

--18:24:55
function Helper:getHRTime2()
  hour = tostring(os.date("*t").hour)
  minute = tostring(os.date("*t").min)
  second = tostring(os.date("*t").sec)
  if tonumber(hour) < 10 then
    hour = "0" .. hour
  end
  if tonumber(minute) < 10 then
    minute = "0" .. minute
  end
  if tonumber(second) < 10 then
    second = "0" .. second
  end
  return hour .. ":" .. minute .. ":" .. second
end
function Helper:getHRTime3(seconds)
  hour = os.date("*t").hour
  minute = os.date("*t").min
  sec = os.date("*t").sec + seconds
  if sec > 59 then
    minute = minute + 1
    sec = sec - 60
    if minute > 59 then
      hour = hour + 1
      minute = minute - 60
    end
  end
  return hour * 10000 + minute * 100 + sec
end
function Helper:getHRTime4()
	local dt = os.date("*t")
  hour = tostring(dt.hour)
  minute = tostring(dt.min)
  second = tostring(dt.sec)
  return hour * 10000 + minute * 100 + second
end
function Helper:round(num, idp)
  local mult = 10 ^ (idp or 0)
  return math.floor(num * mult + 0.5) / mult
end


--ENS без секунд
function Helper:getHRTime5()
  hour = tostring(os.date("*t").hour)
  minute = tostring(os.date("*t").min)
  
  return hour * 10000 + minute * 100
end

--возвращает дату сделки в строковом формате SQL '2016-11-06' (для правильной сортировки в таблицах)
--datetime - таблица, поля: day, month, year
function Helper:get_trade_date_sql(datetime)

  local z = ''
  
  local day = ''
  
  if datetime.day<10 then 
    z = '0' 
  else
    z = ''
  end
  day = z..tostring(datetime.day)
   
  local month = ''
  
  if datetime.month<10 then 
    z = '0' 
  else
    z = ''
  end
  month = z..tostring(datetime.month)

  return tostring(datetime.year)..'-'..month..'-'..day
end

--функция возвращает true, если бит [index] установлен в 1 (взято из примеров some_callbacks.lua)
--пример вызова для определения направления
--if bit_set(flags, 2) then
--		t["sell"]=1
--	else
--		t["buy"] = 1
--	end
--
function Helper:bit_set( flags, index )
  local n=1
  n=bit.lshift(1, index)
  if bit.band(flags, n) ~=0 then
    return true
  else
    return false
  end
end

--определим направление сделки
function Helper:what_is_the_direction(trade)
    if self:bit_set(trade.flags, 2) then
      return 'sell'
    else
      return 'buy'
    end
end