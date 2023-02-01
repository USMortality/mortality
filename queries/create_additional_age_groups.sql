INSERT INTO
  deaths.deaths_week_projected
SELECT
  state,
  year,
  week,
  "65+" AS "age_group",
  sum(deaths) AS "deaths",
  sum(deaths_covid) AS "deaths_covid",
  sum(deaths_projected) AS "deaths_projected",
  sum(deaths_lower_projected) AS "deaths_lower_projected",
  sum(deaths_upper_projected) AS "deaths_upper_projected",
  max(has_projection) AS "has_projection",
  1 AS is_calculated
FROM
  deaths.deaths_week_projected
WHERE
  age_group IN ('65-74', '75-84', '85+')
GROUP BY
  state,
  year,
  week;

INSERT INTO
  deaths.deaths_week_projected
SELECT
  state,
  year,
  week,
  "0-64" AS "age_group",
  sum(deaths) AS "deaths",
  sum(deaths_covid) AS "deaths_covid",
  sum(deaths_projected) AS "deaths_projected",
  sum(deaths_lower_projected) AS "deaths_lower_projected",
  sum(deaths_upper_projected) AS "deaths_upper_projected",
  max(has_projection) AS "has_projection",
  1 AS is_calculated
FROM
  deaths.deaths_week_projected
WHERE
  age_group IN ('0-24', '25-44', '0-29', '30-44', '45-64')
GROUP BY
  state,
  year,
  week;

INSERT INTO
  population.imp_population (jurisdiction, age_group, year, population)
SELECT
  jurisdiction,
  "65+" AS "age_group",
  year,
  sum(population) AS "population"
FROM
  population.imp_population
WHERE
  age_group IN ('65-74', '75-84', '85+')
GROUP BY
  jurisdiction,
  year;

INSERT INTO
  population.imp_population (jurisdiction, age_group, year, population)
SELECT
  jurisdiction,
  "0-64" AS "age_group",
  year,
  sum(population) AS "population"
FROM
  population.imp_population
WHERE
  age_group IN ('0-24', '25-44', '0-29', '30-44', '45-64')
GROUP BY
  jurisdiction,
  year;