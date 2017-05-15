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

--выполняет выборку и возвращает рекордсет
function SQLiteWork:selectSQL(sql)
	local rows = self.db:nrows(sql)
	return rows
end

--исполняет запрос без возврата рекордсета
function SQLiteWork:executeSQL(sql)
	self.db:exec(sql)
end
--создает таблицу с сигналами от роботов
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
			processed REAL,	--флаг обработки. 0 - не обработана, 1 - обратана полностью, 2 - обработка прервана по таймауту (доделать)
			price_value REAL,		--значение цены
			ma_value REAL,		--значение скользящей средней
			price_pred_value REAL,		--предыдущее значение цены
			ma_pred_value REAL		--предыдущее значение скользящей средней
		   
          );          
        ]=]
         
	self:executeSQL(sql)
end

function SQLiteWork:createTablePositions()

  local sql=[=[
          CREATE TABLE positions
          (
                                
			rownum INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL
											
											 
			--Параметр Тип Описание
			 
			,client_code      		TEXT -- Код клиента 
			,depo_code				TEXT  -- код счета ДЕПО для ММВБ
			,trade_num              REAL -- Номер сделки в торговой системе
			,sec_code               TEXT -- Код бумаги заявки 
			,class_code             TEXT -- Код класса 
			,price                  	REAL -- Цена 
			,qty                    	REAL -- Количество бумаг в последней сделке в лотах 

			--мои поля
			,date                   	TEXT -- получаем из таблицы datetime, наверное сразу в виде гггг-мм-дд
			,time                   	TEXT -- получаем из таблицы datetime
			,robot_id            	TEXT -- наверное, будем заполнять потом, т.к. пока непонятно, как это делать в событии OnTrade() да надо ли это делать там?

			,signal_id				TEXT -- ЭТО БУДЕТ ПОЛЕ ROWNUM ИЗ ТАБЛИЦЫ SIGNALS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

			,direction            	TEXT -- buy/sell
			--мои поля конец
			 
			,order_num       		REAL -- Номер заявки в торговой системе 
			,brokerref              	TEXT -- Комментарий, обычно: <код клиента>/<номер поручения> 
			,userid                 	TEXT -- Идентификатор трейдера 
			,firmid					TEXT -- Идентификатор дилера 
			,account                TEXT -- Торговый счет 
			,value                  	REAL -- Объем в денежных средствах 
			,flags                  	REAL -- Набор битовых флагов 
			,trade_currency       TEXT -- Валюта 
			,trans_id               	REAL  --Идентификатор транзакции -- ПОЛЬЗОВАТЕЛЬСКИЙ!!!!! при программном создании , чтобы потом можно было отловить

		);  
        ]=]
         
   self:executeSQL(sql)
end

function SQLiteWork:createTableOrders()

  local sql=[=[
          CREATE TABLE orders
          (
                                
            rownum INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL
                                
			--Параметр Тип Описание
			,order_num                                      REAL  --Номер заявки в торговой системе 
			--мои поля
			,date                     	TEXT      --            получаем из таблицы datetime, наверное сразу в виде гггг-мм-дд
			,time                     	TEXT -- получаем из таблицы datetime
			,robot_id            		TEXT -- наверное, будем заполнять потом, т.к. пока непонятно, как это делать в событии OnTrade() да надо ли это делать там?
			,withdraw_date 			TEXT --               получаем из таблицы withdraw_datetime
			,withdraw_time 			TEXT --               получаем из таблицы withdraw_datetime
			,direction            		TEXT --buy/sell
			--мои поля конец
			,flags                                                                    REAL  --Набор битовых флагов
			,brokerref                                                         TEXT  --Комментарий, обычно: <код клиента>/<номер поручения> 
			,userid                                                                                TEXT  --Идентификатор трейдера 
			,firmid                                                                                 TEXT  --Идентификатор фирмы 
			,account                                                             TEXT  --Торговый счет 
			,price                                                                   REAL  --Цена 
			,qty                                                                                      REAL  --Количество в лотах 
			,balance                                                             REAL  --Остаток 
			,value                                                                  REAL  --Объем в денежных средствах 
			,accruedint                                        REAL  --Накопленный купонный доход 
			,yield                                                                    REAL  --Доходность 
			,trans_id                                                            REAL  --Идентификатор транзакции -- ПОЛЬЗОВАТЕЛЬСКИЙ!!!!! при программном создании , чтобы потом можно было отловить
			,client_code                                      TEXT  --Код клиента 
			,price2                                                                                REAL  --Цена выкупа 
			,settlecode                   TEXT  --Код расчетов 
			,uid                                                                                      REAL  --Идентификатор пользователя 
			,exchange_code            TEXT  --Код биржи в торговой системе 
			,activation_time                              REAL  --Время активации 
			,linkedorder                                      REAL  --Номер заявки в торговой системе 
			,expiry                                                                                REAL  --Дата окончания срока действия заявки 
			,sec_code                                          TEXT  --Код бумаги заявки 
			,class_code                                       TEXT  --Код класса заявки 
			--,datetime                                                       TABLE  --Дата и время 
			--,withdraw_datetime  TABLE  --Дата и время снятия заявки 
			,bank_acc_id                                    TEXT  --Идентификатор расчетного счета/кода в клиринговой организации 
			,value_entry_type         REAL  --Способ указания объема заявки. Возможные значения:
			 
			--«0» – по количеству,
			--«1» – по объему
			 
			,repoterm                                                         REAL   --Срок РЕПО, в календарных днях 
			,repovalue                                                        REAL  --Сумма РЕПО на текущую дату. Отображается с точностью 2 знака 
			,repo2value                                      REAL  --Объём сделки выкупа РЕПО. Отображается с точностью 2 знака 
			,repo_value_balance  REAL  --Остаток суммы РЕПО за вычетом суммы привлеченных или предоставленных по сделке РЕПО денежных средств в неисполненной части заявки, по состоянию на текущую дату. Отображается с точностью 2 знака 
			,start_discount                                REAL    --Начальный дисконт, в % 
			,reject_reason                                 TEXT  --Причина отклонения заявки брокером 
			,ext_order_flags                             REAL  --Битовое поле для получения специфических параметров с западных площадок 
			,min_qty                                                            REAL  -- Минимально допустимое количество, которое можно указать в заявке по данному инструменту. Если имеет значение «0», значит ограничение по количеству не задано 
			,exec_type                                        REAL  --Тип исполнения заявки. Если имеет значение «0», значит значение не задано 
			,side_qualifier                                  REAL  --Поле для получения параметров по западным площадкам. Если имеет значение «0», значит значение не задано 
			,acnt_type                                         REAL  --Поле для получения параметров по западным площадкам. Если имеет значение «0», значит значение не задано 
			,capacity                                                             REAL  --Поле для получения параметров по западным площадкам. Если имеет значение «0», значит значение не задано 
			,passive_only_order  REAL  --Поле для получения параметров по западным площадкам. Если имеет значение «0», значит значение не задано 
			,visible                                                                REAL  --Видимое количество. Параметр айсберг-заявок, для обычных заявок выводится значение: «0»
 
 
          );  
        ]=]
         
   self:executeSQL(sql)
end

