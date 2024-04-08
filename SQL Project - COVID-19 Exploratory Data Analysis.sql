/* COVID-19 DATA EXPLORATION

Skills Used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4


--SELECT DATA TO USE--

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--TOTAL CASES v. TOTAL DEATHS--
	--Likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (CONVERT(float,total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

--TOTAL CASES v. POPULATION--
	--Shows percentage of population that got covid

SELECT location, date, population, total_cases, (CONVERT(float,total_cases) / NULLIF(CONVERT(float, population), 0))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
Order by 1,2

--IDENTIFY COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION--

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(CONVERT(float,total_cases) / NULLIF(CONVERT(float, population), 0))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

--SHOWS COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION--
	--After cast, location data inaccurate (ex: "World")

SELECT Location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount desc

--SELECT *
--FROM PortfolioProject..CovidDeaths
--WHERE continent is not null
--Order by 3, 4


--LOOK AT DATA BY CONTINENT--
	--N. America does not include Canada
	--Shows continents with highest death count

SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths--WHERE location like '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

--SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
--FROM PortfolioProject..CovidDeaths
----WHERE location like '%states%'
--WHERE continent is null
--Group by location
--Order by TotalDeathCount desc


--GLOBAL NUMBERS--

SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(NULLIF(new_cases,0))*100 as GlobalDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


--JOIN TABLES (CovidDeaths and CovidVaccinations)--

SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

--TOTAL POPULATION v. VACCINATIONS--
	--Total # of people in the world vaccinated

--USE CTE--

WITH PopvsVac(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated

--How many people in each country are vaccinated
	--, (RollingPeopleVaccinated/population)*100

FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac

--CREATE TEMP TABLE--

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent NVARCHAR(255),
location NVARCHAR(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated

FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


--CREATE VIEW TO STORE DATA FOR LATER VISUALIZATIONS--

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated

FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3


SELECT * 
FROM PercentPopulationVaccinated
