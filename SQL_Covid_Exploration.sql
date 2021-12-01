--Exploring Covid 19 data with Microsoft SQL Sever
--DataSource:https://ourworldindata.org/covid-deaths 
--Skills Shown: 
--Joins, Temp Tables, CTE's, Creating Views,  Aggregate Functions, 
--Windows Functions,  Converting Data Types

----------Shows what Percent of the German population got Coivd by day.----------------
SELECT 
Location,
date,
total_cases,
population,
(total_cases/population)*100 as CasesPerPopulation
FROM
CovidDeaths
WHERE location = 'Germany'
ORDER BY 1,2 DESC
-----------------------Average chance of dying from Covid in each location. -------------------------------------------------
SELECT 
location, 
AVG(
(total_deaths/total_cases)*100) as MeanOddsofDyingAsOf_11_22_21
FROM CovidDeaths 
WHERE location = 'Brazil'
GROUP BY location
ORDER BY 1,2

------------------------------------------------------
--Global  Numbers of COVID-19 cases in the world and percent infected
SELECT SUM(new_cases) AS TotalNewCaseCount,SUM(new_deaths) AS TotalDeathCount,
((SUM(new_deaths))/(SUM(new_cases)))*100 AS Percent_of_Cases_per_death
FROM
CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2 

----------------------PercentOfPopulationInfectedWithCovidByNation.---------------------------------------------
SELECT 
location,
population,
MAX(total_cases) as MaxInfectionCount,
MAX((total_cases/population))*100 as PercentOfPopulationInfectedWithCovid
FROM
CovidDeaths
GROUP BY location,population
ORDER BY 4 desc
--------------------------------------------------------------------------------
--Show nations with the most amount of people dead.Change continet to 'is null' to see what happens
SELECT location,MAX(total_deaths) as CountofDead
FROM
CovidDeaths
--WHERE location = 'United States'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 desc 

------------------CovidCasesWorldwide-------------------------------
Select SUM(new_cases) as AllCases,SUM(new_deaths) as AllDeaths,
SUM(new_deaths)/SUM(New_cases) * 100 as PercentDeadWorldWide
FROM
CovidDeaths
WHERE continent is not null
ORDER BY 1,2
---------------------Both Tables Joined Together-------------------------------
SELECT * 
FROM CovidVaccinations
join CovidDeaths 
ON CovidDeaths.LOCATION = CovidVaccinations.LOCATION
and CovidDeaths.DATE = CovidVaccinations.DATE

--------------------- Total Population vs Vaccinations------------------
SELECT morte.continent,morte.location,population,
SUM(CONVERT(bigint,new_vaccinations)) as NumberofPeopleWhoRecviedAtLeastOneVaccine
FROM CovidVaccinations as vacca
JOIN CovidDeaths as morte 
ON morte.LOCATION = vacca.LOCATION
AND morte.DATE = vacca.DATE
WHERE morte.continent IS NOT NULL
GROUP BY morte.continent,morte.location,population
ORDER BY 1

-----------Looking at total number of people vaccinated per day---------------
SELECT 
morte.date,
morte.continent,
morte.location,
population,
vacca.new_vaccinations,
SUM(CAST (vacca.new_vaccinations AS BIGINT)) OVER (PARTITION BY morte.location order by morte.location 
) AS NumberOfPeopleVaccinatePerDay
FROM CovidDeaths AS morte
JOIN 
CovidVaccinations AS vacca
ON vacca.location = morte.location
AND vacca.date = morte.date
WHERE morte.continent IS NOT NULL
ORDER BY 2,3,1

----------------------Total Number of people vaccinated by percent in each nation via CTE---------------
WITH PopulationVaccinated (
Continent, 
Location, 
Date, 
Population, 
New_Vaccinations, 
TotalVaccinationsPerDay
)
AS
(
SELECT 
morte.continent, 
morte.location, 
morte.date, 
morte.population, 
vacca.new_vaccinations, 
SUM(CONVERT(bigint,vacca.new_vaccinations)) OVER (Partition by morte.Location Order by morte.location, morte.Date) as TotalVaccinationsPerDay
FROM CovidDeaths morte
JOIN CovidVaccinations vacca	
ON morte.location = vacca.location
AND morte.date = vacca.date
WHERE morte.continent IS NOT NULL 
)
SELECT *, (TotalVaccinationsPerDay/Population)*100 PercentofPopulationVaccinatedPerDay
FROM PopulationVaccinated

-------------Temp Table-----------
DROP TABLE IF Exists #TotalPercentofPopulationVaccinated 
CREATE TABLE #TotalPercentofPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population bigint,
New_vaccinations bigint,
TotalDailyPeopleVaccinated float
)
INSERT INTO #TotalPercentofPopulationVaccinated
SELECT 
morte.continent,
morte.location,
morte.date,
population,
vacca.new_vaccinations,
SUM(CAST (vacca.new_vaccinations as bigint)) OVER (Partition by morte.location order by morte.location 
,morte.date) as TotalDailyPeopleVaccinated
FROM CovidDeaths AS morte
JOIN 
CovidVaccinations AS vacca
ON vacca.location = morte.location
AND vacca.date = morte.date
WHERE morte.continent IS NOT NULL
ORDER BY 2,3

SELECT 
*,(TotalDailyPeopleVaccinated/Population) * 100
FROM #TotalPercentofPopulationVaccinated

-------------------Looking at total death per case.----------------------------------------------------------
--This will show us the chance of dying if you contract covid in each country.
SELECT
location,
date,
total_cases,
total_deaths,
(total_deaths/total_cases)*100 as PercentChanceofDying
FROM CovidDeaths
WHERE location = 'United States'
AND continent IS NOT NULL
ORDER BY 1,2
-------------------------Create views--------------------------------
CREATE VIEW PercentPopulationVaccinated as 
SELECT 
CovidDeaths.continent,
CovidDeaths.location,
CovidDeaths.date,
CovidDeaths.population,
CovidVaccinations.new_vaccinations,
SUM(convert(bigint,CovidVaccinations.new_vaccinations)) OVER (PARTITION BY CovidDeaths.location ORDER BY 
CovidDeaths.location,CovidDeaths.date) AS RollingPeopleVaccinated
FROM CovidDeaths 
JOIN CovidVaccinations
ON 
CovidDeaths.location = CovidVaccinations.location 
AND
CovidVaccinations.date = CovidDeaths.date
WHERE CovidDeaths.continent IS NOT NULL
--order by 2,3

--------------------------------View Total Cases and New Cases------------------------------------------------------------------
SELECT 
location,
date,
total_cases,
new_cases,
population 
FROM CovidDeaths
WHERE continent is not null 
ORDER BY 1,2


