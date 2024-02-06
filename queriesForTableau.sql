-- you can use these views in tableau later on 
-- Queries used for Tableau Project
-- 1. 

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
-- Where location like '%states%'
where continent !=''
-- Group By date
order by 1,2;

-- 2. 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe
Select location, SUM(new_deaths) as TotalDeathCount
From CovidDeaths
-- Where location like '%states%'
Where continent ='' 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc;

-- 3.

Select Location, Population, MAX(cast(total_cases as signed)) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
from CovidDeaths
-- Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc;

-- 4.


Select Location, Population,date, MAX(cast(total_cases as signed)) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
-- Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc;