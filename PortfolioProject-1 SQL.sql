/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

select *
FROM [Portfolio Project]..[CovidDeaths]
Where continent is not null
Order by 3,4

--select *
--FROM [Portfolio Project]..['CovidVaccinations']
--Order by 3,4

-- Select Data that we are going to be using

select Location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..[CovidDeaths]
Order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM [Portfolio Project]..[CovidDeaths]
Where location like '%states%'
Where continent is not null
Order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

select Location, date, total_cases, Population, (total_cases/population)*100 as PercentPopulationInfected
FROM [Portfolio Project]..[CovidDeaths]
Where location = 'United States'
Order by 1,2

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
FROM [Portfolio Project]..[CovidDeaths]
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

-- Countries with Highest Death Count per Population

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..[CovidDeaths]
--Where location like '%states%'
Where continent is not null
Group by Location
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

--Correct Data
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..[CovidDeaths]
--Where location like '%states%'
Where continent is null
Group by location
order by TotalDeathCount desc

-- Used for tutorial
-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM [Portfolio Project]..[CovidDeaths]
--Where location like '%states%'
Where continent is not null
Group by date
Order by 1,2

-- Total GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM [Portfolio Project]..[CovidDeaths]
--Where location like '%states%'
Where continent is not null
--Group by date
Order by 1,2


--Join the two Covid tables from the data by location and date

Select *
FROM [Portfolio Project]..[CovidDeaths] dea
Join [Portfolio Project]..['CovidVaccinations'] vac
On dea.location = vac.location
and dea.date = vac.date

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date)  as RollingPeopleVaccinated
FROM [Portfolio Project]..[CovidDeaths] dea
Join [Portfolio Project]..['CovidVaccinations'] vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
Order by 2,3 asc

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..[CovidDeaths] dea
Join [Portfolio Project]..['CovidVaccinations'] vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
Order by 2,3 asc




Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..[CovidDeaths] dea
Join [Portfolio Project]..['CovidVaccinations'] vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
Order by 2,3 asc

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..[CovidDeaths] dea
Join [Portfolio Project]..['CovidVaccinations'] vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--Order by 2,3
)
Select *, (rollingpeoplevaccinated/population)*100
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..[CovidDeaths] dea
Join [Portfolio Project]..['CovidVaccinations'] vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--Order by 2,3

Select *, (rollingpeoplevaccinated/population)*100
From #PercentPopulationVaccinated



--Creating View to store data for later visualizations

USE [Portfolio Project]

Alter View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..[CovidDeaths] dea
Join [Portfolio Project]..['CovidVaccinations'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


Select * 
From PercentPopulationVaccinated