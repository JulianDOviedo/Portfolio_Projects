/*  */
/* Project: Covid Data From 2020 - 2021 */
/* */


Select *
From PortfolioProject..CovidDeaths
Where continent is not null -- There are some Data in which the location is a continent, and continent is NULL. Unusable!
Order by 3,4


--Select *
--From PortfolioProject..CovidVaccinations
--Where continent is not null
--Order by 3,4




/* Select the Data we are going to be using */

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
Order By 1,2


/* Looking at Total Cases vs Total Deaths */
-- How many cases per county, and how many deaths for their entire cases. Shows likelihood of dying from covid by being infected per country

Select Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
From PortfolioProject..CovidDeaths
Where Location like '%states%' -- Select a country
and continent is not null
Order By Location, date



/* Looking at Total Cases vs Population */
-- Shows what percentage of the population has been infected by covid.

Select Location, date, population, total_cases, (total_cases / population) * 100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where Location like '%states%' -- Select a country
and continent is not null
Order By Location, date



/* Looking at counries with the highest Infection Rate compared to Population */
-- .

Select Location, population, max(total_cases) as HighestInfectionCount, max((total_cases / population)) * 100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where Location like '%states%' -- Select a country
Where continent is not null
Group by Location, Population
Order By PercentPopulationInfected Desc



/* Looking at how many people died */
-- Showing Countries with the Highest Death Count per Population.

Select Location, max(cast(total_deaths as int)) as TotalDeathCount -- Total_Deaths needs to be converted (casted) as a numeric
From PortfolioProject..CovidDeaths
--Where Location like '%states%' -- Select a country
Where continent is not null
Group by Location 
Order By TotalDeathCount Desc





/* ANALYSING DATA BY CONTINENT */

-- Showing Regions with the highest Death Count per Population.

Select location, max(cast(total_deaths as int)) as TotalDeathCount -- Total_Deaths needs to be converted (casted) as a numeric
From PortfolioProject..CovidDeaths
--Where Location like '%states%' -- Select a country
Where continent is null -- Like this it is possible to get the whole Data by Continent/Region
Group by location 
Order By TotalDeathCount Desc


-- Showing Continent with the highest Death Count per Population.

Select continent, max(convert(int, total_deaths)) as TotalDeathCount 
From PortfolioProject..CovidDeaths
--Where Location like '%states%'
Where continent is not null 
Group by continent 
Order By TotalDeathCount Desc



/* GLOBAL NUMBERS */ 

-- Therefore not including Location, Continent

-- Daily Deaths across the World
Select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, (sum(cast(new_deaths as int)) / sum(new_cases)) * 100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where Location like '%states%' -- Select a country
Where continent is not null
Group by date
Order By 1, 2


-- Total Deaths across the World during Covid's first year
Select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, (sum(cast(new_deaths as int)) / sum(new_cases)) * 100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where Location like '%states%' -- Select a country
Where continent is not null
--Group by date
Order By 1, 2



/* Now Let's take a look at Vaccinations */ 
Select *
From PortfolioProject..CovidVaccinations
Where continent is not null
Order by 3,4



/* JOIN both tables Deaths & Vaccinations */
Select *
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac
	On dea.location = vac.location and  dea.date = vac.date
Order by 3, 4


/* Looking at Total Population vs New Vaccinations per day */
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac
	On dea.location = vac.location and  dea.date = vac.date
Where dea.continent is not null
Order by 2, 3



/* Cummulative sum of daily vaccinations per country */ -- SUM only for every Country and starts over
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as int)) Over (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac
	On dea.location = vac.location and  dea.date = vac.date
Where dea.continent is not null
Order by 2, 3




/* USE A CTE */ 

With PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) -- number of columns must match
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as int)) Over (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac
	On dea.location = vac.location and  dea.date = vac.date
Where dea.continent is not null
--Order by 2, 3
)
Select *, (RollingPeopleVaccinated / Population) * 100 as PercentPeopleVaccinated
From PopvsVac



/* USE A TEMP TABLE */ 

Drop Table if exists #PercentPopulationVaccinated -- Add this for making further alterations
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as int)) Over (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac
	On dea.location = vac.location and  dea.date = vac.date
--Where dea.continent is not null
--Order by 2, 3

Select *, (RollingPeopleVaccinated / Population) * 100 as PercentPeopleVaccinated
From #PercentPopulationVaccinated



/* Finally, let's create a View to store Data for later visualizations */

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as int)) Over (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac
	On dea.location = vac.location and  dea.date = vac.date
Where dea.continent is not null
--Order by 2, 3

Select *
From PercentPopulationVaccinated







Select continent, max(convert(int, total_deaths)) as TotalDeathCount 
From PortfolioProject..CovidDeaths
--Where Location like '%states%'
Where continent is not null 
Group by continent 
Order By TotalDeathCount Desc

