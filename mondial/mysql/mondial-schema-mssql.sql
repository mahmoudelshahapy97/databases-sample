CREATE TABLE dbo.Country
(Name Nvarchar(50) NOT NULL UNIQUE,
 Code Nvarchar(4) CONSTRAINT CountryKey PRIMARY KEY,
 Capital Nvarchar(50),
 Province Nvarchar(50),
 Area Float CONSTRAINT CountryArea
   CHECK (Area >= 0),
 Population Float CONSTRAINT CountryPop
   CHECK (Population >= 0));

CREATE TABLE dbo.City
(Name Nvarchar(50),
 Country Nvarchar(4),
 Province Nvarchar(50),
 Population Float CONSTRAINT CityPop
   CHECK (Population >= 0),
 Latitude Float CONSTRAINT CityLat
   CHECK ((Latitude >= -90) AND (Latitude <= 90)) ,
 Longitude Float CONSTRAINT CityLon
   CHECK ((Longitude >= -180) AND (Longitude <= 180)) ,
 Elevation Float ,
 CONSTRAINT CityKey PRIMARY KEY (Name, Country, Province));

CREATE TABLE dbo.Province
(Name Nvarchar(50) CONSTRAINT PrName NOT NULL ,
 Country  Nvarchar(4) CONSTRAINT PrCountry NOT NULL ,
 Population Float CONSTRAINT PrPop
   CHECK (Population >= 0),
 Area Float CONSTRAINT PrAr
   CHECK (Area >= 0),
 Capital Nvarchar(50),
 CapProv Nvarchar(50),
 CONSTRAINT PrKey PRIMARY KEY (Name, Country));

CREATE TABLE dbo.Economy
(Country Nvarchar(4) CONSTRAINT EconomyKey PRIMARY KEY,
 GDP Float CONSTRAINT EconomyGDP
   CHECK (GDP >= 0),
 Agriculture Float,
 Service Float,
 Industry Float,
 Inflation Float,
 Unemployment Float);

CREATE TABLE dbo.Population
(Country Nvarchar(4) CONSTRAINT PopKey PRIMARY KEY,
 Population_Growth Float,
 Infant_Mortality Float);

CREATE TABLE dbo.Politics
(Country Nvarchar(4) CONSTRAINT PoliticsKey PRIMARY KEY,
 Independence DATE,
 WasDependent Nvarchar(50),
 Dependent  Nvarchar(4),
 Government Nvarchar(120));

CREATE TABLE dbo.Religion
(Country Nvarchar(4),
 Name Nvarchar(50),
 Percentage Float CONSTRAINT ReligionPercent 
   CHECK ((Percentage > 0) AND (Percentage <= 100)),
 CONSTRAINT ReligionKey PRIMARY KEY (Name, Country));

CREATE TABLE dbo.EthnicGroup
(Country Nvarchar(4),
 Name Nvarchar(50),
 Percentage Float CONSTRAINT EthnicPercent 
   CHECK ((Percentage > 0) AND (Percentage <= 100)),
 CONSTRAINT EthnicKey PRIMARY KEY (Name, Country));

CREATE TABLE dbo.Spoken
(Country Nvarchar(4),
 Language Nvarchar(50),
 Percentage Float CONSTRAINT SpokenPercent 
   CHECK ((Percentage > 0) AND (Percentage <= 100)),
 CONSTRAINT SpokenKey PRIMARY KEY (Country, Language));

CREATE TABLE dbo.Language
(Name Nvarchar(50) ,
 Superlanguage Nvarchar(50),
 CONSTRAINT LanguageKey PRIMARY KEY (Name));

CREATE TABLE dbo.Countrypops
(Country Nvarchar(4),
 Year Float CONSTRAINT CountryPopsYear
   CHECK (Year >= 0),
 Population Float CONSTRAINT CountryPopsPop
   CHECK (Population >= 0),
 CONSTRAINT CountryPopsKey PRIMARY KEY (Country, Year));

