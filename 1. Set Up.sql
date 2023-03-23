USE ROLE USERADMIN;
CREATE OR REPLACE ROLE CHEESEMONGER;
GRANT ROLE CHEESEMONGER TO ROLE SYSADMIN;
CREATE OR REPLACE ROLE SHOPCLERK;
GRANT ROLE SHOPCLERK TO ROLE SYSADMIN;
CREATE OR REPLACE ROLE CUSTOMER;
GRANT ROLE CUSTOMER TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
CREATE OR REPLACE DATABASE DEV_DB;

USE DATABASE DEV_DB;
CREATE OR REPLACE SCHEMA SCHEMACHANGE WITH MANAGED ACCESS;
CREATE OR REPLACE SCHEMA CHEESESHOP WITH MANAGED ACCESS;


CREATE OR REPLACE WAREHOUSE CHEESE_WH;
GRANT USAGE ON WAREHOUSE CHEESE_WH TO CHEESEMONGER;
GRANT USAGE ON WAREHOUSE CHEESE_WH TO SHOPCLERK;
GRANT USAGE ON WAREHOUSE CHEESE_WH TO CUSTOMER;


USE SCHEMA CHEESESHOP;

GRANT USAGE ON DATABASE DEV_DB TO ROLE CHEESEMONGER;
GRANT OWNERSHIP ON SCHEMA CHEESESHOP TO ROLE CHEESEMONGER;
GRANT USAGE ON DATABASE DEV_DB TO ROLE SHOPCLERK;
GRANT USAGE ON SCHEMA CHEESESHOP TO ROLE SHOPCLERK;


GRANT OWNERSHIP ON FUTURE TABLES IN SCHEMA CHEESESHOP TO ROLE CHEESEMONGER;
GRANT OWNERSHIP ON FUTURE VIEWS IN SCHEMA CHEESESHOP TO ROLE CHEESEMONGER;

GRANT SELECT, INSERT, UPDATE, TRUNCATE, DELETE, REFERENCES ON FUTURE TABLES IN SCHEMA CHEESESHOP TO ROLE SHOPCLERK;
GRANT SELECT, REFERENCES ON FUTURE VIEWS IN SCHEMA CHEESESHOP TO ROLE SHOPCLERK;

GRANT SELECT ON FUTURE VIEWS IN SCHEMA CHEESESHOP TO ROLE CUSTOMER;

USE ROLE CHEESEMONGER;
CREATE OR REPLACE TABLE CATALOG (
	NAME STRING,
    SOURCE STRING,
    NOTES STRING,
    QTY INT
    );
CREATE OR REPLACE VIEW INVENTORY AS
SELECT *
FROM CATALOG
WHERE QTY > 0;

USE ROLE SHOPCLERK;
INSERT INTO CATALOG VALUES
('Dunbarton Blue','COW','A wondefully vieny blue',2),
('Parmesean DOC','COW','The Usual, but better',3.5),
('Drunken Goat','GOAT','Not as boozy as expected',0),
('Feta','GOAT','Good in Salads',14),
('Gjetost','COW/GOAT','YAY-TOAST',1),
('Headcheese','PIG','technically not cheese',0);


GRANT USAGE ON DATABASE DEV_DB TO ROLE CUSTOMER;
GRANT USAGE ON SCHEMA CHEESESHOP TO ROLE CUSTOMER;



