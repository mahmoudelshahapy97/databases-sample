CREATE DATABASE IF NOT EXISTS `mondial` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `mondial`;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE country
(Name VARCHAR(50) NOT NULL UNIQUE,
 Code VARCHAR(4) PRIMARY KEY,
 Capital VARCHAR(50),
 Province VARCHAR(50),
 Area DOUBLE CONSTRAINT CountryArea
   CHECK (Area >= 0),
 Population DOUBLE CONSTRAINT CountryPop
   CHECK (Population >= 0));

CREATE TABLE city
(Name VARCHAR(50),
 Country VARCHAR(4),
 Province VARCHAR(50),
 Population DOUBLE CONSTRAINT CityPop
   CHECK (Population >= 0),
 Latitude DOUBLE CONSTRAINT CityLat
   CHECK ((Latitude >= -90) AND (Latitude <= 90)) ,
 Longitude DOUBLE CONSTRAINT CityLon
   CHECK ((Longitude >= -180) AND (Longitude <= 180)) ,
 Elevation DOUBLE ,
 PRIMARY KEY (Name, Country, Province));

CREATE TABLE province
(Name VARCHAR(50) NOT NULL ,
 Country  VARCHAR(4) NOT NULL ,
 Population DOUBLE CONSTRAINT PrPop
   CHECK (Population >= 0),
 Area DOUBLE CONSTRAINT PrAr
   CHECK (Area >= 0),
 Capital VARCHAR(50),
 CapProv VARCHAR(50),
 PRIMARY KEY (Name, Country));

CREATE TABLE economy
(Country VARCHAR(4) PRIMARY KEY,
 GDP DOUBLE CONSTRAINT EconomyGDP
   CHECK (GDP >= 0),
 Agriculture DOUBLE,
 Service DOUBLE,
 Industry DOUBLE,
 Inflation DOUBLE,
 Unemployment DOUBLE);

CREATE TABLE population
(Country VARCHAR(4) PRIMARY KEY,
 Population_Growth DOUBLE,
 Infant_Mortality DOUBLE);

CREATE TABLE politics
(Country VARCHAR(4) PRIMARY KEY,
 Independence DATE,
 WasDependent VARCHAR(50),
 Dependent  VARCHAR(4),
 Government VARCHAR(120));

CREATE TABLE religion
(Country VARCHAR(4),
 Name VARCHAR(50),
 Percentage DOUBLE CONSTRAINT ReligionPercent 
   CHECK ((Percentage > 0) AND (Percentage <= 100)),
 PRIMARY KEY (Name, Country));

CREATE TABLE ethnicgroup
(Country VARCHAR(4),
 Name VARCHAR(50),
 Percentage DOUBLE CONSTRAINT EthnicPercent 
   CHECK ((Percentage > 0) AND (Percentage <= 100)),
 PRIMARY KEY (Name, Country));

CREATE TABLE spoken
(Country VARCHAR(4),
 Language VARCHAR(50),
 Percentage DOUBLE CONSTRAINT SpokenPercent 
   CHECK ((Percentage > 0) AND (Percentage <= 100)),
 PRIMARY KEY (Country, Language));

CREATE TABLE language
(Name VARCHAR(50) ,
 Superlanguage VARCHAR(50),
 PRIMARY KEY (Name));

CREATE TABLE countrypops
(Country VARCHAR(4),
 Year DOUBLE CONSTRAINT CountryPopsYear
   CHECK (Year >= 0),
 Population DOUBLE CONSTRAINT CountryPopsPop
   CHECK (Population >= 0),
 PRIMARY KEY (Country, Year));

CREATE TABLE countryothername
(Country VARCHAR(4),
 othername VARCHAR(50),
 PRIMARY KEY (Country, othername));

CREATE TABLE countrylocalname
(Country VARCHAR(4),
 localname VARCHAR(300),
 PRIMARY KEY (Country));

CREATE TABLE provpops
(Province VARCHAR(50),
 Country VARCHAR(4),
 Year DOUBLE CONSTRAINT ProvPopsYear
   CHECK (Year >= 0),
 Population DOUBLE CONSTRAINT ProvPopsPop
   CHECK (Population >= 0),
 PRIMARY KEY (Country, Province, Year));

CREATE TABLE provinceothername
(Province VARCHAR(50),
 Country VARCHAR(4),
 othername VARCHAR(50),
 PRIMARY KEY (Country, Province, othername));

CREATE TABLE provincelocalname
(Province VARCHAR(50),
 Country VARCHAR(4),
 localname VARCHAR(300),
 PRIMARY KEY (Country, Province));

