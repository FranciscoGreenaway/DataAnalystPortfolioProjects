
SELECT * FROM PortfolioProject.dbo.['CovidDeaths']
ORDER BY 6


-- SELECT Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..['CovidDeaths']
WHERE continent IS NOT null
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathRate
FROM PortfolioProject..['CovidDeaths']
WHERE continent IS NOT null
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths in Haiti
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathRate
FROM PortfolioProject..['CovidDeaths']
WHERE location LIKE '%haiti%'
ORDER BY location, date 

-- Looking at Total Cases vs Population
-- Shows the percentage of the total population of a country contacted covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS ContractionRate
FROM PortfolioProject..['CovidDeaths']
WHERE continent IS NOT null
--WHERE location like '%state%'
ORDER BY date


-- Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS LargestInfectionCount, MAX((total_cases/population)) *100 AS ContractionRate
FROM PortfolioProject..['CovidDeaths']
WHERE continent IS NOT null
GROUP BY location, population
ORDER BY ContractionRate DESC

-- Showing Countries with Highest Death Count per Population
SELECT location, population, MAX(total_cases) AS LargestInfectionCount, MAX((total_cases/population)) *100 AS ContractionRate
FROM PortfolioProject..['CovidDeaths']
WHERE continent IS NOT null
GROUP BY location, population
ORDER BY ContractionRate DESC

-----------------------------------------------------------------------------------------------
-- Showing Countries with Highest Death Count per Population
SELECT location, Max(cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..['CovidDeaths']
WHERE continent IS NOT null
GROUP BY location
ORDER BY TotalDeathCount DESC
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Breaking numbers down by highest death count in a continent (Correct Way)
SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject.dbo.['CovidDeaths']
WHERE continent IS null
GROUP BY location
ORDER BY TotalDeathCount DESC
-----------------------------------------------------------------------------------------------


-- Show the total cases ANDtotal deaths of a location each day
SELECT date, location, MAX(total_cases) AS TotalCases, MAX(total_deaths) AS TotalDeaths
FROM PortfolioProject.dbo.['CovidDeaths']
WHERE continent IS NOT null
GROUP BY date, location
ORDER BY location, date

-----------------------------------------------------------------------------------------------
----------------------- GLOBAL NUMBERS	--------------------------
-- Show new daily cases, new global deaths, and death percentage
SELECT date, SUM(new_cases) AS NewGlobalCases, SUM(cast(new_deaths AS int)) AS NewGlobalDeaths,
	(SUM(cast(new_deaths AS int))/SUM(new_cases)) *100 AS DeathPercentage
FROM PortfolioProject.dbo.['CovidDeaths']
WHERE continent IS NOT null
GROUP BY date
ORDER BY date

-- Show overall total of deaths cases and death percentage around the globe
SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS int)) AS TotalDeaths,
	(SUM(cast(new_deaths AS int))/SUM(new_cases)) *100 AS DeathPercentage
FROM PortfolioProject.dbo.['CovidDeaths']
WHERE continent IS NOT null
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Find total vaccinated percent by location (Continents)
SELECT death.location, SUM(death.population) AS TotalPopulation, SUM(cast(vacc.new_vaccinations AS bigint)) AS TotalVaccs,
	SUM(cast(vacc.new_vaccinations AS bigint))/(SUM(death.population))*100 AS TotalVaccinatedPercent
FROM PortfolioProject.dbo.['CovidDeaths'] death
JOIN PortfolioProject.dbo.['CovidVaccinations'] vacc
	ON death.iso_code = vacc.iso_code
	WHERE death.continent IS null
	GROUP BY death.location, death.population
	ORDER BY death.population desc
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Looking at total Population vs Vaccinations
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations
,SUM(cast(vacc.new_vaccinations AS int)) OVER (Partition by death.location ORDER BY death.location,
 death.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.['CovidDeaths'] death
JOIN PortfolioProject.dbo.['CovidVaccinations'] vacc
	ON death.location = vacc.location
	ANDdeath.date = vacc.date
WHERE death.continent IS NOT null
ORDER BY 2,3


-- Creating a CTE 

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
As
(
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations
,SUM(cast(vacc.new_vaccinations AS int)) OVER (Partition by death.location ORDER BY death.location,
 death.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.['CovidDeaths'] death
JOIN PortfolioProject.dbo.['CovidVaccinations'] vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentOfPopulationVaccinated
FROM PopvsVac


----------------------------------------------------------------------------------------------------
-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations
,SUM(cast(vacc.new_vaccinations AS int)) OVER (Partition by death.location ORDER BY death.location,
 death.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.['CovidDeaths'] death
JOIN PortfolioProject.dbo.['CovidVaccinations'] vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentOfPopulationVaccinated
FROM #PercentPopulationVaccinated
----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------
-- Creating view to store data for later visualizations
Create view PercentPopulationVaccinated as
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations
,SUM(cast(vacc.new_vaccinations AS int)) OVER (Partition by death.location ORDER BY death.location,
 death.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.['CovidDeaths'] death
JOIN PortfolioProject.dbo.['CovidVaccinations'] vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT null
--ORDER BY 2,3

SELECT * FROM PercentPopulationVaccinated
----------------------------------------------------------------------------------------------------
