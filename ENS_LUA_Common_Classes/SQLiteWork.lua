SQLiteWork = class(function(acc)
end)

helper = {}
settings = {}

function SQLiteWork:Init()
  helper = Helper()
  helper:Init()

  settings = Settings()
  settings:Init()
  settings:Load()
  
  self.db = sqlite3.open(settings.dbpath)
end

--��������� ������� � ���������� ���������
function SQLiteWork:selectSQL(sql)
	local rows = self.db:nrows(sql)
	return rows
end

--��������� ������ ��� �������� ����������
function SQLiteWork:executeSQL(sql)
	self.db:exec(sql)
end
--������� ������� � ��������� �� �������
function SQLiteWork:createTableSignals()

 sql=[=[
          CREATE TABLE signals
          (
			rownum INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
		   
			client_code TEXT,
			depo_code TEXT,
			robot_id TEXT,
			sec_code TEXT,
			class_code TEXT,
			price_id TEXT,
			MA_id TEXT,
			date TEXT,
			time TEXT,
			direction TEXT,  --buy/sell
			processed REAL,	--���� ���������. 0 - �� ����������, 1 - �������� ���������, 2 - ��������� �������� �� �������� (��������)
			price_value REAL,		--�������� ����
			ma_value REAL,		--�������� ���������� �������
			price_pred_value REAL,		--���������� �������� ����
			ma_pred_value REAL		--���������� �������� ���������� �������
		   
          );          
        ]=]
         
	self:executeSQL(sql)
end

function SQLiteWork:createTablePositions()

  local sql=[=[
          CREATE TABLE positions
          (
                                
			rownum INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL
											
											 
			--�������� ��� ��������
			 
			,client_code      		TEXT -- ��� ������� 
			,depo_code				TEXT  -- ��� ����� ���� ��� ����
			,trade_num              REAL -- ����� ������ � �������� �������
			,sec_code               TEXT -- ��� ������ ������ 
			,class_code             TEXT -- ��� ������ 
			,price                  	REAL -- ���� 
			,qty                    	REAL -- ���������� ����� � ��������� ������ � ����� 

			--��� ����
			,date                   	TEXT -- �������� �� ������� datetime, �������� ����� � ���� ����-��-��
			,time                   	TEXT -- �������� �� ������� datetime
			,robot_id            	TEXT -- ��������, ����� ��������� �����, �.�. ���� ���������, ��� ��� ������ � ������� OnTrade() �� ���� �� ��� ������ ���?

			,signal_id				TEXT -- ��� ����� ���� ROWNUM �� ������� SIGNALS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

			,direction            	TEXT -- buy/sell
			--��� ���� �����
			 
			,order_num       		REAL -- ����� ������ � �������� ������� 
			,brokerref              	TEXT -- �����������, ������: <��� �������>/<����� ���������> 
			,userid                 	TEXT -- ������������� �������� 
			,firmid					TEXT -- ������������� ������ 
			,account                TEXT -- �������� ���� 
			,value                  	REAL -- ����� � �������� ��������� 
			,flags                  	REAL -- ����� ������� ������ 
			,trade_currency       TEXT -- ������ 
			,trans_id               	REAL  --������������� ���������� -- ����������������!!!!! ��� ����������� �������� , ����� ����� ����� ���� ��������

		);  
        ]=]
         
   self:executeSQL(sql)
end