CREATE TABLE citypops
(City VARCHAR(50),
 Country VARCHAR(4),
 Province VARCHAR(50),
 Year DOUBLE CONSTRAINT CityPopsYear
   CHECK (Year >= 0),
 Population DOUBLE CONSTRAINT CityPopsPop
   CHECK (Population >= 0),
 PRIMARY KEY (Country, Province, City, Year));

CREATE TABLE cityothername
(City VARCHAR(50),
 Country VARCHAR(4),
 Province VARCHAR(50),
 othername VARCHAR(50),
 PRIMARY KEY (Country, Province, City, othername));

CREATE TABLE citylocalname
(City VARCHAR(50),
 Country VARCHAR(4),
 Province VARCHAR(50),
 localname VARCHAR(300),
 PRIMARY KEY (Country, Province, City));

CREATE TABLE continent
(Name VARCHAR(20) PRIMARY KEY,
 Area DOUBLE);

CREATE TABLE borders
(Country1 VARCHAR(4),
 Country2 VARCHAR(4),
 Length DOUBLE 
   CHECK (Length > 0),
 PRIMARY KEY (Country1,Country2) );

CREATE TABLE encompasses
(Country VARCHAR(4) NOT NULL,
 Continent VARCHAR(20) NOT NULL,
 Percentage DOUBLE,
   CHECK ((Percentage > 0) AND (Percentage <= 100)),
 PRIMARY KEY (Country,Continent));

CREATE TABLE organization
(Abbreviation VARCHAR(12) PRIMARY KEY,
 Name VARCHAR(100) NOT NULL,
 City VARCHAR(50) ,
 Country VARCHAR(4) , 
 Province VARCHAR(50) ,
 Established DATE,
 UNIQUE (Name));

CREATE TABLE ismember
(Country VARCHAR(4),
 Organization VARCHAR(12),
 Type VARCHAR(60) DEFAULT 'member',
 PRIMARY KEY (Country,Organization) );




CREATE TABLE mountain
(
  Name VARCHAR(50) PRIMARY KEY,
  Mountains VARCHAR(50),
  Elevation DOUBLE,
  [Type] VARCHAR(10),
  Latitude DOUBLE,
  Longitude DOUBLE,
  CONSTRAINT MountainCoord CHECK (
    (Latitude >= -90) AND 
    (Latitude <= 90) AND
    (Longitude > -180) AND
    (Longitude <= 180)
  )
);
	
CREATE TABLE desert
(Name VARCHAR(50) PRIMARY KEY,
 Area DOUBLE,
  Latitude DOUBLE,
  Longitude DOUBLE,
 CONSTRAINT DesertCoord CHECK (
    (Latitude >= -90) AND 
    (Latitude <= 90) AND
    (Longitude > -180) AND
    (Longitude <= 180)
  ));

CREATE TABLE island
(Name VARCHAR(50) PRIMARY KEY,
 Islands VARCHAR(50),
 Area DOUBLE CONSTRAINT IslandAr check (Area >= 0),
 Elevation DOUBLE,
 Type VARCHAR(15),
  Latitude DOUBLE,
  Longitude DOUBLE,
 CONSTRAINT IslandCoord CHECK (
    (Latitude >= -90) AND 
    (Latitude <= 90) AND
    (Longitude > -180) AND
    (Longitude <= 180)
  ));

CREATE TABLE lake
(Name VARCHAR(50) PRIMARY KEY,
 River VARCHAR(50),
 Area DOUBLE CONSTRAINT LakeAr CHECK (Area >= 0),
 Elevation DOUBLE,
 Depth DOUBLE CONSTRAINT LakeDpth CHECK (Depth >= 0),
 Height DOUBLE CONSTRAINT DamHeight CHECK (Height > 0),
 Type VARCHAR(12),
  Latitude DOUBLE,
  Longitude DOUBLE,
 CONSTRAINT LakeCoord CHECK (
    (Latitude >= -90) AND 
    (Latitude <= 90) AND
    (Longitude > -180) AND
    (Longitude <= 180)
  ));

CREATE TABLE sea
(Name VARCHAR(50) PRIMARY KEY,
 Area DOUBLE CONSTRAINT SeaAr CHECK (Area >= 0),
 Depth DOUBLE CONSTRAINT SeaDepth CHECK (Depth >= 0));

