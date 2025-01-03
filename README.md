# README: COVID-19 Data Analysis Project

## Project Overview
This project analyzes COVID-19 data to extract meaningful insights related to infection rates, death rates, and vaccination trends across different locations and continents. The data is sourced from two datasets:

1. **Covid Deaths CSV File** - Contains information on cases, deaths, and population.
2. **Covid Vaccinations CSV File** - Contains details on vaccination numbers.

SQL is used extensively to query, join, and manipulate data to produce insights such as:
- Infection and death rates
- Population percentages affected
- Rolling vaccination counts

## Prerequisites
Ensure you have:
- A SQL Server environment to execute the queries.
- The COVID-19 datasets imported into the database with appropriate permissions to query them.

## Datasets Used
The following datasets are referenced:
- **[Portfolio project]..['Covid deaths CSV file$']**
- **[Portfolio project]..['Covid Vaccinations CSV file$']**

## Key Features and Queries
### 1. **Data Exploration**
Basic queries to inspect the datasets and verify the structure:
```sql
-- Inspecting Covid Deaths Dataset
SELECT *
FROM [Portfolio project]..['Covid deaths CSV file$']
ORDER BY 3, 4;

-- Inspecting Covid Vaccinations Dataset
SELECT *
FROM [Portfolio project]..['Covid Vaccinations CSV file$']
ORDER BY 3, 4;
```

### 2. **Total Cases vs Total Deaths**
Calculates the death rate for a specific location (e.g., Canada):
```sql
SELECT location, date, total_cases, total_deaths,
CASE
    WHEN total_cases = 0 THEN NULL
    ELSE ROUND((total_deaths / total_cases) * 100, 2)
END AS death_rate
FROM [Portfolio project]..['Covid deaths CSV file$']
WHERE location LIKE 'canada'
ORDER BY 1, 2;
```

### 3. **Infection Rate Analysis**
Shows the percentage of the population affected by COVID-19:
```sql
SELECT location, date, population, total_cases,
ROUND((total_cases / population) * 100, 2) AS infection_percentage
FROM [Portfolio project]..['Covid deaths CSV file$']
WHERE location LIKE 'canada'
ORDER BY 1, 2;
```

### 4. **Highest Infection Rates**
Identifies countries with the highest percentage of population infected:
```sql
SELECT location, population, MAX(total_cases) AS HighestInfectionCount,
ROUND(MAX((total_cases / population)) * 100, 2) AS PercentPopulationInfected
FROM [Portfolio project]..['Covid deaths CSV file$']
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;
```

### 5. **Vaccination Analysis**
#### Rolling Count of Vaccinations:
Calculates a running total of vaccinations for each location:
```sql
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingCountofVaccinations
FROM [Portfolio project]..['Covid deaths CSV file$'] AS Dea
JOIN [Portfolio project]..['Covid Vaccinations CSV file$'] AS Vac
    ON Dea.location = Vac.location AND Dea.date = Vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;
```

### 6. **Temporary Tables**
Stores vaccination data in a temporary table for further analysis:
```sql
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingCountofVaccination NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingCountofVaccination
FROM [Portfolio project]..['Covid deaths CSV file$'] AS Dea
JOIN [Portfolio project]..['Covid Vaccinations CSV file$'] AS Vac
    ON Dea.location = Vac.location AND Dea.date = Vac.date;

SELECT *,
CASE
    WHEN Population = 0 OR Population IS NULL THEN NULL
    ELSE (RollingCountofVaccination / Population) * 100
END AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;
```

### 7. **Views**
Creates a view to simplify vaccination analysis:
```sql
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingCountofVaccinations
FROM [Portfolio project]..['Covid deaths CSV file$'] AS Dea
JOIN [Portfolio project]..['Covid Vaccinations CSV file$'] AS Vac
    ON Dea.location = Vac.location AND Dea.date = Vac.date
WHERE dea.continent IS NOT NULL;
```

## Insights
1. **Death Rate Trends:**
   - Allows tracking of death rate trends across countries and continents.

2. **Infection Rates:**
   - Highlights regions with high infection percentages relative to their population.

3. **Vaccination Progress:**
   - Tracks vaccination progress using rolling counts and identifies countries with the highest vaccination percentages.

## Conclusion
This project provides a robust framework for analyzing COVID-19 data, offering insights into how the pandemic impacted different regions globally. It can be expanded further by incorporating more data sources or enhancing visualization with tools like Power BI or Tableau.

