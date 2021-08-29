/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT *
--  FROM JasonOrf..Covid_Deaths
--  order by 3,4


--SELECT *
--  FROM JasonOrf..Covid_Vaccinations
--  order by 3,4

-- Select data we will be using

--SELECT location, date, total_cases, new_cases, total_deaths, population
--  FROM JasonOrf..Covid_Deaths
--  order by 1,2


-- Looking at total cases vs total deaths
-- Shows likelihood of dying if you contract covid in your country.
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
  FROM JasonOrf..Covid_Deaths
  where location like '%states%'
  order by 1,2


  -- Looking at the total cases vs population
  -- Shows what percentage of population has gotten covid
SELECT location, date, population, total_cases,  (total_cases/population)*100 as PercentCovid
  FROM JasonOrf..Covid_Deaths
  where location like '%states%'
  order by 1,2


-- Looking at countries w/ highest infection rates compared to population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopInfected
  FROM JasonOrf..Covid_Deaths
  --where location like '%states%'
  group by location, population
  order by 4 desc


-- SHowing countries with highest death count per population

  SELECT location, Max(cast(Total_deaths as int)) as TotalDeathCount
  FROM JasonOrf..Covid_Deaths
  where continent is not null
  group by location, population
  order by TotalDeathCount desc

-- lets break things down by continent (CORRECT)
  SELECT location, Max(cast(Total_deaths as int)) as TotalDeathCount
  FROM JasonOrf..Covid_Deaths
  where continent is null
  group by location
  order by TotalDeathCount desc

  SELECT continent, Max(cast(Total_deaths as int)) as TotalDeathCount
  FROM JasonOrf..Covid_Deaths
  where continent is not null
  group by continent
  order by TotalDeathCount desc

  -- Global numbers
  select 
  --date, 
  sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, (sum(cast(new_deaths as int))/Sum(new_cases))*100 as DeathPercentage
  from JasonOrf..Covid_Deaths
 -- where location like '%states%'
  where continent is not null
  --group by date
  order by 1, 2

-- look at total pop vs vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, 
from JasonOrf..Covid_Deaths dea
Join JasonOrf..Covid_Vaccinations vac
 on dea.location = vac.location
 and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE (Common Expression Table)

with PopvsVac (Continuent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, 
from JasonOrf..Covid_Deaths dea
Join JasonOrf..Covid_Vaccinations vac
 on dea.location = vac.location
 and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

Select *, Format((RollingPeopleVaccinated/Population),'P') as RollingPercentageVaccinated
From PopvsVac
Where Location like '%states%'


-- Temp Table

Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, 
from JasonOrf..Covid_Deaths dea
Join JasonOrf..Covid_Vaccinations vac
 on dea.location = vac.location
 and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as #RollingPercentageVaccinated
From PercentPopulationVaccinated
where location like '%states%'



-- Creating view to store data for later
Create view PercentPopulationVaccinated2 as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, 
from JasonOrf..Covid_Deaths dea
Join JasonOrf..Covid_Vaccinations vac
 on dea.location = vac.location
 and dea.date = vac.date
where dea.continent is not null

select * from PercentPopulationVaccinated2

Create view CountryStatsCovid as
Select location
, max(population) as Population
, max(cast(total_deaths as int)) as Total_Deaths
, (max(cast(total_deaths as int))/max(total_cases))*100 as TotalDeathofInfection
, (max(cast(total_deaths as int))/max(population))*100 as PercentageDeathofPop
from [dbo].[Covid_Deaths]
where continent is not null
group by location
--order by population desc