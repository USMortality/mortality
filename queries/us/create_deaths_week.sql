ALTER TABLE deaths.imp_deaths
MODIFY year INTEGER;
ALTER TABLE deaths.imp_deaths
MODIFY week INTEGER;
DROP TABLE IF EXISTS deaths.deaths_week;
Select *
from deaths.imp_deaths
ORDER BY state,
    year,
    week,
    age_group;