
function main()
	client='11267'
	depo='MB1000100002'
	code = 'USD000UTSTOM'
	currency = 'USD'
	a=GetCurrentPosition(code, client, currency)
	message(tostring(a))
	
	--[[
	table_name='money_limits'
	n = getNumberOf(table_name)
	--message(tostring(n))
	for i = n-1, 0, -1 do
		message(tostring(     getItem(table_name, i)['currentbal']      ) .. ' cur code '.. getItem(table_name, i)['currcode'])
    end
	--]]
	
end

function GetCurrentPosition(code, client, currency)
  curPosition = 0
  curPosition = getValueFromTable2("futures_client_holding", "sec_code", code, "trdaccid", client, "totalnet")
  if curPosition == nil then
    curPosition = getValueFromTable2("depo_limits", "sec_code", code, "client_code", client, "currentbal")
  end
  if curPosition == nil then
  
    curPosition = getValueFromTable_CETS("money_limits", "sec_code", code, "client_code", client, "currentbal", currency)
	
  end
  if curPosition == nil then
    curPosition = 0
  end
  return curPosition
end

function getValueFromTable2(table_name, key1, value1, key2, value2, key3, currency)
  local i
  
  for i = getNumberOf(table_name)-1, 0, -1 do
    if getItem(table_name, i) ~= nil and getItem(table_name, i)[key1] ~= nil and tostring(getItem(table_name, i)[key1]) == tostring(value1) and tostring(getItem(table_name, i)[key2]) == tostring(value2) then
      return getItem(table_name, i)[key3]
    end
  end
  return nil
end

function getValueFromTable_CETS(table_name, key1, value1, key2, value2, key3)
  local i
  --message('cets')
  for i = getNumberOf(table_name)-1, 0, -1 do
    if getItem(table_name, i) ~= nil 
		and getItem(table_name, i)[key2] ~= nil 
		and tostring(getItem(table_name, i)[key2]) == tostring(value2)
		and tostring(getItem(table_name, i)['currcode']) == tostring(currency) 
		then
      return getItem(table_name, i)[key3]
    end
  end
  return nil
end