-- Data was imported using the mysql workbench import wizard
/*
skills used:
	Joins
    CTE's
    Temp Tables
    Window Funcitons
    Aggregate Functions
    Creating Views
    Converting Datatypes
*/
-- Database creation
CREATE DATABASE covid19;
use covid19;

-- Preview the data
select * from coviddeaths;
select * from covidvaccinations;

-- select data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population from coviddeaths order by 1,2;

-- BEGIN DRAWING INSIGHTS FROM DATA

-- per country, what is the ratio of deaths to cases?
-- This shows the liklihood of dying if you contract covid in your country  
select location,date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage from coviddeaths
order by 1,2;

-- look at specific country
select location,date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage from coviddeaths where 
location like '% states' order by 1,2;

-- what is the ratio of people infected to the total population?
-- shows what percentage of population got covid (infected/total)
select location,date,population, total_cases, total_deaths, (total_cases/population)*100 as cases_per_population 
from coviddeaths where location like '%States' order by 1,2;

-- which country had the highest infection percentage?
-- most dangerous countries throughout corona period
select location, population, max(cast(total_cases as signed)) as highest_infection_count, max((total_cases/population)*100) as percent_population_infected
from coviddeaths group by location, population order by percent_population_infected desc; 

-- showing countries with highest death count per population
-- initially when we try max(total_deaths), it is displayed as nvarchar(255), we need to cast it  
select location, population,max(cast(total_deaths as signed)) as highest_death_count, max((total_deaths/population)*100) as percent_population_dead
from coviddeaths group by location, population order by percent_population_dead desc;

-- Breaking down data by continent 

-- notice that the groups consist of continents (ex: europe) and even world, which causes discrepency in how we wanted our data to be 
-- read initially. this is because in the original datatset, there is data for the countries but also data for the continents as a whole
select * from coviddeaths;
select * from covidvaccinations;

-- going back to the original dataset, you can see that when the author wants to show data for a continent, the continent field is null or empty
-- instead, the location column holds the continent name. so if we only want to see statistics for countries,
-- we can do : where cotinent is not empty (or not null using other sql import wizards. this is what worked for mysql workbench) 
-- total death count over entire peiod for each country 
select location, population, max(cast(total_deaths as signed)) as Total_death_count from coviddeaths where continent !='' 
group by location, population order by Total_death_count desc;

-- do the same for all countries in a given continent: 
-- total death count for all countries, grouped by continent
select continent, sum(population) as total_population, max(cast(total_deaths as signed)) as Total_death_count from coviddeaths 
where continent !='' group by continent order by Total_death_count desc;

-- do the saame for a continent: (note that the continent entries; location = continent name, the cotinent field was empty in the dataset)
select location, continent, max(cast(total_deaths as signed)) as Total_death_count from coviddeaths 
where continent ='' group by location order by Total_death_count desc;
 
 
 -- now let's join our two tables: covid deaths and covid vaccinations 
 select * from coviddeaths as dea join covidvaccinations vac on dea.location = vac.location and dea.date=vac.date;
 
 -- look at total population vs vaccinations 
 select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 sum(vac.new_vaccinations) over (partition by dea.location) -- partition by location to ensure the the sum zeros with every new location  
 from coviddeaths dea join covidvaccinations vac on dea.location = vac.location and dea.date = vac.date where dea.continent !=''
 order by 2,3;
 
 -- the above query will show the total number of vaccinations over the entire period in a new column for each distinct location.
 -- What if we want a rolling sum? :
  select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
 -- using order by with window functions allows us to perform rolling operations (notice albania in the table: 60+78=138)
 from coviddeaths dea join covidvaccinations vac on dea.location = vac.location and dea.date = vac.date where dea.continent !=''
 order by 2,3;
 
-- now, we want to use the total number of people vaccinated in the country and find total_vaccinations/population to find percentage vaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
 -- using order by with window functions allows us to perform rolling operations (notice albania in the table: 60+78=138)
 , rolling_people_vaccinated/population -- this query will result in an error from this line, you can't use a column you just created
 from coviddeaths dea join covidvaccinations vac on dea.location = vac.location and dea.date = vac.date where dea.continent !='' 
  group by dea.location order by 2,3;
 
 -- we need to resort to views or cte '
 -- the following query will provide rolling sum + rolling percentages of people vaccinated in each country relative to the population
 -- cte:
 with popvsvac as(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
 -- using order by with window functions allows us to perform rolling operations (notice albania in the table: 60+78=138)
 from coviddeaths dea join covidvaccinations vac on dea.location = vac.location and dea.date = vac.date where dea.continent !=''
 order by 2,3)
  select *,(rolling_people_vaccinated/population)*100 as percent_vaccinated from popvsvac;
  
-- we could also use a temp table here 
-- Using Temp Table to perform Calculation on Partition By in previous query:
DROP Table if exists PercentPopulationVaccinated;
Create temporary Table PercentPopulationVaccinated(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population long,
New_vaccinations long,
RollingPeopleVaccinated long
);

Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date;

Select *, (RollingPeopleVaccinated/Population)*100
From PercentPopulationVaccinated;

-- creating views to store data for later visualizations ( try to do after/before eid,christmas analysis and visualizations)
-- seeing rolling percentage using views 
drop view if exists PercentPopulationVaccinated;
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent !='' ;
 
select *, (RollingPeopleVaccinated/population)*100 from PercentPopulationVaccinated;