function SQLiteWork:createTableOrders()

  local sql=[=[
          CREATE TABLE orders
          (
                                
            rownum INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL
                                
			--�������� ��� ��������
			,order_num                                      REAL  --����� ������ � �������� ������� 
			--��� ����
			,date                     	TEXT      --            �������� �� ������� datetime, �������� ����� � ���� ����-��-��
			,time                     	TEXT -- �������� �� ������� datetime
			,robot_id            		TEXT -- ��������, ����� ��������� �����, �.�. ���� ���������, ��� ��� ������ � ������� OnTrade() �� ���� �� ��� ������ ���?
			,withdraw_date 			TEXT --               �������� �� ������� withdraw_datetime
			,withdraw_time 			TEXT --               �������� �� ������� withdraw_datetime
			,direction            		TEXT --buy/sell
			--��� ���� �����
			,flags                                                                    REAL  --����� ������� ������
			,brokerref                                                         TEXT  --�����������, ������: <��� �������>/<����� ���������> 
			,userid                                                                                TEXT  --������������� �������� 
			,firmid                                                                                 TEXT  --������������� ����� 
			,account                                                             TEXT  --�������� ���� 
			,price                                                                   REAL  --���� 
			,qty                                                                                      REAL  --���������� � ����� 
			,balance                                                             REAL  --������� 
			,value                                                                  REAL  --����� � �������� ��������� 
			,accruedint                                        REAL  --����������� �������� ����� 
			,yield                                                                    REAL  --���������� 
			,trans_id                                                            REAL  --������������� ���������� -- ����������������!!!!! ��� ����������� �������� , ����� ����� ����� ���� ��������
			,client_code                                      TEXT  --��� ������� 
			,price2                                                                                REAL  --���� ������ 
			,settlecode                   TEXT  --��� �������� 
			,uid                                                                                      REAL  --������������� ������������ 
			,exchange_code            TEXT  --��� ����� � �������� ������� 
			,activation_time                              REAL  --����� ��������� 
			,linkedorder                                      REAL  --����� ������ � �������� ������� 
			,expiry                                                                                REAL  --���� ��������� ����� �������� ������ 
			,sec_code                                          TEXT  --��� ������ ������ 
			,class_code                                       TEXT  --��� ������ ������ 
			--,datetime                                                       TABLE  --���� � ����� 
			--,withdraw_datetime  TABLE  --���� � ����� ������ ������ 
			,bank_acc_id                                    TEXT  --������������� ���������� �����/���� � ����������� ����������� 
			,value_entry_type         REAL  --������ �������� ������ ������. ��������� ��������:
			 
			--�0� � �� ����������,
			--�1� � �� ������
			 
			,repoterm                                                         REAL   --���� ����, � ����������� ���� 
			,repovalue                                                        REAL  --����� ���� �� ������� ����. ������������ � ��������� 2 ����� 
			,repo2value                                      REAL  --����� ������ ������ ����. ������������ � ��������� 2 ����� 
			,repo_value_balance  REAL  --������� ����� ���� �� ������� ����� ������������ ��� ��������������� �� ������ ���� �������� ������� � ������������� ����� ������, �� ��������� �� ������� ����. ������������ � ��������� 2 ����� 
			,start_discount                                REAL    --��������� �������, � % 
			,reject_reason                                 TEXT  --������� ���������� ������ �������� 
			,ext_order_flags                             REAL  --������� ���� ��� ��������� ������������� ���������� � �������� �������� 
			,min_qty                                                            REAL  -- ���������� ���������� ����������, ������� ����� ������� � ������ �� ������� �����������. ���� ����� �������� �0�, ������ ����������� �� ���������� �� ������ 
			,exec_type                                        REAL  --��� ���������� ������. ���� ����� �������� �0�, ������ �������� �� ������ 
			,side_qualifier                                  REAL  --���� ��� ��������� ���������� �� �������� ���������. ���� ����� �������� �0�, ������ �������� �� ������ 
			,acnt_type                                         REAL  --���� ��� ��������� ���������� �� �������� ���������. ���� ����� �������� �0�, ������ �������� �� ������ 
			,capacity                                                             REAL  --���� ��� ��������� ���������� �� �������� ���������. ���� ����� �������� �0�, ������ �������� �� ������ 
			,passive_only_order  REAL  --���� ��� ��������� ���������� �� �������� ���������. ���� ����� �������� �0�, ������ �������� �� ������ 
			,visible                                                                REAL  --������� ����������. �������� �������-������, ��� ������� ������ ��������� ��������: �0�
 
 
          );  
        ]=]
         
   self:executeSQL(sql)
end

