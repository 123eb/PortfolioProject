SELECT *
FROM master.DBO.CovidDeaths
ORDER BY 1,2

-- DATA TO BE USED
SELECT  Location, date, total_cases, new_cases, total_deaths, population
FROM MASTER..CovidDeaths
ORDER BY 1, 2

-- TOTAL CASES VS TOTAL DEATHS
SELECT  Location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 AS DeathPercentage
FROM MASTER..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1, 2

-- TOTAL CASES VS POPULATION
SELECT  Location, date, total_cases, Population, (CAST(total_cases AS FLOAT)/CAST(population AS FLOAT))*100 AS InfectionPercentage
FROM MASTER..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1, 2

-- COUNTRIES WITH THE HIGHEST INFECTION RATE COMPARED TO POPULATION
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((CAST(total_cases AS INT)/CAST(population AS INT)))*100 AS InfectionPercentage
FROM MASTER..CovidDeaths
GROUP BY population, location
ORDER BY InfectionPercentage DESC

SELECT iso_code, continent, location, population, MAX(total_cases) AS HighestInfectionCount
FROM MASTER..CovidDeaths
WHERE location = 'cyprus'
GROUP BY location, population, iso_code, continent
ORDER BY HighestInfectionCount


-- COUNTRIES WITH THE HIGHEST DEATH COUNT PER POPULATION 
SELECT Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathsCount
FROM MASTER..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY population, location
ORDER BY TotalDeathsCount DESC

-- BY CONTINENT
SELECT continent, MAX(CAST(total_Deaths AS INT)) AS TotalDeathCount
FROM MASTER..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount

-- WORLD DATA
SELECT SUM(CAST(new_cases AS INT)) AS NewCaseSUM, SUM(CAST(new_deaths AS INT)) AS NewDeathSum, (SUM(new_deaths) / SUM(new_cases)) * 100 AS DeathPercentage
FROM MASTER..CovidDeaths
WHERE continent IS NOT NULL AND new_cases <> 0 AND new_deaths IS NOT NULL
--GROUP BY date
ORDER BY 1,2


-- STARTING WITH COVID VACCINATIONS
SELECT *
FROM MASTER..CovidDeaths dea
INNER JOIN MASTER..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.location = 'Grenada'
	ORDER BY dea.location DESC

-- LOOKING AT THE TOTAL POPULATION VS VACCINATION
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
SUM(CONVERT(INT, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM MASTER..CovidDeaths dea
INNER JOIN MASTER..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	--WHERE dea.location = 'Grenada'
	WHERE dea.continent  IS NOT NULL
	ORDER BY 2,3


-- USE CTE
WITH Pop_vs_Vac (continent, Location, Date, population, New_Vaccinations, RollingPeopleVaccinated)
AS(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM MASTER..CovidDeaths dea
INNER JOIN MASTER..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND new_vaccinations IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/population) * 100
FROM Pop_vs_Vac

-- USING A TEMP TABLE

CREATE TABLE #Temp_Table
(
Continent NVARCHAR(255),
Location NVARCHAR (255),
Date  DATETIME,
Population NUMERIC,
New_Vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

INSERT INTO #Temp_Table
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM MASTER..CovidDeaths dea
INNER JOIN MASTER..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL AND new_vaccinations IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 
FROM #Temp_Table

-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION
CREATE VIEW PercentPopulationVaccinated AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM MASTER..CovidDeaths dea
INNER JOIN MASTER..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND new_vaccinations IS NOT NULL
)

SELECT *
FROM PercentPopulationVaccinated