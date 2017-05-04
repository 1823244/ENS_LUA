--этот скрипт создает таблицы сделок и заявок
 
local sqlite3 = require("lsqlite3")
local db = sqlite3.open(getScriptPath() .. ".\\..\\positions.db")
 
--создает таблицу регистра ФИФО ШОРТ
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
                                
                                 
--Параметр Тип Описание
 
,trade_num                       REAL --Номер сделки в торговой системе
 
--мои поля
,date                     TEXT      --            получаем из таблицы datetime, наверное сразу в виде гггг-мм-дд
,time                     TEXT -- получаем из таблицы datetime
,robot_id            TEXT -- наверное, будем заполнять потом, т.к. пока непонятно, как это делать в событии OnTrade() да надо ли это делать там?
,canceled_date TEXT -- получаем из таблицы canceled_datetime
,canceled_time TEXT -- получаем из таблицы canceled_datetime
,direction            TEXT --buy/sell
--мои поля конец
 
,order_num       REAL  --Номер заявки в торговой системе 
,brokerref                          STRING  --Комментарий, обычно: <код клиента>/<номер поручения> 
,userid                                                 TEXT  --Идентификатор трейдера 
,firmid                                                 TEXT  --Идентификатор дилера 
,account                              TEXT  --Торговый счет 
,price                                    REAL  --Цена 
,qty                                                       REAL  --Количество бумаг в последней сделке в лотах 
,value                                   REAL  --Объем в денежных средствах 
,accruedint         REAL  --Накопленный купонный доход 
,yield                                    REAL  --Доходность 
,settlecode        TEXT  --Код расчетов 
,cpfirmid                             TEXT -- Код фирмы партнера 
,flags                                    REAL  --Набор битовых флагов 
,price2                                                 REAL  --Цена выкупа 
,reporate                            REAL  --Ставка РЕПО (%) 
,client_code      TEXT  --Код клиента 
,accrued2                           REAL  --Доход (%) на дату выкупа 
,repoterm                          REAL  --Срок РЕПО, в календарных днях 
,repovalue                         REAL  --Сумма РЕПО 
,repo2value       REAL  --Объем выкупа РЕПО 
,start_discount                                                REAL  --Начальный дисконт (%) 
,lower_discount                                             REAL  --Нижний дисконт (%) 
,upper_discount                                             REAL  --Верхний дисконт (%) 
,block_securities                                            REAL  --Блокировка обеспечения («Да»/«Нет») 
,clearing_comission                       REAL  --Клиринговая комиссия (ММВБ) 
,exchange_comission   REAL  --Комиссия Фондовой биржи (ММВБ) 
,tech_center_comission  REAL  --Комиссия Технического центра (ММВБ) 
,settle_date                      TEXT  --Дата расчетов 
,settle_currency              TEXT  --Валюта расчетов 
,trade_currency              TEXT -- Валюта 
,exchange_code             TEXT  --Код биржи в торговой системе 
,station_id                                         TEXT  --Идентификатор рабочей станции 
,sec_code                                          TEXT  --Код бумаги заявки 
,class_code                        TEXT  --Код класса 
--,datetime                                       TABLE  --Дата и время 
,bank_acc_id                    TEXT  --Идентификатор расчетного счета/кода в клиринговой организации 
,broker_comission  REAL  --Комиссия брокера. Отображается с точностью до 2 двух знаков. Поле зарезервировано для будущего использования. 
,linked_trade                    REAL -- Номер витринной сделки в Торговой Системе для сделок РЕПО с ЦК и SWAP 
,period                                                                INTEGER  --Период торговой сессии. Возможные значения:
 
--«0» – Открытие;
--«1» – Нормальный;
--«2» – Закрытие
 
,trans_id                                             REAL  --Идентификатор транзакции -- ПОЛЬЗОВАТЕЛЬСКИЙ!!!!! при программном создании , чтобы потом можно было отловить
,kind                                                                    INTEGER  --Тип сделки. Возможные значения:
 
--«1» – Обычная;
--«2» – Адресная;
--«3» – Первичное размещение;
--«4» – Перевод денег/бумаг;
--«5» – Адресная сделка первой части РЕПО;
--«6» – Расчетная по операции своп;
--«7» – Расчетная по внебиржевой операции своп;
--«8» – Расчетная сделка бивалютной корзины;
--«9» – Расчетная внебиржевая сделка бивалютной корзины;
--«10» – Сделка по операции РЕПО с ЦК;
--«11» – Первая часть сделки по операции РЕПО с ЦК;
--«12» – Вторая часть сделки по операции РЕПО с ЦК;
--«13» – Адресная сделка по операции РЕПО с ЦК;
--«14» – Первая часть адресной сделки по операции РЕПО с ЦК;
--«15» – Вторая часть адресной сделки по операции РЕПО с ЦК;
--«16» – Техническая сделка по возврату активов РЕПО с ЦК;
--«17» – Сделка по спреду между фьючерсами разных сроков на один актив;
--«18» – Техническая сделка первой части от спреда между фьючерсами;
--«19» – Техническая сделка второй части от спреда между фьючерсами;
--«20» – Адресная сделка первой части РЕПО с корзиной;
--«21» – Адресная сделка второй части РЕПО с корзиной;
--«22» – Перенос позиций срочного рынка
 
,clearing_bank_accid     TEXT --Идентификатор счета в НКЦ (расчетный код)
--,canceled_datetime                   TABLE --Дата и время снятия сделки
,clearing_firmid                                               TEXT --Идентификатор фирмы - участника клиринга
,system_ref                                                      TEXT --Дополнительная информация по сделке, передаваемая торговой системой
,uid                                                                                                      REAL --Идентификатор пользователя на сервере QUIK
 
 
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
                                
                                 
--Параметр Тип Описание
 
,client_code      		TEXT -- Код клиента 
,trade_num              REAL -- Номер сделки в торговой системе
,sec_code               TEXT -- Код бумаги заявки 
,class_code             TEXT -- Код класса 
,price                  REAL -- Цена 
,qty                    REAL -- Количество бумаг в последней сделке в лотах 

--мои поля
,date                   TEXT -- получаем из таблицы datetime, наверное сразу в виде гггг-мм-дд
,time                   TEXT -- получаем из таблицы datetime
,robot_id            	TEXT -- наверное, будем заполнять потом, т.к. пока непонятно, как это делать в событии OnTrade() да надо ли это делать там?
,signal_id				TEXT --

,direction            	TEXT -- buy/sell
--мои поля конец
 
,order_num       		REAL -- Номер заявки в торговой системе 
,brokerref              TEXT -- Комментарий, обычно: <код клиента>/<номер поручения> 
,userid                 TEXT -- Идентификатор трейдера 
,firmid					TEXT -- Идентификатор дилера 
,account                TEXT -- Торговый счет 
,value                  REAL -- Объем в денежных средствах 
,flags                  REAL -- Набор битовых флагов 
,trade_currency         TEXT -- Валюта 
,trans_id               REAL  --Идентификатор транзакции -- ПОЛЬЗОВАТЕЛЬСКИЙ!!!!! при программном создании , чтобы потом можно было отловить

          );  
        ]=]
return sql
end

