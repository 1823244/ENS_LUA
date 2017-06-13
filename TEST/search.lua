local processed_trades = {} --таблица обработанных сделок
function main()
	local found = false
	message(tostring(#processed_trades))
	processed_trades[#processed_trades+1] = 395
	
	for i = 1, #processed_trades do
		if processed_trades[i] == 395 then
			found = true
			message(tostring('found'))
			break
		end
	end
	if found == true then
		return
	else
		processed_trades[#processed_trades+1] = 395
	end
	message(tostring(#processed_trades))
end