CREATE TABLE dbo.Countryothername
(Country Nvarchar(4),
 othername Nvarchar(50),
 CONSTRAINT CountryOthernameKey PRIMARY KEY (Country, othername));

CREATE TABLE dbo.Countrylocalname
(Country Nvarchar(4),
 localname Nvarchar(300),
 CONSTRAINT CountrylocalnameKey PRIMARY KEY (Country));

CREATE TABLE dbo.Provpops
(Province Nvarchar(50),
 Country Nvarchar(4),
 Year Float CONSTRAINT ProvPopsYear
   CHECK (Year >= 0),
 Population Float CONSTRAINT ProvPopsPop
   CHECK (Population >= 0),
 CONSTRAINT ProvPopKey PRIMARY KEY (Country, Province, Year));

CREATE TABLE dbo.Provinceothername
(Province Nvarchar(50),
 Country Nvarchar(4),
 othername Nvarchar(50),
 CONSTRAINT ProvOthernameKey PRIMARY KEY (Country, Province, othername));

CREATE TABLE dbo.Provincelocalname
(Province Nvarchar(50),
 Country Nvarchar(4),
 localname Nvarchar(300),
 CONSTRAINT ProvlocalnameKey PRIMARY KEY (Country, Province));

CREATE TABLE dbo.Citypops
(City Nvarchar(50),
 Country Nvarchar(4),
 Province Nvarchar(50),
 Year Float CONSTRAINT CityPopsYear
   CHECK (Year >= 0),
 Population Float CONSTRAINT CityPopsPop
   CHECK (Population >= 0),
 CONSTRAINT CityPopKey PRIMARY KEY (Country, Province, City, Year));

CREATE TABLE dbo.Cityothername
(City Nvarchar(50),
 Country Nvarchar(4),
 Province Nvarchar(50),
 othername Nvarchar(50),
 CONSTRAINT CityOthernameKey PRIMARY KEY (Country, Province, City, othername));

CREATE TABLE dbo.Citylocalname
(City Nvarchar(50),
 Country Nvarchar(4),
 Province Nvarchar(50),
 localname Nvarchar(300),
 CONSTRAINT CitylocalnameKey PRIMARY KEY (Country, Province, City));

CREATE TABLE dbo.Continent
(Name Nvarchar(20) CONSTRAINT ContinentKey PRIMARY KEY,
 Area Float(10));

CREATE TABLE dbo.borders
(Country1 Nvarchar(4),
 Country2 Nvarchar(4),
 Length Float 
   CHECK (Length > 0),
 CONSTRAINT BorderKey PRIMARY KEY (Country1,Country2) );

CREATE TABLE dbo.encompasses
(Country Nvarchar(4) NOT NULL,
 Continent Nvarchar(20) NOT NULL,
 Percentage Float,
   CHECK ((Percentage > 0) AND (Percentage <= 100)),
 CONSTRAINT EncompassesKey PRIMARY KEY (Country,Continent));

CREATE TABLE dbo.Organization
(Abbreviation Nvarchar(12) Constraint OrgKey PRIMARY KEY,
 Name Nvarchar(100) NOT NULL,
 City Nvarchar(50) ,
 Country Nvarchar(4) , 
 Province Nvarchar(50) ,
 Established DATE,
 CONSTRAINT OrgNameUnique UNIQUE (Name));

CREATE TABLE dbo.isMember
(Country Nvarchar(4),
 Organization Nvarchar(12),
 Type Nvarchar(60) DEFAULT 'member',
 CONSTRAINT MemberKey PRIMARY KEY (Country,Organization) );




CREATE TABLE dbo.Mountain
(
  Name NVARCHAR(50) CONSTRAINT MountainKey PRIMARY KEY,
  Mountains NVARCHAR(50),
  Elevation FLOAT,
  [Type] NVARCHAR(10),
  Latitude FLOAT,
  Longitude FLOAT,
  CONSTRAINT MountainCoord CHECK (
    (Latitude >= -90) AND 
    (Latitude <= 90) AND
    (Longitude > -180) AND
    (Longitude <= 180)
  )
);
	
