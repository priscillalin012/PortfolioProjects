Select * 
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4

Select * 
From PortfolioProject..CovidVaccinations
order by 3,4

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2

--Looking at Total Cases vs Total Deaths (percentage of cases that died from covid) in the US
--Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths,CONVERT(DECIMAL(18,5),(CONVERT(DECIMAL(18,5),total_deaths)/CONVERT(DECIMAL(18,5),total_cases)))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%' 
and continent is not null
order by 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid

Select Location, date, population,total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%states%' 
and continent is not null
order by 1,2

--Looking at Countries with Highest Infection Rate compared to Population

Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc

-- Showing Countries with Highest Death Count per Population
--cast as int because the total_deaths is a varchar

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by Location
order by TotalDeathCount desc

-- Let's break this down by continent
-- Showing continent with the highest death count per population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
order by TotalDeathCount desc

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null
Group by location
order by TotalDeathCount desc

-- Global numbers

Select date, SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths,(CONVERT(DECIMAL(18,5),SUM(CONVERT(DECIMAL(18,5),new_deaths))/NULLIF(SUM(new_cases),0)))*100 as NewDeathPercentage
From PortfolioProject..CovidDeaths 
Where continent is not null
Group by date
order by 1,2

-- OR

Select date, SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths,(SUM(cast (new_deaths as int))/NULLIF(SUM(new_cases),0))*100 as NewDeathPercentage
From PortfolioProject..CovidDeaths 
Where continent is not null
Group by date
order by 1,2


-- Joining two tables

Select * 
From PortfolioProject..CovidDeaths Dea
Join PortfolioProject..CovidVaccinations Vac
     on dea.location = vac.location
	 and dea.date = vac.date

-- Looking at Total Population vs. Vaccinations 

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
     on dea.location = vac.location
	 and dea.date = vac.date
	     where dea.continent is not null
	     order by 2, 3

--Rolling count of new vaccinations per day - use partition over

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) 
OVER (Partition by dea.location
Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
     on dea.location = vac.location
	 and dea.date = vac.date
	     where dea.continent is not null
	     order by 2, 3

--Percentage of new vaccinations per day
--USE CTE

With PopvsVac (Continent, location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location
Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
     on dea.location = vac.location
	 and dea.date = vac.date
	     where dea.continent is not null
)

Select *, (RollingPeopleVaccinated/Population)*100 as PercentRollingVaccinatedPerPopulation
From PopvsVac

--Temp Table

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
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location
Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
     on dea.location = vac.location
	 and dea.date = vac.date
	     where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100 as PercentRollingVaccinatedPerPopulation
From #PercentPopulationVaccinated

-- Creating View to Store Data for Later Visualations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location
Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
     on dea.location = vac.location
	 and dea.date = vac.date
	     where dea.continent is not null

Select *
From PercentPopulationVaccinated
