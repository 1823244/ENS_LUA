Window = class(function(acc)
end)

--Parameters
--position - table, coordinates of window x, y, dx, dy. for function SetWindowPos
function Window:Init(caption, columns, position)


  self.hID = AllocTable()
  self.columns = {} --ENS добавим поле columns, чтобы потом можно было найти  номер колонки по имени
  local i = 1
  local lent = 0
  for key, value in pairs(columns) do
	if value == 'Message_' then 
		lent = 100
	else
		lent = 20
	end
    AddColumn(self.hID, i, value, true, QTABLE_STRING_TYPE, lent)
	self.columns[i]=value --ENS добавим поле columns, чтобы потом можно было найти  номер колонки по имени
    i = i + 1
  end
  
  CreateWindow(self.hID)
  SetWindowCaption(self.hID, caption)
  --зачем добавлять пустую строку?
  --InsertRow(self.hID, 0)
  
  if position ~= nil then
	if position.x ~= nil and position.y ~= nil and position.dx~=nil and position.dy ~= nil then
		SetWindowPos(self.hID, position.x, position.y, position.dx, position.dy)
	end 
  end
  
end

function Window:InsertValue(id, value)
  value = tostring(value)
  if value == nil then
    return
  end
  rows, columns = GetTableSize(self.hID)
  local i = 1
  local j = 1
  while i <= columns do
    j = 1
    while j <= rows do
      local x = GetCell(self.hID, j, i)
      if x ~= nil and x.image == id then
        SetCell(self.hID, j + 1, i, value)
      end
      j = j + 1
    end
    i = i + 1
  end
end

function Window:SetValueWithColor(id, value, color)
  rows, columns = GetTableSize(self.hID)
  local i = 1
  local j = 1
  while i <= columns do
    j = 1
    while j <= rows do
      local x = GetCell(self.hID, j, i)
      if x ~= nil and x.image == id then
        SetCell(self.hID, j, i, value)
        if color == "Grey" then
          SetColor(self.hID, j, QTABLE_NO_INDEX, RGB(220, 220, 220), QTABLE_NO_INDEX, QTABLE_NO_INDEX, QTABLE_NO_INDEX)
        end
        if color == "Green" then
          SetColor(self.hID, j, QTABLE_NO_INDEX, RGB(0, 255, 0), QTABLE_NO_INDEX, QTABLE_NO_INDEX, QTABLE_NO_INDEX)
        end
        if color == "Red" then
          SetColor(self.hID, j, QTABLE_NO_INDEX, RGB(255, 0, 0), QTABLE_NO_INDEX, QTABLE_NO_INDEX, QTABLE_NO_INDEX)
        end
      end
      j = j + 1
    end
    i = i + 1
  end
end

function Window:GetValue(id)
  value = 0
  rows, columns = GetTableSize(self.hID)
  i = 1
  j = 1
  while i <= columns do
    j = 1
    while j <= rows do
      x = GetCell(self.hID, j, i)
      if x ~= nil and x.image == id then
        value = GetCell(self.hID, j + 1, i).image
      end
      j = j + 1
    end
    i = i + 1
  end
  if value == nil or value == "" then
    value = 0
  end
  return value
end

function Window:IfExists(id)
  rows, columns = GetTableSize(self.hID)
  i = 1
  j = 1
  while i <= columns do
    j = 1
    while j <= rows do
      x = GetCell(self.hID, j, i)
      if x ~= nil and x.image == id then
        return true
      end
      j = j + 1
    end
    i = i + 1
  end
  return false
end

--добавляет строку в таблицу роботаы
function Window:AddRow(row, color)
  rows, columns = GetTableSize(self.hID)
  InsertRow(self.hID, rows)
  i = 1
  for key, value in pairs(row) do
  --message(value)
    SetCell(self.hID, rows, i, tostring(value))
    i = i + 1
  end
  if color == "Grey" then
    SetColor(self.hID, rows, QTABLE_NO_INDEX, RGB(220, 220, 220), QTABLE_NO_INDEX, QTABLE_NO_INDEX, QTABLE_NO_INDEX)
  end
  if color == "Green" then
    --SetColor(self.hID, rows, QTABLE_NO_INDEX, RGB(0, 255, 0), QTABLE_NO_INDEX, QTABLE_NO_INDEX, QTABLE_NO_INDEX)
	SetColor(self.hID, rows, QTABLE_NO_INDEX, RGB(230, 255, 230), QTABLE_NO_INDEX, QTABLE_NO_INDEX, QTABLE_NO_INDEX)
  end
  if color == "Red" then
    --SetColor(self.hID, rows, QTABLE_NO_INDEX, RGB(255, 0, 0), QTABLE_NO_INDEX, QTABLE_NO_INDEX, QTABLE_NO_INDEX)
	SetColor(self.hID, rows, QTABLE_NO_INDEX, RGB(255, 230, 230), QTABLE_NO_INDEX, QTABLE_NO_INDEX, QTABLE_NO_INDEX)
  end
end

function Window:Close()
  DestroyTable(self.hID)
end

--ENS поиск номера колонки по имени
function Window:GetColNumberByName(col_name)
	rows, columns = GetTableSize(self.hID)
	for i=1, columns do
		if self.columns[i] == col_name then
			return i
		end
	end
	return nil
end

function Window:GetValueByColName(row, col_name)

	local t={}
	local col_ind = self:GetColNumberByName(col_name)
	if col_ind == nil then
		return nil
	end
	t = GetCell(self.hID, row, col_ind)
	return t


end

function Window:SetValueByColName(row, col_name, data)

	--message(col_name)
	local col_ind = self:GetColNumberByName(col_name)
	--message(tostring(col_ind))
	
	if col_ind == nil then
		return false
	end
	SetCell(self.hID, row, col_ind, tostring(data))
	return true
end