CREATE TABLE river
(Name VARCHAR(50) PRIMARY KEY,
 River VARCHAR(50),
 Lake VARCHAR(50),
 Sea VARCHAR(50),
 Length DOUBLE CONSTRAINT RiverLength
   CHECK (Length >= 0),
 Area DOUBLE CONSTRAINT RiverArea
   CHECK (Area >= 0),
  sourceLatitude DOUBLE,
  sourceLongitude DOUBLE,
 CONSTRAINT sourceCoord CHECK (
    (sourceLatitude >= -90) AND 
    (sourceLatitude <= 90) AND
    (sourceLongitude > -180) AND
    (sourceLongitude <= 180)
  ),
 Mountains VARCHAR(50),
 SourceElevation DOUBLE,
  EstuaryLatitude DOUBLE,
  EstuaryLongitude DOUBLE,
 CONSTRAINT estuaryCoord CHECK (
    (EstuaryLatitude >= -90) AND 
    (EstuaryLatitude <= 90) AND
    (EstuaryLongitude > -180) AND
    (EstuaryLongitude <= 180)
  ),
 EstuaryElevation DOUBLE,
 CONSTRAINT RivFlowsInto 
     CHECK ((River IS NULL AND Lake IS NULL)
            OR (River IS NULL AND Sea IS NULL)
            OR (Lake IS NULL AND Sea is NULL)));

CREATE TABLE riverthrough
(River VARCHAR(50),
 Lake  VARCHAR(50),
 PRIMARY KEY (River,Lake) );

CREATE TABLE geo_mountain
(Mountain VARCHAR(50) ,
 Country VARCHAR(4) ,
 Province VARCHAR(50) ,
 PRIMARY KEY (Province,Country,Mountain) );

CREATE TABLE geo_desert
(Desert VARCHAR(50) ,
 Country VARCHAR(4) ,
 Province VARCHAR(50) ,
 PRIMARY KEY (Province, Country, Desert) );

CREATE TABLE geo_island
(Island VARCHAR(50) , 
 Country VARCHAR(4) ,
 Province VARCHAR(50) ,
 PRIMARY KEY (Province, Country, Island) );

CREATE TABLE geo_river
(River VARCHAR(50) , 
 Country VARCHAR(4) ,
 Province VARCHAR(50) ,
 PRIMARY KEY (Province ,Country, River) );

CREATE TABLE geo_sea
(Sea VARCHAR(50) ,
 Country VARCHAR(4)  ,
 Province VARCHAR(50) ,
 PRIMARY KEY (Province, Country, Sea) );

CREATE TABLE geo_lake
(Lake VARCHAR(50) ,
 Country VARCHAR(4) ,
 Province VARCHAR(50) ,
 PRIMARY KEY (Province, Country, Lake) );

CREATE TABLE geo_source
(River VARCHAR(50) ,
 Country VARCHAR(4) ,
 Province VARCHAR(50) ,
 PRIMARY KEY (Province, Country, River) );

CREATE TABLE geo_estuary
(River VARCHAR(50) ,
 Country VARCHAR(4) ,
 Province VARCHAR(50) ,
 PRIMARY KEY (Province, Country, River) );

CREATE TABLE mergeswith
(Sea1 VARCHAR(50) ,
 Sea2 VARCHAR(50) ,
 PRIMARY KEY (Sea1, Sea2) );

CREATE TABLE located
(City VARCHAR(50) ,
 Province VARCHAR(50) ,
 Country VARCHAR(4) ,
 River VARCHAR(50),
 Lake VARCHAR(50),
 Sea VARCHAR(50) );

CREATE TABLE locatedon
(City VARCHAR(50) ,
 Province VARCHAR(50) ,
 Country VARCHAR(4) ,
 Island VARCHAR(50) ,
 PRIMARY KEY (City, Province, Country, Island) );

CREATE TABLE islandin
(Island VARCHAR(50) ,
 Sea VARCHAR(50) ,
 Lake VARCHAR(50) ,
 River VARCHAR(50) );

CREATE TABLE mountainonisland
(Mountain VARCHAR(50),
 Island   VARCHAR(50),
 PRIMARY KEY (Mountain, Island) );

CREATE TABLE lakeonisland
(Lake    VARCHAR(50),
 Island  VARCHAR(50),
 PRIMARY KEY (Lake, Island) );

CREATE TABLE riveronisland
(River   VARCHAR(50),
 Island  VARCHAR(50),
 PRIMARY KEY (River, Island) );

CREATE TABLE airport
(IATACode VARCHAR(3) PRIMARY KEY,
 Name VARCHAR(100) ,
 Country VARCHAR(4) ,
 City VARCHAR(50) ,
 Province VARCHAR(50) ,
 Island VARCHAR(50) ,
 Latitude DOUBLE CONSTRAINT AirpLat
   CHECK ((Latitude >= -90) AND (Latitude <= 90)) ,
 Longitude DOUBLE CONSTRAINT AirpLon
   CHECK ((Longitude >= -180) AND (Longitude <= 180)) ,
 Elevation DOUBLE ,
 gmtOffset DOUBLE );
 