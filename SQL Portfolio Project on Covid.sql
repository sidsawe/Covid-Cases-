-- Fetching all data from tables
-- SELECT *
-- FROM [Portfolio project]..['Covid deaths CSV file$']
-- ORDER BY 3, 4;

-- SELECT *
-- FROM [Portfolio project]..['Covid Vaccinations CSV file$']
-- ORDER BY 3, 4;

-- Basic details for each location
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio project]..['Covid deaths CSV file$']
ORDER BY 1, 2;

-- Total Cases vs Total Deaths: Likelihood of dying if infected
SELECT location, date, total_cases, total_deaths,
    CASE
        WHEN total_cases = 0 THEN NULL
        ELSE ROUND((total_deaths / total_cases) * 100, 2)
    END AS death_rate
FROM [Portfolio project]..['Covid deaths CSV file$']
WHERE location LIKE 'canada'
ORDER BY 1, 2;

-- Total Cases vs Population: Percentage of population infected
SELECT location, date, population, total_cases,
    ROUND((total_cases / population) * 100, 2) AS infection_percentage
FROM [Portfolio project]..['Covid deaths CSV file$']
WHERE location LIKE 'canada'
ORDER BY 1, 2;

-- Countries with the highest infection rate
SELECT location, population, MAX(total_cases) AS HighestInfectionCount,
    ROUND(MAX(total_cases / population) * 100, 2) AS PercentPopulationInfected
FROM [Portfolio project]..['Covid deaths CSV file$']
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Countries with the highest death count per population
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM [Portfolio project]..['Covid deaths CSV file$']
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM [Portfolio project]..['Covid deaths CSV file$']
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global statistics
SELECT date, SUM(new_cases) AS TotalNewCases, SUM(CAST(new_deaths AS INT)) AS TotalNewDeaths,
    CASE 
        WHEN SUM(new_cases) = 0 THEN NULL
        ELSE SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 
    END AS death_percentage
FROM [Portfolio project]..['Covid deaths CSV file$']
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1;

-- Total deaths worldwide
SELECT SUM(new_cases) AS TotalNewCases, SUM(CAST(new_deaths AS INT)) AS TotalNewDeaths,
    CASE 
        WHEN SUM(new_cases) = 0 THEN NULL
        ELSE SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 
    END AS death_percentage
FROM [Portfolio project]..['Covid deaths CSV file$']
WHERE continent IS NOT NULL;

-- Total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM [Portfolio project]..['Covid deaths CSV file$'] AS Dea
JOIN [Portfolio project]..['Covid Vaccinations CSV file$'] AS Vac
    ON Dea.location = Vac.location
    AND Dea.date = Vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2, 3;

-- Rolling count of vaccinations per location
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingCountofVaccinations
FROM [Portfolio project]..['Covid deaths CSV file$'] AS Dea
JOIN [Portfolio project]..['Covid Vaccinations CSV file$'] AS Vac
    ON Dea.location = Vac.location
    AND Dea.date = Vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2, 3;

-- Using CTE for population vs vaccination
WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingCountofVaccinations) AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingCountofVaccinations
    FROM [Portfolio project]..['Covid deaths CSV file$'] AS Dea
    JOIN [Portfolio project]..['Covid Vaccinations CSV file$'] AS Vac
        ON Dea.location = Vac.location
        AND Dea.date = Vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingCountofVaccinations / Population) * 100 AS PercentPopulationVaccinated
FROM PopvsVac;

-- Using temporary table for vaccination statistics
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
    ON Dea.location = Vac.location
    AND Dea.date = Vac.date;

SELECT *,
    CASE 
        WHEN Population = 0 OR Population IS NULL THEN NULL 
        ELSE (RollingCountofVaccination / Population) * 100 
    END AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- Creating a view for vaccination statistics
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingCountofVaccinations
FROM [Portfolio project]..['Covid deaths CSV file$'] AS Dea
JOIN [Portfolio project]..['Covid Vaccinations CSV file$'] AS Vac
    ON Dea.location = Vac.location
    AND Dea.date = Vac.date
WHERE dea.continent IS NOT NULL;
