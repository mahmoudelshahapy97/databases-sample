-- =============================================================================
-- sh_load_csv.sql  --  Bulk-load the six SH (Sales History) CSV data files
-- =============================================================================
-- GENERATED FILE -- produced by oracle/tools/gen_sh_load_csv.sh from the CSV
-- headers in oracle/data/sales_history/. Re-run the generator
-- instead of editing by hand.
--
-- WHY THIS FILE EXISTS
--   Upstream sh_populate.sql loads these tables with SQLcl's `LOAD <table>
--   <file>.csv` command. SQLcl is a separate Java tool that is not present in
--   the gvenzl/oracle-xe image, so 04_sh.sh rewrites those six LOAD lines into
--   a single @-call to this script, which does the same work with external
--   tables (a core database feature -- no extra binaries required).
--
-- ASSUMPTIONS
--   * Directory object SH_CSV_DIR points at /source/sales_history
--     and SH has READ on it (created by 04_sh.sh as SYSTEM).
--   * Called from sh_populate.sql at the point where all table constraints are
--     still DISABLED and the bitmap indexes have not been created yet.
--   * The CSV mount is read-only, hence NOBADFILE / NOLOGFILE / NODISCARDFILE.
--
-- HOW THE CONVERSION WORKS
--   Each staging column is VARCHAR2 and each INSERT relies on implicit
--   conversion to the real column type, driven by the NLS settings below. The
--   longest line in any of these CSVs is 756 bytes, so 1000 is ample.
--   LRTRIM matters: sales.csv pads its last field with trailing spaces.
--   SKIP 1 discards the header row.
-- =============================================================================

SET DEFINE OFF
SET ECHO OFF
SET FEEDBACK 1

ALTER SESSION SET NLS_LANGUAGE           = American;
ALTER SESSION SET NLS_TERRITORY          = America;
ALTER SESSION SET NLS_DATE_FORMAT        = 'YYYY-MM-DD';
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

-- ---------------------------------------------------------------------------
-- times  <-  times.csv  (38 columns)
-- ---------------------------------------------------------------------------
PROMPT ******  Loading times from times.csv ....

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE times_ext';
EXCEPTION
   WHEN OTHERS THEN NULL;   -- first run: nothing to drop
END;
/

CREATE TABLE times_ext (
   TIME_ID                        VARCHAR2(1000),
   DAY_NAME                       VARCHAR2(1000),
   DAY_NUMBER_IN_WEEK             VARCHAR2(1000),
   DAY_NUMBER_IN_MONTH            VARCHAR2(1000),
   CALENDAR_WEEK_NUMBER           VARCHAR2(1000),
   FISCAL_WEEK_NUMBER             VARCHAR2(1000),
   WEEK_ENDING_DAY                VARCHAR2(1000),
   WEEK_ENDING_DAY_ID             VARCHAR2(1000),
   CALENDAR_MONTH_NUMBER          VARCHAR2(1000),
   FISCAL_MONTH_NUMBER            VARCHAR2(1000),
   CALENDAR_MONTH_DESC            VARCHAR2(1000),
   CALENDAR_MONTH_ID              VARCHAR2(1000),
   FISCAL_MONTH_DESC              VARCHAR2(1000),
   FISCAL_MONTH_ID                VARCHAR2(1000),
   DAYS_IN_CAL_MONTH              VARCHAR2(1000),
   DAYS_IN_FIS_MONTH              VARCHAR2(1000),
   END_OF_CAL_MONTH               VARCHAR2(1000),
   END_OF_FIS_MONTH               VARCHAR2(1000),
   CALENDAR_MONTH_NAME            VARCHAR2(1000),
   FISCAL_MONTH_NAME              VARCHAR2(1000),
   CALENDAR_QUARTER_DESC          VARCHAR2(1000),
   CALENDAR_QUARTER_ID            VARCHAR2(1000),
   FISCAL_QUARTER_DESC            VARCHAR2(1000),
   FISCAL_QUARTER_ID              VARCHAR2(1000),
   DAYS_IN_CAL_QUARTER            VARCHAR2(1000),
   DAYS_IN_FIS_QUARTER            VARCHAR2(1000),
   END_OF_CAL_QUARTER             VARCHAR2(1000),
   END_OF_FIS_QUARTER             VARCHAR2(1000),
   CALENDAR_QUARTER_NUMBER        VARCHAR2(1000),
   FISCAL_QUARTER_NUMBER          VARCHAR2(1000),
   CALENDAR_YEAR                  VARCHAR2(1000),
   CALENDAR_YEAR_ID               VARCHAR2(1000),
   FISCAL_YEAR                    VARCHAR2(1000),
   FISCAL_YEAR_ID                 VARCHAR2(1000),
   DAYS_IN_CAL_YEAR               VARCHAR2(1000),
   DAYS_IN_FIS_YEAR               VARCHAR2(1000),
   END_OF_CAL_YEAR                VARCHAR2(1000),
   END_OF_FIS_YEAR                VARCHAR2(1000)
)
ORGANIZATION EXTERNAL (
   TYPE ORACLE_LOADER
   DEFAULT DIRECTORY sh_csv_dir
   ACCESS PARAMETERS (
      RECORDS DELIMITED BY NEWLINE
      CHARACTERSET AL32UTF8
      SKIP 1
      NOBADFILE
      NOLOGFILE
      NODISCARDFILE
      FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
      MISSING FIELD VALUES ARE NULL
      REJECT ROWS WITH ALL NULL FIELDS
      (
        TIME_ID                        CHAR(1000),
        DAY_NAME                       CHAR(1000),
        DAY_NUMBER_IN_WEEK             CHAR(1000),
        DAY_NUMBER_IN_MONTH            CHAR(1000),
        CALENDAR_WEEK_NUMBER           CHAR(1000),
        FISCAL_WEEK_NUMBER             CHAR(1000),
        WEEK_ENDING_DAY                CHAR(1000),
        WEEK_ENDING_DAY_ID             CHAR(1000),
        CALENDAR_MONTH_NUMBER          CHAR(1000),
        FISCAL_MONTH_NUMBER            CHAR(1000),
        CALENDAR_MONTH_DESC            CHAR(1000),
        CALENDAR_MONTH_ID              CHAR(1000),
        FISCAL_MONTH_DESC              CHAR(1000),
        FISCAL_MONTH_ID                CHAR(1000),
        DAYS_IN_CAL_MONTH              CHAR(1000),
        DAYS_IN_FIS_MONTH              CHAR(1000),
        END_OF_CAL_MONTH               CHAR(1000),
        END_OF_FIS_MONTH               CHAR(1000),
        CALENDAR_MONTH_NAME            CHAR(1000),
        FISCAL_MONTH_NAME              CHAR(1000),
        CALENDAR_QUARTER_DESC          CHAR(1000),
        CALENDAR_QUARTER_ID            CHAR(1000),
        FISCAL_QUARTER_DESC            CHAR(1000),
        FISCAL_QUARTER_ID              CHAR(1000),
        DAYS_IN_CAL_QUARTER            CHAR(1000),
        DAYS_IN_FIS_QUARTER            CHAR(1000),
        END_OF_CAL_QUARTER             CHAR(1000),
        END_OF_FIS_QUARTER             CHAR(1000),
        CALENDAR_QUARTER_NUMBER        CHAR(1000),
        FISCAL_QUARTER_NUMBER          CHAR(1000),
        CALENDAR_YEAR                  CHAR(1000),
        CALENDAR_YEAR_ID               CHAR(1000),
        FISCAL_YEAR                    CHAR(1000),
        FISCAL_YEAR_ID                 CHAR(1000),
        DAYS_IN_CAL_YEAR               CHAR(1000),
        DAYS_IN_FIS_YEAR               CHAR(1000),
        END_OF_CAL_YEAR                CHAR(1000),
        END_OF_FIS_YEAR                CHAR(1000)
      )
   )
   LOCATION ('times.csv')
)
REJECT LIMIT UNLIMITED
NOPARALLEL;

INSERT /*+ APPEND */ INTO times (
          TIME_ID, DAY_NAME, DAY_NUMBER_IN_WEEK, DAY_NUMBER_IN_MONTH, 
          CALENDAR_WEEK_NUMBER, FISCAL_WEEK_NUMBER, WEEK_ENDING_DAY, 
          WEEK_ENDING_DAY_ID, CALENDAR_MONTH_NUMBER, FISCAL_MONTH_NUMBER, 
          CALENDAR_MONTH_DESC, CALENDAR_MONTH_ID, FISCAL_MONTH_DESC, 
          FISCAL_MONTH_ID, DAYS_IN_CAL_MONTH, DAYS_IN_FIS_MONTH, 
          END_OF_CAL_MONTH, END_OF_FIS_MONTH, CALENDAR_MONTH_NAME, 
          FISCAL_MONTH_NAME, CALENDAR_QUARTER_DESC, CALENDAR_QUARTER_ID, 
          FISCAL_QUARTER_DESC, FISCAL_QUARTER_ID, DAYS_IN_CAL_QUARTER, 
          DAYS_IN_FIS_QUARTER, END_OF_CAL_QUARTER, END_OF_FIS_QUARTER, 
          CALENDAR_QUARTER_NUMBER, FISCAL_QUARTER_NUMBER, CALENDAR_YEAR, 
          CALENDAR_YEAR_ID, FISCAL_YEAR, FISCAL_YEAR_ID, DAYS_IN_CAL_YEAR, 
          DAYS_IN_FIS_YEAR, END_OF_CAL_YEAR, END_OF_FIS_YEAR
)
SELECT
          TIME_ID, DAY_NAME, DAY_NUMBER_IN_WEEK, DAY_NUMBER_IN_MONTH, 
          CALENDAR_WEEK_NUMBER, FISCAL_WEEK_NUMBER, WEEK_ENDING_DAY, 
          WEEK_ENDING_DAY_ID, CALENDAR_MONTH_NUMBER, FISCAL_MONTH_NUMBER, 
          CALENDAR_MONTH_DESC, CALENDAR_MONTH_ID, FISCAL_MONTH_DESC, 
          FISCAL_MONTH_ID, DAYS_IN_CAL_MONTH, DAYS_IN_FIS_MONTH, 
          END_OF_CAL_MONTH, END_OF_FIS_MONTH, CALENDAR_MONTH_NAME, 
          FISCAL_MONTH_NAME, CALENDAR_QUARTER_DESC, CALENDAR_QUARTER_ID, 
          FISCAL_QUARTER_DESC, FISCAL_QUARTER_ID, DAYS_IN_CAL_QUARTER, 
          DAYS_IN_FIS_QUARTER, END_OF_CAL_QUARTER, END_OF_FIS_QUARTER, 
          CALENDAR_QUARTER_NUMBER, FISCAL_QUARTER_NUMBER, CALENDAR_YEAR, 
          CALENDAR_YEAR_ID, FISCAL_YEAR, FISCAL_YEAR_ID, DAYS_IN_CAL_YEAR, 
          DAYS_IN_FIS_YEAR, END_OF_CAL_YEAR, END_OF_FIS_YEAR
FROM times_ext;

COMMIT;

DROP TABLE times_ext;

-- ---------------------------------------------------------------------------
-- promotions  <-  promotions.csv  (11 columns)
-- ---------------------------------------------------------------------------
PROMPT ******  Loading promotions from promotions.csv ....

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE promotions_ext';
EXCEPTION
   WHEN OTHERS THEN NULL;   -- first run: nothing to drop
END;
/

CREATE TABLE promotions_ext (
   PROMO_ID                       VARCHAR2(1000),
   PROMO_NAME                     VARCHAR2(1000),
   PROMO_SUBCATEGORY              VARCHAR2(1000),
   PROMO_SUBCATEGORY_ID           VARCHAR2(1000),
   PROMO_CATEGORY                 VARCHAR2(1000),
   PROMO_CATEGORY_ID              VARCHAR2(1000),
   PROMO_COST                     VARCHAR2(1000),
   PROMO_BEGIN_DATE               VARCHAR2(1000),
   PROMO_END_DATE                 VARCHAR2(1000),
   PROMO_TOTAL                    VARCHAR2(1000),
   PROMO_TOTAL_ID                 VARCHAR2(1000)
)
ORGANIZATION EXTERNAL (
   TYPE ORACLE_LOADER
   DEFAULT DIRECTORY sh_csv_dir
   ACCESS PARAMETERS (
      RECORDS DELIMITED BY NEWLINE
      CHARACTERSET AL32UTF8
      SKIP 1
      NOBADFILE
      NOLOGFILE
      NODISCARDFILE
      FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
      MISSING FIELD VALUES ARE NULL
      REJECT ROWS WITH ALL NULL FIELDS
      (
        PROMO_ID                       CHAR(1000),
        PROMO_NAME                     CHAR(1000),
        PROMO_SUBCATEGORY              CHAR(1000),
        PROMO_SUBCATEGORY_ID           CHAR(1000),
        PROMO_CATEGORY                 CHAR(1000),
        PROMO_CATEGORY_ID              CHAR(1000),
        PROMO_COST                     CHAR(1000),
        PROMO_BEGIN_DATE               CHAR(1000),
        PROMO_END_DATE                 CHAR(1000),
        PROMO_TOTAL                    CHAR(1000),
        PROMO_TOTAL_ID                 CHAR(1000)
      )
   )
   LOCATION ('promotions.csv')
)
REJECT LIMIT UNLIMITED
NOPARALLEL;

INSERT /*+ APPEND */ INTO promotions (
          PROMO_ID, PROMO_NAME, PROMO_SUBCATEGORY, PROMO_SUBCATEGORY_ID, 
          PROMO_CATEGORY, PROMO_CATEGORY_ID, PROMO_COST, PROMO_BEGIN_DATE, 
          PROMO_END_DATE, PROMO_TOTAL, PROMO_TOTAL_ID
)
SELECT
          PROMO_ID, PROMO_NAME, PROMO_SUBCATEGORY, PROMO_SUBCATEGORY_ID, 
          PROMO_CATEGORY, PROMO_CATEGORY_ID, PROMO_COST, PROMO_BEGIN_DATE, 
          PROMO_END_DATE, PROMO_TOTAL, PROMO_TOTAL_ID
FROM promotions_ext;

COMMIT;

DROP TABLE promotions_ext;

-- ---------------------------------------------------------------------------
-- customers  <-  customers.csv  (23 columns)
-- ---------------------------------------------------------------------------
PROMPT ******  Loading customers from customers.csv ....

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE customers_ext';
EXCEPTION
   WHEN OTHERS THEN NULL;   -- first run: nothing to drop
END;
/

CREATE TABLE customers_ext (
   CUST_ID                        VARCHAR2(1000),
   CUST_FIRST_NAME                VARCHAR2(1000),
   CUST_LAST_NAME                 VARCHAR2(1000),
   CUST_GENDER                    VARCHAR2(1000),
   CUST_YEAR_OF_BIRTH             VARCHAR2(1000),
   CUST_MARITAL_STATUS            VARCHAR2(1000),
   CUST_STREET_ADDRESS            VARCHAR2(1000),
   CUST_POSTAL_CODE               VARCHAR2(1000),
   CUST_CITY                      VARCHAR2(1000),
   CUST_CITY_ID                   VARCHAR2(1000),
   CUST_STATE_PROVINCE            VARCHAR2(1000),
   CUST_STATE_PROVINCE_ID         VARCHAR2(1000),
   COUNTRY_ID                     VARCHAR2(1000),
   CUST_MAIN_PHONE_NUMBER         VARCHAR2(1000),
   CUST_INCOME_LEVEL              VARCHAR2(1000),
   CUST_CREDIT_LIMIT              VARCHAR2(1000),
   CUST_EMAIL                     VARCHAR2(1000),
   CUST_TOTAL                     VARCHAR2(1000),
   CUST_TOTAL_ID                  VARCHAR2(1000),
   CUST_SRC_ID                    VARCHAR2(1000),
   CUST_EFF_FROM                  VARCHAR2(1000),
   CUST_EFF_TO                    VARCHAR2(1000),
   CUST_VALID                     VARCHAR2(1000)
)
ORGANIZATION EXTERNAL (
   TYPE ORACLE_LOADER
   DEFAULT DIRECTORY sh_csv_dir
   ACCESS PARAMETERS (
      RECORDS DELIMITED BY NEWLINE
      CHARACTERSET AL32UTF8
      SKIP 1
      NOBADFILE
      NOLOGFILE
      NODISCARDFILE
      FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
      MISSING FIELD VALUES ARE NULL
      REJECT ROWS WITH ALL NULL FIELDS
      (
        CUST_ID                        CHAR(1000),
        CUST_FIRST_NAME                CHAR(1000),
        CUST_LAST_NAME                 CHAR(1000),
        CUST_GENDER                    CHAR(1000),
        CUST_YEAR_OF_BIRTH             CHAR(1000),
        CUST_MARITAL_STATUS            CHAR(1000),
        CUST_STREET_ADDRESS            CHAR(1000),
        CUST_POSTAL_CODE               CHAR(1000),
        CUST_CITY                      CHAR(1000),
        CUST_CITY_ID                   CHAR(1000),
        CUST_STATE_PROVINCE            CHAR(1000),
        CUST_STATE_PROVINCE_ID         CHAR(1000),
        COUNTRY_ID                     CHAR(1000),
        CUST_MAIN_PHONE_NUMBER         CHAR(1000),
        CUST_INCOME_LEVEL              CHAR(1000),
        CUST_CREDIT_LIMIT              CHAR(1000),
        CUST_EMAIL                     CHAR(1000),
        CUST_TOTAL                     CHAR(1000),
        CUST_TOTAL_ID                  CHAR(1000),
        CUST_SRC_ID                    CHAR(1000),
        CUST_EFF_FROM                  CHAR(1000),
        CUST_EFF_TO                    CHAR(1000),
        CUST_VALID                     CHAR(1000)
      )
   )
   LOCATION ('customers.csv')
)
REJECT LIMIT UNLIMITED
NOPARALLEL;

INSERT /*+ APPEND */ INTO customers (
          CUST_ID, CUST_FIRST_NAME, CUST_LAST_NAME, CUST_GENDER, 
          CUST_YEAR_OF_BIRTH, CUST_MARITAL_STATUS, CUST_STREET_ADDRESS, 
          CUST_POSTAL_CODE, CUST_CITY, CUST_CITY_ID, CUST_STATE_PROVINCE, 
          CUST_STATE_PROVINCE_ID, COUNTRY_ID, CUST_MAIN_PHONE_NUMBER, 
          CUST_INCOME_LEVEL, CUST_CREDIT_LIMIT, CUST_EMAIL, CUST_TOTAL, 
          CUST_TOTAL_ID, CUST_SRC_ID, CUST_EFF_FROM, CUST_EFF_TO, CUST_VALID
)
SELECT
          CUST_ID, CUST_FIRST_NAME, CUST_LAST_NAME, CUST_GENDER, 
          CUST_YEAR_OF_BIRTH, CUST_MARITAL_STATUS, CUST_STREET_ADDRESS, 
          CUST_POSTAL_CODE, CUST_CITY, CUST_CITY_ID, CUST_STATE_PROVINCE, 
          CUST_STATE_PROVINCE_ID, COUNTRY_ID, CUST_MAIN_PHONE_NUMBER, 
          CUST_INCOME_LEVEL, CUST_CREDIT_LIMIT, CUST_EMAIL, CUST_TOTAL, 
          CUST_TOTAL_ID, CUST_SRC_ID, CUST_EFF_FROM, CUST_EFF_TO, CUST_VALID
FROM customers_ext;

COMMIT;

DROP TABLE customers_ext;

-- ---------------------------------------------------------------------------
-- costs  <-  costs.csv  (6 columns)
-- ---------------------------------------------------------------------------
PROMPT ******  Loading costs from costs.csv ....

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE costs_ext';
EXCEPTION
   WHEN OTHERS THEN NULL;   -- first run: nothing to drop
END;
/

CREATE TABLE costs_ext (
   PROD_ID                        VARCHAR2(1000),
   TIME_ID                        VARCHAR2(1000),
   PROMO_ID                       VARCHAR2(1000),
   CHANNEL_ID                     VARCHAR2(1000),
   UNIT_COST                      VARCHAR2(1000),
   UNIT_PRICE                     VARCHAR2(1000)
)
ORGANIZATION EXTERNAL (
   TYPE ORACLE_LOADER
   DEFAULT DIRECTORY sh_csv_dir
   ACCESS PARAMETERS (
      RECORDS DELIMITED BY NEWLINE
      CHARACTERSET AL32UTF8
      SKIP 1
      NOBADFILE
      NOLOGFILE
      NODISCARDFILE
      FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
      MISSING FIELD VALUES ARE NULL
      REJECT ROWS WITH ALL NULL FIELDS
      (
        PROD_ID                        CHAR(1000),
        TIME_ID                        CHAR(1000),
        PROMO_ID                       CHAR(1000),
        CHANNEL_ID                     CHAR(1000),
        UNIT_COST                      CHAR(1000),
        UNIT_PRICE                     CHAR(1000)
      )
   )
   LOCATION ('costs.csv')
)
REJECT LIMIT UNLIMITED
NOPARALLEL;

INSERT /*+ APPEND */ INTO costs (
          PROD_ID, TIME_ID, PROMO_ID, CHANNEL_ID, UNIT_COST, UNIT_PRICE
)
SELECT
          PROD_ID, TIME_ID, PROMO_ID, CHANNEL_ID, UNIT_COST, UNIT_PRICE
FROM costs_ext;

COMMIT;

DROP TABLE costs_ext;

-- ---------------------------------------------------------------------------
-- sales  <-  sales.csv  (7 columns)
-- ---------------------------------------------------------------------------
PROMPT ******  Loading sales from sales.csv ....

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE sales_ext';
EXCEPTION
   WHEN OTHERS THEN NULL;   -- first run: nothing to drop
END;
/

CREATE TABLE sales_ext (
   PROD_ID                        VARCHAR2(1000),
   CUST_ID                        VARCHAR2(1000),
   TIME_ID                        VARCHAR2(1000),
   CHANNEL_ID                     VARCHAR2(1000),
   PROMO_ID                       VARCHAR2(1000),
   QUANTITY_SOLD                  VARCHAR2(1000),
   AMOUNT_SOLD                    VARCHAR2(1000)
)
ORGANIZATION EXTERNAL (
   TYPE ORACLE_LOADER
   DEFAULT DIRECTORY sh_csv_dir
   ACCESS PARAMETERS (
      RECORDS DELIMITED BY NEWLINE
      CHARACTERSET AL32UTF8
      SKIP 1
      NOBADFILE
      NOLOGFILE
      NODISCARDFILE
      FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
      MISSING FIELD VALUES ARE NULL
      REJECT ROWS WITH ALL NULL FIELDS
      (
        PROD_ID                        CHAR(1000),
        CUST_ID                        CHAR(1000),
        TIME_ID                        CHAR(1000),
        CHANNEL_ID                     CHAR(1000),
        PROMO_ID                       CHAR(1000),
        QUANTITY_SOLD                  CHAR(1000),
        AMOUNT_SOLD                    CHAR(1000)
      )
   )
   LOCATION ('sales.csv')
)
REJECT LIMIT UNLIMITED
NOPARALLEL;

INSERT /*+ APPEND */ INTO sales (
          PROD_ID, CUST_ID, TIME_ID, CHANNEL_ID, PROMO_ID, QUANTITY_SOLD, 
          AMOUNT_SOLD
)
SELECT
          PROD_ID, CUST_ID, TIME_ID, CHANNEL_ID, PROMO_ID, QUANTITY_SOLD, 
          AMOUNT_SOLD
FROM sales_ext;

COMMIT;

DROP TABLE sales_ext;

-- ---------------------------------------------------------------------------
-- supplementary_demographics  <-  supplementary_demographics.csv  (14 columns)
-- ---------------------------------------------------------------------------
PROMPT ******  Loading supplementary_demographics from supplementary_demographics.csv ....

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE supplementary_demographics_ext';
EXCEPTION
   WHEN OTHERS THEN NULL;   -- first run: nothing to drop
END;
/

CREATE TABLE supplementary_demographics_ext (
   CUST_ID                        VARCHAR2(1000),
   EDUCATION                      VARCHAR2(1000),
   OCCUPATION                     VARCHAR2(1000),
   HOUSEHOLD_SIZE                 VARCHAR2(1000),
   YRS_RESIDENCE                  VARCHAR2(1000),
   AFFINITY_CARD                  VARCHAR2(1000),
   CRICKET                        VARCHAR2(1000),
   BASEBALL                       VARCHAR2(1000),
   TENNIS                         VARCHAR2(1000),
   SOCCER                         VARCHAR2(1000),
   GOLF                           VARCHAR2(1000),
   UNKNOWN                        VARCHAR2(1000),
   MISC                           VARCHAR2(1000),
   COMMENTS                       VARCHAR2(1000)
)
ORGANIZATION EXTERNAL (
   TYPE ORACLE_LOADER
   DEFAULT DIRECTORY sh_csv_dir
   ACCESS PARAMETERS (
      RECORDS DELIMITED BY NEWLINE
      CHARACTERSET AL32UTF8
      SKIP 1
      NOBADFILE
      NOLOGFILE
      NODISCARDFILE
      FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LRTRIM
      MISSING FIELD VALUES ARE NULL
      REJECT ROWS WITH ALL NULL FIELDS
      (
        CUST_ID                        CHAR(1000),
        EDUCATION                      CHAR(1000),
        OCCUPATION                     CHAR(1000),
        HOUSEHOLD_SIZE                 CHAR(1000),
        YRS_RESIDENCE                  CHAR(1000),
        AFFINITY_CARD                  CHAR(1000),
        CRICKET                        CHAR(1000),
        BASEBALL                       CHAR(1000),
        TENNIS                         CHAR(1000),
        SOCCER                         CHAR(1000),
        GOLF                           CHAR(1000),
        UNKNOWN                        CHAR(1000),
        MISC                           CHAR(1000),
        COMMENTS                       CHAR(1000)
      )
   )
   LOCATION ('supplementary_demographics.csv')
)
REJECT LIMIT UNLIMITED
NOPARALLEL;

INSERT /*+ APPEND */ INTO supplementary_demographics (
          CUST_ID, EDUCATION, OCCUPATION, HOUSEHOLD_SIZE, YRS_RESIDENCE, 
          AFFINITY_CARD, CRICKET, BASEBALL, TENNIS, SOCCER, GOLF, UNKNOWN, 
          MISC, COMMENTS
)
SELECT
          CUST_ID, EDUCATION, OCCUPATION, HOUSEHOLD_SIZE, YRS_RESIDENCE, 
          AFFINITY_CARD, CRICKET, BASEBALL, TENNIS, SOCCER, GOLF, UNKNOWN, 
          MISC, COMMENTS
FROM supplementary_demographics_ext;

COMMIT;

DROP TABLE supplementary_demographics_ext;

PROMPT ******  CSV load complete.
