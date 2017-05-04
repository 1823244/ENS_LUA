--���� ������ ������� ������� ������ � ������
 
local sqlite3 = require("lsqlite3")
local db = sqlite3.open(getScriptPath() .. ".\\..\\positions.db")
 
--������� ������� �������� ���� ����
function main()
    local sql = create_deals()
        
   db:exec(sql)
   
   sql = createIndexes()
   
   db:exec(sql)
   
   sql = create_table_positions()
   
   db:exec(sql)
end
 
 
---------------------------------------   DEALS
function create_deals()
   local sql=[=[
          CREATE TABLE deals
          (
                                
rownum INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL
                                
                                 
--�������� ��� ��������
 
,trade_num                       REAL --����� ������ � �������� �������
 
--��� ����
,date                     TEXT      --            �������� �� ������� datetime, �������� ����� � ���� ����-��-��
,time                     TEXT -- �������� �� ������� datetime
,robot_id            TEXT -- ��������, ����� ��������� �����, �.�. ���� ���������, ��� ��� ������ � ������� OnTrade() �� ���� �� ��� ������ ���?
,canceled_date TEXT -- �������� �� ������� canceled_datetime
,canceled_time TEXT -- �������� �� ������� canceled_datetime
,direction            TEXT --buy/sell
--��� ���� �����
 
,order_num       REAL  --����� ������ � �������� ������� 
,brokerref                          STRING  --�����������, ������: <��� �������>/<����� ���������> 
,userid                                                 TEXT  --������������� �������� 
,firmid                                                 TEXT  --������������� ������ 
,account                              TEXT  --�������� ���� 
,price                                    REAL  --���� 
,qty                                                       REAL  --���������� ����� � ��������� ������ � ����� 
,value                                   REAL  --����� � �������� ��������� 
,accruedint         REAL  --����������� �������� ����� 
,yield                                    REAL  --���������� 
,settlecode        TEXT  --��� �������� 
,cpfirmid                             TEXT -- ��� ����� �������� 
,flags                                    REAL  --����� ������� ������ 
,price2                                                 REAL  --���� ������ 
,reporate                            REAL  --������ ���� (%) 
,client_code      TEXT  --��� ������� 
,accrued2                           REAL  --����� (%) �� ���� ������ 
,repoterm                          REAL  --���� ����, � ����������� ���� 
,repovalue                         REAL  --����� ���� 
,repo2value       REAL  --����� ������ ���� 
,start_discount                                                REAL  --��������� ������� (%) 
,lower_discount                                             REAL  --������ ������� (%) 
,upper_discount                                             REAL  --������� ������� (%) 
,block_securities                                            REAL  --���������� ����������� (���/����) 
,clearing_comission                       REAL  --����������� �������� (����) 
,exchange_comission   REAL  --�������� �������� ����� (����) 
,tech_center_comission  REAL  --�������� ������������ ������ (����) 
,settle_date                      TEXT  --���� �������� 
,settle_currency              TEXT  --������ �������� 
,trade_currency              TEXT -- ������ 
,exchange_code             TEXT  --��� ����� � �������� ������� 
,station_id                                         TEXT  --������������� ������� ������� 
,sec_code                                          TEXT  --��� ������ ������ 
,class_code                        TEXT  --��� ������ 
--,datetime                                       TABLE  --���� � ����� 
,bank_acc_id                    TEXT  --������������� ���������� �����/���� � ����������� ����������� 
,broker_comission  REAL  --�������� �������. ������������ � ��������� �� 2 ���� ������. ���� ��������������� ��� �������� �������������. 
,linked_trade                    REAL -- ����� ��������� ������ � �������� ������� ��� ������ ���� � �� � SWAP 
,period                                                                INTEGER  --������ �������� ������. ��������� ��������:
 
--�0� � ��������;
--�1� � ����������;
--�2� � ��������
 
,trans_id                                             REAL  --������������� ���������� -- ����������������!!!!! ��� ����������� �������� , ����� ����� ����� ���� ��������
,kind                                                                    INTEGER  --��� ������. ��������� ��������:
 
--�1� � �������;
--�2� � ��������;
--�3� � ��������� ����������;
--�4� � ������� �����/�����;
--�5� � �������� ������ ������ ����� ����;
--�6� � ��������� �� �������� ����;
--�7� � ��������� �� ����������� �������� ����;
--�8� � ��������� ������ ���������� �������;
--�9� � ��������� ����������� ������ ���������� �������;
--�10� � ������ �� �������� ���� � ��;
--�11� � ������ ����� ������ �� �������� ���� � ��;
--�12� � ������ ����� ������ �� �������� ���� � ��;
--�13� � �������� ������ �� �������� ���� � ��;
--�14� � ������ ����� �������� ������ �� �������� ���� � ��;
--�15� � ������ ����� �������� ������ �� �������� ���� � ��;
--�16� � ����������� ������ �� �������� ������� ���� � ��;
--�17� � ������ �� ������ ����� ���������� ������ ������ �� ���� �����;
--�18� � ����������� ������ ������ ����� �� ������ ����� ����������;
--�19� � ����������� ������ ������ ����� �� ������ ����� ����������;
--�20� � �������� ������ ������ ����� ���� � ��������;
--�21� � �������� ������ ������ ����� ���� � ��������;
--�22� � ������� ������� �������� �����
 
,clearing_bank_accid     TEXT --������������� ����� � ��� (��������� ���)
--,canceled_datetime                   TABLE --���� � ����� ������ ������
,clearing_firmid                                               TEXT --������������� ����� - ��������� ��������
,system_ref                                                      TEXT --�������������� ���������� �� ������, ������������ �������� ��������
,uid                                                                                                      REAL --������������� ������������ �� ������� QUIK
 
 
          );  
        ]=]
return sql
end

function createIndexes()
	local sql = [=[

	CREATE INDEX `num_date_idx` ON `deals` (`trade_num` ASC,`date` ASC);
	]=]
	return sql
end

function create_table_positions()
   local sql=[=[
          CREATE TABLE positions
          (
                                
rownum INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL
                                
                                 
--�������� ��� ��������
 
,client_code      		TEXT -- ��� ������� 
,trade_num              REAL -- ����� ������ � �������� �������
,sec_code               TEXT -- ��� ������ ������ 
,class_code             TEXT -- ��� ������ 
,price                  REAL -- ���� 
,qty                    REAL -- ���������� ����� � ��������� ������ � ����� 

--��� ����
,date                   TEXT -- �������� �� ������� datetime, �������� ����� � ���� ����-��-��
,time                   TEXT -- �������� �� ������� datetime
,robot_id            	TEXT -- ��������, ����� ��������� �����, �.�. ���� ���������, ��� ��� ������ � ������� OnTrade() �� ���� �� ��� ������ ���?
,signal_id				TEXT --

,direction            	TEXT -- buy/sell
--��� ���� �����
 
,order_num       		REAL -- ����� ������ � �������� ������� 
,brokerref              TEXT -- �����������, ������: <��� �������>/<����� ���������> 
,userid                 TEXT -- ������������� �������� 
,firmid					TEXT -- ������������� ������ 
,account                TEXT -- �������� ���� 
,value                  REAL -- ����� � �������� ��������� 
,flags                  REAL -- ����� ������� ������ 
,trade_currency         TEXT -- ������ 
,trans_id               REAL  --������������� ���������� -- ����������������!!!!! ��� ����������� �������� , ����� ����� ����� ���� ��������

          );  
        ]=]
return sql
end

