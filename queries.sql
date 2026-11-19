create database propfind;
use propfind;

show tables;

-- 1. Fix UTF-8 BOM column names and set VARCHAR for Primary Keys
ALTER TABLE properties 
  CHANGE COLUMN `ï»¿Property_ID` Property_ID VARCHAR(50) NOT NULL,
  MODIFY COLUMN Developer_ID VARCHAR(50),
  MODIFY COLUMN State_ID VARCHAR(50),
  MODIFY COLUMN City_ID VARCHAR(50),
  MODIFY COLUMN Property_Type VARCHAR(100);

ALTER TABLE property_transactions 
  CHANGE COLUMN `ï»¿Transaction_ID` Transaction_ID VARCHAR(50) NOT NULL,
  MODIFY COLUMN Property_ID VARCHAR(50);

ALTER TABLE shopping_malls 
  CHANGE COLUMN `ï»¿Mall_ID` Mall_ID VARCHAR(50) NOT NULL,
  MODIFY COLUMN State_Name VARCHAR(100);

-- 2. Set VARCHAR on the remaining tables
ALTER TABLE amenities_master 
  MODIFY COLUMN Amenity_ID VARCHAR(50) NOT NULL;

ALTER TABLE developers 
  MODIFY COLUMN Developer_ID VARCHAR(50) NOT NULL;

ALTER TABLE states 
  MODIFY COLUMN State_ID VARCHAR(50) NOT NULL,
  MODIFY COLUMN State_Name VARCHAR(100) NOT NULL;

ALTER TABLE cities 
  MODIFY COLUMN City_ID VARCHAR(50) NOT NULL,
  MODIFY COLUMN State_Name VARCHAR(100);

ALTER TABLE schools 
  MODIFY COLUMN School_ID VARCHAR(50) NOT NULL,
  MODIFY COLUMN City_ID VARCHAR(50);

ALTER TABLE propertytypes 
  MODIFY COLUMN Property_Type_ID VARCHAR(50) NOT NULL,
  MODIFY COLUMN Property_Type VARCHAR(100) NOT NULL;
  
ALTER TABLE amenities_master      ADD PRIMARY KEY (Amenity_ID);
ALTER TABLE developers            ADD PRIMARY KEY (Developer_ID);
ALTER TABLE states                ADD PRIMARY KEY (State_ID), ADD UNIQUE (State_Name);
ALTER TABLE cities                ADD PRIMARY KEY (City_ID);
ALTER TABLE properties            ADD PRIMARY KEY (Property_ID);
ALTER TABLE property_transactions ADD PRIMARY KEY (Transaction_ID);
ALTER TABLE schools               ADD PRIMARY KEY (School_ID);
ALTER TABLE shopping_malls        ADD PRIMARY KEY (Mall_ID);
ALTER TABLE propertytypes        ADD PRIMARY KEY (Property_Type_ID), ADD UNIQUE (Property_Type);

-- Link cities to states (via State_Name, since cities has no State_ID)
ALTER TABLE cities
  ADD CONSTRAINT fk_cities_state
  FOREIGN KEY (State_Name) REFERENCES states(State_Name);

-- Link shopping_malls to states (via State_Name)
ALTER TABLE shopping_malls
  ADD CONSTRAINT fk_malls_state
  FOREIGN KEY (State_Name) REFERENCES states(State_Name);

-- Link schools to cities
ALTER TABLE schools
  ADD CONSTRAINT fk_schools_city
  FOREIGN KEY (City_ID) REFERENCES cities(City_ID);

-- Link properties to developers, states, cities, and property_types
ALTER TABLE properties
  ADD CONSTRAINT fk_prop_developer FOREIGN KEY (Developer_ID) REFERENCES developers(Developer_ID),
  ADD CONSTRAINT fk_prop_state     FOREIGN KEY (State_ID)     REFERENCES states(State_ID),
  ADD CONSTRAINT fk_prop_city      FOREIGN KEY (City_ID)      REFERENCES cities(City_ID),
  ADD CONSTRAINT fk_prop_type      FOREIGN KEY (Property_Type) REFERENCES propertytypes(Property_Type);

-- Link property_transactions to properties
ALTER TABLE property_transactions
  ADD CONSTRAINT fk_trx_property
  FOREIGN KEY (Property_ID) REFERENCES properties(Property_ID);
  
-- HIghest Price per Sq. Ft by Locality vs. City Average
WITH locality_metrics AS (
    SELECT 
        p.City_ID,
        c.City_Name,
        p.Locality_ID,
        pt.Locality_Name,
        COUNT(DISTINCT p.Property_ID) AS total_properties,
        ROUND(AVG(p.price_per_sqft), 2) AS avg_price_per_sqft,
        c.Average_Property_Price_sqft AS city_benchmark_sqft
    FROM properties p
    JOIN cities c ON p.City_ID = c.City_ID
    LEFT JOIN property_transactions pt ON p.Property_ID = pt.Property_ID
    GROUP BY p.City_ID, c.City_Name, p.Locality_ID, pt.Locality_Name, c.Average_Property_Price_sqft
)
SELECT 
    City_Name,
    Locality_Name,
    total_properties,
    avg_price_per_sqft,
    city_benchmark_sqft,
    ROUND(((avg_price_per_sqft - city_benchmark_sqft) / NULLIF(city_benchmark_sqft, 0)) * 100, 2) AS pct_diff_from_city_avg,
    DENSE_RANK() OVER (ORDER BY avg_price_per_sqft DESC) AS overall_rank
