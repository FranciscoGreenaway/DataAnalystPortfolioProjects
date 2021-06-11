
SELECT * FROM PortfolioProject.dbo.['CovidDeaths']
ORDER BY 6

--SELECT * FROM PortfolioProject..['CovidVaccinations']
--ORDER BY 3,4


-- Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..['CovidDeaths']
where continent is not null
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
From PortfolioProject..['CovidDeaths']
where continent is not null
order by 1,2

-- Looking at Total Cases vs Total Deaths in Haiti
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
From PortfolioProject..['CovidDeaths']
where location like '%haiti%'
order by location, date 

-- Looking at Total Cases vs Population
-- Shows the percentage of the total population of a country contacted covid
SELECT location, date, population, total_cases, (total_cases/population)*100 as ContractionRate
From PortfolioProject..['CovidDeaths']
where continent is not null
--where location like '%state%'
order by date


-- Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) as LargestInfectionCount, Max((total_cases/population)) *100 as ContractionRate
FROM PortfolioProject..['CovidDeaths']
where continent is not null
GROUP BY location, population
ORDER BY ContractionRate DESC

-- Showing Countries with Highest Death Count per Population
SELECT location, population, MAX(total_cases) as LargestInfectionCount, Max((total_cases/population)) *100 as ContractionRate
FROM PortfolioProject..['CovidDeaths']
where continent is not null
GROUP BY location, population
ORDER BY ContractionRate DESC


-- Showing Countries with Highest Death Count per Population
SELECT location, Max(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..['CovidDeaths']
where continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

------------------------------------------------------------------
-- Breaking numbers down by highest death count in a continent (Correct Way)
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.dbo.['CovidDeaths']
where continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC
------------------------------------------------------------------

-- Show the total cases and total deaths of a location each day
SELECT date, location, MAX(total_cases) as TotalCases, MAX(total_deaths) as TotalDeaths
FROM PortfolioProject.dbo.['CovidDeaths']
where continent is not null
GROUP BY date, location
ORDER BY location, date

-----------------------------------------------------------------------------------------------
----------------------- GLOBAL NUMBERS	--------------------------
-- Show new daily cases, new global deaths, and that death percentage
SELECT date, SUM(new_cases) as NewGlobalCases, SUM(cast(new_deaths as int)) as NewGlobalDeaths,
	(SUM(cast(new_deaths as int))/SUM(new_cases)) *100 as DeathPercentage
FROM PortfolioProject.dbo.['CovidDeaths']
where continent is not null
GROUP BY date
ORDER BY date

-- Show overall total of deaths cases and death percentage around the globe
SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths,
	(SUM(cast(new_deaths as int))/SUM(new_cases)) *100 as DeathPercentage
FROM PortfolioProject.dbo.['CovidDeaths']
where continent is not null
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------


-- Find total vaccinated percent by location (Continents)
SELECT death.location, SUM(death.population) as TotalPopulation, SUM(cast(vacc.new_vaccinations as bigint)) as TotalVaccs,
	SUM(cast(vacc.new_vaccinations as bigint))/(SUM(death.population))*100 as TotalVaccinatedPercent
FROM PortfolioProject.dbo.['CovidDeaths'] death
join PortfolioProject.dbo.['CovidVaccinations'] vacc
	on death.iso_code = vacc.iso_code
	WHERE death.continent is null
	group by death.location, death.population
	order by death.population desc
-------------------------------------------------------------



-- Looking at total Population vs Vaccinations

SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations
,SUM(cast(vacc.new_vaccinations as int)) OVER (Partition by death.location ORDER BY death.location,
 death.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.['CovidDeaths'] death
join PortfolioProject.dbo.['CovidVaccinations'] vacc
	ON death.location = vacc.location
	and death.date = vacc.date
WHERE death.continent is not null
ORDER BY 2,3


-- Use CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations
,SUM(cast(vacc.new_vaccinations as int)) OVER (Partition by death.location ORDER BY death.location,
 death.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.['CovidDeaths'] death
join PortfolioProject.dbo.['CovidVaccinations'] vacc
	ON death.location = vacc.location
	and death.date = vacc.date
WHERE death.continent is not null
--ORDER BY 2,3
)
select *, (RollingPeopleVaccinated/population)*100 as PercentOfPopulationVaccinated
from PopvsVac


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
,SUM(cast(vacc.new_vaccinations as int)) OVER (Partition by death.location ORDER BY death.location,
 death.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.['CovidDeaths'] death
join PortfolioProject.dbo.['CovidVaccinations'] vacc
	ON death.location = vacc.location
	and death.date = vacc.date
WHERE death.continent is not null
--ORDER BY 2,3

select *, (RollingPeopleVaccinated/population)*100 as PercentOfPopulationVaccinated
from #PercentPopulationVaccinated
----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------
-- Creating view to store data for later visualizations
Create view PercentPopulationVaccinated as
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations
,SUM(cast(vacc.new_vaccinations as int)) OVER (Partition by death.location ORDER BY death.location,
 death.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.['CovidDeaths'] death
join PortfolioProject.dbo.['CovidVaccinations'] vacc
	ON death.location = vacc.location
	and death.date = vacc.date
WHERE death.continent is not null
--ORDER BY 2,3

select * from PercentPopulationVaccinated
----------------------------------------------------------------------------------------------------