CREATE TABLE dbo.Desert
(Name Nvarchar(50) CONSTRAINT DesertKey PRIMARY KEY,
 Area Float,
  Latitude FLOAT,
  Longitude FLOAT,
 CONSTRAINT DesertCoord CHECK (
    (Latitude >= -90) AND 
    (Latitude <= 90) AND
    (Longitude > -180) AND
    (Longitude <= 180)
  ));

CREATE TABLE dbo.Island
(Name Nvarchar(50) CONSTRAINT IslandKey PRIMARY KEY,
 Islands Nvarchar(50),
 Area Float CONSTRAINT IslandAr check (Area >= 0),
 Elevation Float,
 Type Nvarchar(15),
  Latitude FLOAT,
  Longitude FLOAT,
 CONSTRAINT IslandCoord CHECK (
    (Latitude >= -90) AND 
    (Latitude <= 90) AND
    (Longitude > -180) AND
    (Longitude <= 180)
  ));

CREATE TABLE dbo.Lake
(Name Nvarchar(50) CONSTRAINT LakeKey PRIMARY KEY,
 River Nvarchar(50),
 Area Float CONSTRAINT LakeAr CHECK (Area >= 0),
 Elevation Float,
 Depth Float CONSTRAINT LakeDpth CHECK (Depth >= 0),
 Height Float CONSTRAINT DamHeight CHECK (Height > 0),
 Type Nvarchar(12),
  Latitude FLOAT,
  Longitude FLOAT,
 CONSTRAINT LakeCoord CHECK (
    (Latitude >= -90) AND 
    (Latitude <= 90) AND
    (Longitude > -180) AND
    (Longitude <= 180)
  ));

CREATE TABLE dbo.Sea
(Name Nvarchar(50) CONSTRAINT SeaKey PRIMARY KEY,
 Area Float CONSTRAINT SeaAr CHECK (Area >= 0),
 Depth Float CONSTRAINT SeaDepth CHECK (Depth >= 0));

CREATE TABLE dbo.River
(Name Nvarchar(50) CONSTRAINT RiverKey PRIMARY KEY,
 River Nvarchar(50),
 Lake Nvarchar(50),
 Sea Nvarchar(50),
 Length Float CONSTRAINT RiverLength
   CHECK (Length >= 0),
 Area Float CONSTRAINT RiverArea
   CHECK (Area >= 0),
  sourceLatitude FLOAT,
  sourceLongitude FLOAT,
 CONSTRAINT sourceCoord CHECK (
    (sourceLatitude >= -90) AND 
    (sourceLatitude <= 90) AND
    (sourceLongitude > -180) AND
    (sourceLongitude <= 180)
  ),
 Mountains Nvarchar(50),
 SourceElevation Float,
  EstuaryLatitude FLOAT,
  EstuaryLongitude FLOAT,
 CONSTRAINT estuaryCoord CHECK (
    (EstuaryLatitude >= -90) AND 
    (EstuaryLatitude <= 90) AND
    (EstuaryLongitude > -180) AND
    (EstuaryLongitude <= 180)
  ),
 EstuaryElevation Float,
 CONSTRAINT RivFlowsInto 
     CHECK ((River IS NULL AND Lake IS NULL)
            OR (River IS NULL AND Sea IS NULL)
            OR (Lake IS NULL AND Sea is NULL)));

CREATE TABLE dbo.RiverThrough
(River Nvarchar(50),
 Lake  Nvarchar(50),
 CONSTRAINT RThroughKey PRIMARY KEY (River,Lake) );

CREATE TABLE dbo.geo_Mountain
(Mountain Nvarchar(50) ,
 Country Nvarchar(4) ,
 Province Nvarchar(50) ,
 CONSTRAINT GMountainKey PRIMARY KEY (Province,Country,Mountain) );

