helper = {}
Settings = class(function(acc)
end)

function Settings:Init()
  self.DepoBox = ""
  self.ClientBox = ""
  self.ClassCode = ""
  self.SecCodeBox = ""
  self.LotSizeBox = ""
  self.logFile = ""
  self.start_all = true
  
  self.Path = ""
  self.TableCaption="MAIN::ENS_GRID_OPTIONS"
  helper = Helper()
  helper:Init()
  
  self.logFile = getScriptPath()..'\\log.txt'
  
  --���� ���� ��������� ������
  
  self.main_position = {x=0,y=0,dx=600,dy=100} --������� �������� ����
  self.log_position = {x=0,y=100,dx=600,dy=100} --������� ���� �����
  
  self.signals_position = {x=0,y=200,dx=600,dy=100} --������� ���� ��������
  self.orders_position = {x=0,y=300,dx=600,dy=100} --������� ���� ������

  
  self.db_path = getScriptPath() .. "\\ens_grid.db"
  self.robot_id = 'ENS_GRID_OPTIONS_BRENT_9_17_#01'
end

function Settings:instruments_list()
	local row = 1
	--local secList = {} --������� ������������. 
	local secList = QTable.new()
	--�������:
	--1 ��� �������� �����������, �������� RTS-9.17, ��� ������ ��� ����������
	secList:AddColumn('BaseASset', QTABLE_STRING_TYPE, 10 )
	--2 ��� �������
	secList:AddColumn('Ticker', QTABLE_STRING_TYPE, 10 )
	--3 ��� ������� - call/put - ��� ����������
	secList:AddColumn('PutCall', QTABLE_STRING_TYPE, 10 )
	--4 ���������� ���������� ����
	secList:AddColumn('Plan', QTABLE_DOUBLE_TYPE, 10 )
	--5 �������� - buy/sell
	secList:AddColumn('Action', QTABLE_STRING_TYPE, 10 )
	--6 ����� ����������� (SPBOPT)
	secList:AddColumn('Class', QTABLE_STRING_TYPE, 10 )
	--7	���� ���������� - ������ ��� ����������, ����� ��������� ����� ���� ������, ����� ��� �����
	secList:AddColumn('Expiration', QTABLE_STRING_TYPE, 10 )
	--8 �������� ����
	secList:AddColumn('Account', QTABLE_STRING_TYPE, 10 )
	--9 ���� ����
	secList:AddColumn('Depo', QTABLE_STRING_TYPE, 10 )
	--10 ����� ���������. start (���������� ����� ����� �������) / stop (�� ����������)
	secList:AddColumn('StartStop', QTABLE_STRING_TYPE, 10 )
	--11 ������ �� ���� ����. � ����� ����. ��������, +2 - ������ �� ����, -3 - ������� �� 3 ����
	secList:AddColumn('TheorDiff', QTABLE_DOUBLE_TYPE, 10 )
		
	---[[
	--										1					2		3	4		5	6			7				8			9			10		11
	row = addOneInstrumentToTable(row, {'BR-9.17 (BRU7)', 'BR47BT7', 'PUT', 20, 'buy', 'SPBOPT', '26.08.17','SPBFUT00922', 'SPBFUT00922', 'stop', '-1'}, secList)
	
	--]]
	
  return secList

end

function addOneInstrumentToTable(row, inst_table, res_table)
	--��������� "������ � �������" � ����������� �������� (� �� ������ �������� ������ ��� ����������������)
	--row - �����, ����� �������� ������� (����� ������ ������� �������)
	--inst_table - ������ � ����������� ����������� (������ �������)
	--res_table - in/out - �������������� �������

	res_table[row]=inst_table
	row = row + 1
	return row
end

function Settings:create_main_t()
	--������� �������, ������� �������� ���������� ��� �������� ���� ������
	--��� ������ ���� ������� ������� lua

	--1 ��� �������� �����������, �������� RTS-9.17, ��� ������ ��� ����������
	--2 ��� �������
	--3 ��� ������� - call/put - ��� ����������
	--4 ���������� ���������� ����
	--5 �������� - buy/sell
	--6 ����� ����������� (SPBOPT)
	--7	���� ���������� - ������ ��� ����������, ����� ��������� ����� ���� ������, ����� ��� �����
	--8 �������� ����
	--9 ���� ����
	--10 ����� ���������. start (���������� ����� ����� �������) / stop (�� ����������)
	--11 ������ �� ���� ����. � ����� ����. ��������, +2 - ������ �� ����, -3 - ������� �� 3 ����

	local t = {
	'current_state',--��������� ������ �� ���� ������ �����������
	'BaseAsset',
	'Ticker',
	'PutCall',--put/call
	'Plan',	--qty plan
	
	--'Action', --buy/sell
	
	--'Class',--SPBOPT	
	t:AddColumn('Class', QTABLE_STRING_TYPE, 10 )
	--'Expiration',
	t:AddColumn('Expiration', QTABLE_STRING_TYPE, 10 )
	--'Account',
	t:AddColumn('Account', QTABLE_STRING_TYPE, 10 )
	--'Depo',
	t:AddColumn('Depo', QTABLE_STRING_TYPE, 10 )
	--'StartStop',--10 ����� ���������. start (���������� ����� ����� �������) / stop (�� ����������)
	t:AddColumn('StartStop', QTABLE_STRING_TYPE, 10 )
	--'TheorDiff'--11 ������ �� ���� ����. � ����� ����. ��������, +2 - ������ �� ����, -3 - ������� �� 3 ����
	t:AddColumn('TheorDiff', QTABLE_DOUBLE_TYPE, 10 )
	--}

	return t

end