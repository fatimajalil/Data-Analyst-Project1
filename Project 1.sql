/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select *
From Project1..Covid_Deaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From Project1..Covid_Deaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Death Percentage 


Select Location, date, total_cases,total_deaths,
(convert (float, total_deaths)/convert (float, total_cases))*100 as death_percentage
From Project1..Covid_Deaths
 Where location like '%states%'
 order by 1,2

 -- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (convert (float, total_cases)/population)*100 as infection_percentage
From Project1..Covid_Deaths
Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as highest_infection_count,  Max((convert (float, total_cases)/population))*100 as infection_percentage
From Project1..Covid_Deaths
Group by Location, Population
order by infection_percentage desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as total_death_count
From Project1..Covid_Deaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by total_death_count desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select location,  MAX(cast(total_deaths as int)) as total_death_count
From Project1..Covid_Deaths
Where continent is null 
Group by location
order by total_death_count desc
 
 Select Location, MAX(cast(Total_deaths as int)) as total_death_count
From Project1..Covid_Deaths
Where continent is not null 
Group by Location
order by total_death_count desc



-- GLOBAL NUMBERS
-- ----------------
--got error division by zero 
Update Project1..Covid_Deaths set new_cases = NULL where new_cases = 0.
-- ----------------
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage 
From Project1..Covid_Deaths
where continent is not null 
Group By date
order by 1,2

-- Totoal cases, deaths and the percentage for the eniter world

Select  SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage 
From Project1..Covid_Deaths
where continent is not null 
--Group By date
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select * 
From Project1..Covid_Deaths dea
Join Project1..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date



Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_people_vaccinated
From Project1..Covid_Deaths dea
Join Project1..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- people vaccinated in one country

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_people_vaccinated
, (rolling_people_vaccinated/population)*100
From Project1..Covid_Deaths dea
Join Project1..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, rolling_people_vaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_people_vaccinated
--, (rolling_people_vaccinated/population)*100
From Project1..Covid_Deaths dea
Join Project1..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)

Select *, (rolling_people_vaccinated/Population)*100 AS rolling_people_vaccinated
From PopvsVac




-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #Percent_population_vaccinated
Create Table #Percent_population_vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #Percent_population_vaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project1..Covid_Deaths dea
Join Project1..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


Select *, (RollingPeopleVaccinated/Population)*100
From #Percent_population_vaccinated




-- Creating View to store data for later visualizations
Drop View if exists Percent_population_vaccinated
Create View Percent_population_vaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From Project1..Covid_Deaths dea
Join Project1..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 