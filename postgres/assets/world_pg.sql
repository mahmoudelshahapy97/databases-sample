-- =============================================================================
-- world_pg.sql  —  World Database schema for PostgreSQL
-- =============================================================================
-- Converted from MySQL world database (postgres/data/world/world.sql)
-- Original: https://dev.mysql.com/doc/index-other.html
--
-- Tables: country (239 rows), city (4 079 rows), countrylanguage (984 rows)
-- =============================================================================

-- Continent check values
-- 'Asia','Europe','North America','Africa','Oceania','Antarctica','South America'

CREATE TABLE country (
    code            CHAR(3)         NOT NULL DEFAULT '',
    name            VARCHAR(52)     NOT NULL DEFAULT '',
    continent       VARCHAR(20)     NOT NULL DEFAULT 'Asia'
                        CHECK (continent IN (
                            'Asia','Europe','North America','Africa',
                            'Oceania','Antarctica','South America'
                        )),
    region          VARCHAR(26)     NOT NULL DEFAULT '',
    surfacearea     DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    indepyear       SMALLINT,
    population      INT             NOT NULL DEFAULT 0,
    lifeexpectancy  DECIMAL(3,1),
    gnp             DECIMAL(10,2),
    gnpold          DECIMAL(10,2),
    localname       VARCHAR(45)     NOT NULL DEFAULT '',
    governmentform  VARCHAR(45)     NOT NULL DEFAULT '',
    headofstate     VARCHAR(60),
    capital         INT,                        -- FK to city.id (deferred below)
    code2           CHAR(2)         NOT NULL DEFAULT '',
    CONSTRAINT pk_country PRIMARY KEY (code)
);

CREATE TABLE city (
    id          SERIAL          NOT NULL,
    name        VARCHAR(35)     NOT NULL DEFAULT '',
    countrycode CHAR(3)         NOT NULL DEFAULT '',
    district    VARCHAR(20)     NOT NULL DEFAULT '',
    population  INT             NOT NULL DEFAULT 0,
    CONSTRAINT pk_city PRIMARY KEY (id)
);

CREATE TABLE countrylanguage (
    countrycode VARCHAR(3)      NOT NULL DEFAULT '',
    language    VARCHAR(30)     NOT NULL DEFAULT '',
    isofficial  CHAR(1)         NOT NULL DEFAULT 'F'
                    CHECK (isofficial IN ('T','F')),
    percentage  DECIMAL(4,1)    NOT NULL DEFAULT 0.0,
    CONSTRAINT pk_countrylanguage PRIMARY KEY (countrycode, language)
);

-- ---------------------------------------------------------------------------
-- Foreign keys  (declared DEFERRABLE to handle the country ↔ city cycle)
-- country.capital  →  city.id
-- city.countrycode →  country.code
-- ---------------------------------------------------------------------------
ALTER TABLE city
    ADD CONSTRAINT fk_city_country
    FOREIGN KEY (countrycode) REFERENCES country (code)
    DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE countrylanguage
    ADD CONSTRAINT fk_countrylanguage_country
    FOREIGN KEY (countrycode) REFERENCES country (code)
    DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE country
    ADD CONSTRAINT fk_country_capital
    FOREIGN KEY (capital) REFERENCES city (id)
    DEFERRABLE INITIALLY DEFERRED;

-- Indexes
CREATE INDEX idx_city_countrycode         ON city            (countrycode);
CREATE INDEX idx_countrylanguage_country  ON countrylanguage (countrycode);
CREATE INDEX idx_country_continent        ON country         (continent);
