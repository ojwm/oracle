CREATE TABLE broker
  (name VARCHAR2(50),
   CONSTRAINT broker_pk
      PRIMARY KEY (name))
/

INSERT INTO broker (name)
VALUES             ('Hargreaves Lansdown')
/

CREATE TABLE broker_fee
  (broker_name  VARCHAR2(50),
   fee_category VARCHAR2(20),
   fee_type     VARCHAR2(10),
   fee_amount   NUMBER,
   CONSTRAINT broker_fee_pk
      PRIMARY KEY (broker_name, fee_category, fee_type, fee_amount),
   CONSTRAINT broker_fee_broker_name_fk
      FOREIGN KEY (broker_name)
      REFERENCES broker(name))
ORGANIZATION INDEX
/

INSERT INTO broker_fee (broker_name,fee_category,fee_type,fee_amount)
VALUES                 ('Hargreaves Lansdown','Online','Flat',11.95)
/
INSERT INTO broker_fee (broker_name,fee_category,fee_type,fee_amount)
VALUES                 ('Hargreaves Lansdown','Phone','Flat',20)
/
INSERT INTO broker_fee (broker_name,fee_category,fee_type,fee_amount)
VALUES                 ('Hargreaves Lansdown','ForEx Commission','Percent',1.5)
/
INSERT INTO broker_fee (broker_name,fee_category,fee_type,fee_amount)
VALUES                 ('Hargreaves Lansdown','Stamp Duty','Percent',0.5)
/

UPDATE broker_fee
SET    fee_amount = fee_amount*100
WHERE  fee_type = 'Percent';

DROP TABLE stock PURGE
/

CREATE TABLE stock
  (stock_symbol         VARCHAR2(5),
   stock_name           VARCHAR2(255),
   broker_name          VARCHAR2(50),
   price                NUMBER CONSTRAINT stock_price_nn NOT NULL,
   currency             VARCHAR2(3) DEFAULT 'GBP' CONSTRAINT stock_currency_nn NOT NULL,
   trade_type           VARCHAR2(10) CONSTRAINT stock_trade_type_nn NOT NULL,
   trade_fee            NUMBER CONSTRAINT stock_trade_fee_nn NOT NULL,
   investment_amt       NUMBER,
   projected_growth_pct NUMBER,
   CONSTRAINT stock_pk
      PRIMARY KEY (stock_symbol,broker_name,trade_type),
   CONSTRAINT stock_broker_name_fk
      FOREIGN KEY (broker_name)
      REFERENCES broker (name))
/