FROM locality_metrics
WHERE total_properties >= 5
ORDER BY avg_price_per_sqft DESC
LIMIT 10;

-- Top Developers by sales volume and revenue
WITH dev_sales AS (
    SELECT 
        d.Developer_ID,
        d.Developer_Name,
        d.Developer_Type,
        COUNT(pt.Transaction_ID) AS total_deals_closed,
        SUM(pt.sale_Price) AS total_revenue,
        ROUND(AVG(pt.sale_price), 2) AS avg_deal_value
    FROM developers d
    JOIN properties p ON d.Developer_ID = p.Developer_ID
    JOIN property_transactions pt ON p.Property_ID = pt.Property_ID
    GROUP BY d.Developer_ID, d.Developer_Name, d.Developer_Type
)
SELECT 
    Developer_Name,
    Developer_Type,
    total_deals_closed,
    total_revenue,
    avg_deal_value,
    ROUND(
        (total_revenue * 100.0) / SUM(total_revenue) OVER (PARTITION BY Developer_Type), 
        2
    ) AS pct_revenue_share_in_type,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS overall_rank
FROM dev_sales
ORDER BY overall_rank
LIMIT 15;

-- Avg Holding days of each developer
WITH property_resales AS (
    SELECT 
        Property_ID,
        Developer_Name,
        Transaction_Date AS current_sale_date,
        LAG(Transaction_Date) OVER (
            PARTITION BY Property_ID 
            ORDER BY Transaction_Date
        ) AS prev_sale_date
    FROM property_transactions
)
SELECT 
    Developer_Name,
    COUNT(*) AS repeat_sales_count,
    ROUND(AVG(DATEDIFF(current_sale_date, prev_sale_date)), 1) AS avg_holding_days,
    MIN(DATEDIFF(current_sale_date, prev_sale_date)) AS shortest_holding_days,
    MAX(DATEDIFF(current_sale_date, prev_sale_date)) AS longest_holding_days
FROM property_resales
WHERE prev_sale_date IS NOT NULL
GROUP BY Developer_Name
HAVING COUNT(*) >= 3
ORDER BY avg_holding_days ASC
limit 10;

-- Impact on schools and malls
SELECT 
    c.City_Name,
    c.Tier,
    c.Average_Property_Price_sqft,
    COALESCE(s.school_count, 0) AS total_schools,
    COALESCE(m.mall_count, 0) AS total_malls,
    COALESCE(m.luxury_malls, 0) AS luxury_malls
FROM cities c
LEFT JOIN (
    SELECT City_ID, COUNT(*) AS school_count
    FROM schools
    GROUP BY City_ID
) s ON c.City_ID = s.City_ID
LEFT JOIN (
    SELECT 
        City_Name, 
        COUNT(*) AS mall_count,
        SUM(CASE WHEN Mall_Type = 'Luxury' THEN 1 ELSE 0 END) AS luxury_malls
    FROM shopping_malls
    GROUP BY City_Name
) m ON c.City_Name = m.City_Name
ORDER BY c.Average_Property_Price_sqft DESC
LIMIT 10;

-- Yearly Transaction Volume by State
SELECT 
    YEAR(Transaction_Date) AS sale_year,
    State_Name,
    COUNT(Transaction_ID) AS total_transactions,
    ROUND(AVG(sale_Price), 2) AS avg_transaction_value
FROM property_transactions
GROUP BY YEAR(Transaction_Date), State_Name
HAVING COUNT(Transaction_ID) >= 10
ORDER BY sale_year DESC, total_transactions DESC, avg_transaction_value desc;

-- Family-Friendly Cities: Schools by Board & Malls with Multiplexes
SELECT 
    c.City_Name,
    c.Tier,
    COUNT(DISTINCT s.School_ID) AS total_schools,
    COUNT(DISTINCT CASE WHEN s.Board IN ('CBSE', 'ICSE', 'IB') THEN s.School_ID END) AS national_intl_schools,
    COUNT(DISTINCT m.Mall_ID) AS total_malls,
    COUNT(DISTINCT CASE WHEN m.Multiplex = 'Yes' AND m.Food_Court = 'Yes' THEN m.Mall_ID END) AS malls_with_multiplex_and_foodcourt
FROM cities c
LEFT JOIN schools s ON c.City_ID = s.City_ID
LEFT JOIN shopping_malls m ON c.City_Name = m.City_Name
GROUP BY c.City_Name, c.Tier
HAVING total_schools > 0 AND total_malls > 0
ORDER BY total_malls DESC, total_schools DESC
LIMIT 15;
