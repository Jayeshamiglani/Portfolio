USE portfolio;

SELECT * 
FROM CovidDeaths#xlsx$
where continent is not null
ORDER BY 3,4;

SELECT * 
FROM CovidVaccinations#xlsx$
where continent is not null
order by 3,4;

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths#xlsx$
where continent is not null
order by 3,4

select column_name, data_type
from INFORMATION_SCHEMA.columns
where table_name = 'CovidDeaths#xlsx$' and COLUMN_NAME = 'total_deaths'

-- Total Cases v/s Total Deaths
select 
	Location, date, total_cases, total_deaths, 
	CONVERT	(DECIMAL(18, 5), 
					(CONVERT
						(DECIMAL(18, 5), total_deaths) / 
					CONVERT
						(DECIMAL(18, 5), total_cases)
			))*100	as [DeathsOverTotal]
from CovidDeaths#xlsx$
where location like 'India' and continent is not null
order by 1,2


-- Total Cases v/s Population
-- Shows what percentage of population got covid


--Looking at countries with highest infection rate compared to population

select 
	Location, 
	population, 
	Max(cast(total_cases as int)) as TC, 
	Max(Convert	(Decimal(18,5),
			(CONVERT		(Decimal(18,2),total_cases)/
			Convert			(Decimal(18,2),population) 
			)))*100 as [PercentPopulationInfected]
from CovidDeaths#xlsx$
where continent is not null
group by location, population
order by PercentPopulationInfected desc
 
--Looking at countries with highest death rate compared to population

select 
	Location, 
	Population, 
	Max(cast(total_deaths as int)) as TotalDeathCount, 
	Max(Convert(Decimal(18,5),
		(CONVERT		(Decimal(18,5),total_deaths)/
		Convert			(Decimal(18,5),population) 
		)))*100 as [PercentPopulationDied]
from CovidDeaths#xlsx$
where continent is not null
Group by Location, population
order by TotalDeathCount desc

--Showing the locations with highest death count per population

select 
	Location, 
		Max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths#xlsx$
where continent is not null
Group by location
order by TotalDeathCount desc

--Showing the continents with highest death count per population

select 
	Continent, 
		Max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths#xlsx$
where continent is not null
Group by Continent
order by TotalDeathCount desc


-- Global Numbers 

select 
	date, sum(new_cases) as TC,	sum(new_deaths) as TD,
	(sum(new_deaths)/sum(new_cases))*100 as DeathOverTotal 
	from CovidDeaths#xlsx$
where continent is not null and new_cases <> 0
group by Date
order by 1

--Total Cases

select 
	sum(new_cases) as TC,	sum(new_deaths) as TD,
	(sum(new_deaths)/sum(new_cases))*100 as DeathOverTotal 
from CovidDeaths#xlsx$
where continent is not null and new_cases <> 0


--looking at total population v/s vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert(decimal(20,2), vac.new_vaccinations)) 
		Over (Partition by dea.location 
			Order by dea.location, dea.date) as Rolling_vaccinated
from Portfolio..CovidDeaths#xlsx$ dea
Join Portfolio..CovidVaccinations#xlsx$ vac
	on dea.location=vac.location 
	and dea.date=vac.date
where dea.continent is not null
order by 1,2,3


--Use CTE

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, Rolling_vaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert(decimal(20,2), vac.new_vaccinations)) 
		Over (Partition by dea.location 
			Order by dea.location, dea.date) as Rolling_vaccinated
from Portfolio..CovidDeaths#xlsx$ dea
Join Portfolio..CovidVaccinations#xlsx$ vac
	on dea.location=vac.location 
	and dea.date=vac.date
where dea.continent is not null
)

select *, (Rolling_vaccinated/population)*100 
from PopvsVac


--Temp Table

DROP TABLE if exists #PercentpopulationVaccinated
Create Table #PercentpopulationVaccinated
(Continet nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinantion numeric,
Rolling_vaccinated numeric)

Insert into #PercentpopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert(decimal(20,2), vac.new_vaccinations)) 
		Over (Partition by dea.location 
			Order by dea.location, dea.date) as Rolling_vaccinated
from Portfolio..CovidDeaths#xlsx$ dea
Join Portfolio..CovidVaccinations#xlsx$ vac
	on dea.location=vac.location 
	and dea.date=vac.date
where dea.continent is not null
order by 1,2,3


select *, (Rolling_vaccinated/population)*100
from #PercentpopulationVaccinated

--Createing view to store data for later visualizations

CREATE View PercentPopulationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert(decimal(20,2), vac.new_vaccinations)) 
		Over (Partition by dea.location 
			Order by dea.location, dea.date) as Rolling_vaccinated
from Portfolio..CovidDeaths#xlsx$ dea
Join Portfolio..CovidVaccinations#xlsx$ vac
	on dea.location=vac.location 
	and dea.date=vac.date
where dea.continent is not null
--order by 2,3

select * from PercentPopulationVaccinated
