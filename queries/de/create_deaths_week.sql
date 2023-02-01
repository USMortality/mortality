SELECT
  state,
  year,
  week,
  year_week,
  age_group,
  sum(deaths) AS "deaths",
  NULL AS "deaths_covid"
FROM
  (
    SELECT
      a.jurisdiction AS "state",
      cast(a.year AS integer) AS "year",
      cast(lpad(a.week, 2, 0) AS integer) AS "week",
      concat(a.year, '_', lpad(a.week, 2, 0)) AS 'year_week',
      CASE
        WHEN a.age_group IN ("Insgesamt") THEN "all"
        WHEN a.age_group IN ("0-30") THEN "0-29"
        WHEN a.age_group IN ("30-35") THEN "30-44"
        WHEN a.age_group IN ("35-40") THEN "30-44"
        WHEN a.age_group IN ("40-45") THEN "30-44"
        WHEN a.age_group IN ("45-50") THEN "45-64"
        WHEN a.age_group IN ("50-55") THEN "45-64"
        WHEN a.age_group IN ("55-60") THEN "45-64"
        WHEN a.age_group IN ("60-65") THEN "45-64"
        WHEN a.age_group IN ("65-70") THEN "65-74"
        WHEN a.age_group IN ("70-75") THEN "65-74"
        WHEN a.age_group IN ("75-80") THEN "75-84"
        WHEN a.age_group IN ("80-84") THEN "75-84"
        WHEN a.age_group IN ("85-90") THEN "85+"
        WHEN a.age_group IN ("90-95") THEN "85+"
        WHEN a.age_group IN ("95") THEN "85+"
        ELSE a.age_group
      END AS "age_group",
      cast(a.deaths AS integer) AS "deaths"
    FROM
      deaths.imp_deaths a
    WHERE
      a.week <= 52
      AND a.deaths > 0
      AND a.jurisdiction = "Deutschland"
    UNION
    SELECT
      CASE
        WHEN a.jurisdiction = "Mecklenburg-Vorpomme" THEN "Mecklenburg-Vorpommern"
        ELSE a.jurisdiction
      END AS "state",
      cast(a.year AS integer) AS "year",
      cast(lpad(a.week, 2, 0) AS integer) AS "week",
      concat(a.year, '_', lpad(a.week, 2, 0)) AS 'year_week',
      CASE
        WHEN a.age_group IN ("Insgesamt") THEN "all"
        WHEN a.age_group IN ("0-65") THEN "0-64"
        WHEN a.age_group IN ("65-75") THEN "65-74"
        WHEN a.age_group IN ("75-85") THEN "75-84"
        WHEN a.age_group IN ("85") THEN "85+"
        ELSE a.age_group
      END AS "age_group",
      cast(a.deaths AS integer) AS "deaths"
    FROM
      deaths.imp_deaths a
    WHERE
      a.week <= 52
      AND a.deaths > 0
      AND a.jurisdiction <> "Deutschland"
  ) a
GROUP BY
  state,
  age_group,
  year,
  week
ORDER BY
  state,
  age_group,
  year,
  week;