CREATE TABLE dbo.geo_Desert
(Desert Nvarchar(50) ,
 Country Nvarchar(4) ,
 Province Nvarchar(50) ,
 CONSTRAINT GDesertKey PRIMARY KEY (Province, Country, Desert) );

CREATE TABLE dbo.geo_Island
(Island Nvarchar(50) , 
 Country Nvarchar(4) ,
 Province Nvarchar(50) ,
 CONSTRAINT GIslandKey PRIMARY KEY (Province, Country, Island) );

CREATE TABLE dbo.geo_River
(River Nvarchar(50) , 
 Country Nvarchar(4) ,
 Province Nvarchar(50) ,
 CONSTRAINT GRiverKey PRIMARY KEY (Province ,Country, River) );

CREATE TABLE dbo.geo_Sea
(Sea Nvarchar(50) ,
 Country Nvarchar(4)  ,
 Province Nvarchar(50) ,
 CONSTRAINT GSeaKey PRIMARY KEY (Province, Country, Sea) );

CREATE TABLE dbo.geo_Lake
(Lake Nvarchar(50) ,
 Country Nvarchar(4) ,
 Province Nvarchar(50) ,
 CONSTRAINT GLakeKey PRIMARY KEY (Province, Country, Lake) );

CREATE TABLE dbo.geo_Source
(River Nvarchar(50) ,
 Country Nvarchar(4) ,
 Province Nvarchar(50) ,
 CONSTRAINT GSourceKey PRIMARY KEY (Province, Country, River) );

CREATE TABLE dbo.geo_Estuary
(River Nvarchar(50) ,
 Country Nvarchar(4) ,
 Province Nvarchar(50) ,
 CONSTRAINT GEstuaryKey PRIMARY KEY (Province, Country, River) );

CREATE TABLE dbo.mergesWith
(Sea1 Nvarchar(50) ,
 Sea2 Nvarchar(50) ,
 CONSTRAINT MergesWithKey PRIMARY KEY (Sea1, Sea2) );

CREATE TABLE dbo.located
(City Nvarchar(50) ,
 Province Nvarchar(50) ,
 Country Nvarchar(4) ,
 River Nvarchar(50),
 Lake Nvarchar(50),
 Sea Nvarchar(50) );

CREATE TABLE dbo.locatedOn
(City Nvarchar(50) ,
 Province Nvarchar(50) ,
 Country Nvarchar(4) ,
 Island Nvarchar(50) ,
 CONSTRAINT locatedOnKey PRIMARY KEY (City, Province, Country, Island) );

CREATE TABLE dbo.islandIn
(Island Nvarchar(50) ,
 Sea Nvarchar(50) ,
 Lake Nvarchar(50) ,
 River Nvarchar(50) );

CREATE TABLE dbo.MountainOnIsland
(Mountain Nvarchar(50),
 Island   Nvarchar(50),
 CONSTRAINT MountainIslKey PRIMARY KEY (Mountain, Island) );

CREATE TABLE dbo.LakeOnIsland
(Lake    Nvarchar(50),
 Island  Nvarchar(50),
 CONSTRAINT LakeIslKey PRIMARY KEY (Lake, Island) );

CREATE TABLE dbo.RiverOnIsland
(River   Nvarchar(50),
 Island  Nvarchar(50),
 CONSTRAINT RiverIslKey PRIMARY KEY (River, Island) );

CREATE TABLE dbo.Airport
(IATACode VARCHAR(3) PRIMARY KEY,
 Name Nvarchar(100) ,
 Country Nvarchar(4) ,
 City Nvarchar(50) ,
 Province Nvarchar(50) ,
 Island Nvarchar(50) ,
 Latitude Float CONSTRAINT AirpLat
   CHECK ((Latitude >= -90) AND (Latitude <= 90)) ,
 Longitude Float CONSTRAINT AirpLon
   CHECK ((Longitude >= -180) AND (Longitude <= 180)) ,
 Elevation Float ,
 gmtOffset Float );
 