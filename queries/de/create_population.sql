SELECT
  jurisdiction,
  age_group,
  year,
  sum(population) AS "population"
FROM
  (
    SELECT
      CASE
        WHEN jurisdiction = "Mecklenburg-Vorpomme" THEN "Mecklenburg-Vorpommern"
        ELSE jurisdiction
      END AS "jurisdiction",
      year,
      CASE
        WHEN age_group IN ("Insgesamt") THEN "all"
        WHEN age_group IN ("0-30") THEN "0-29"
        WHEN age_group IN ("30-35") THEN "30-44"
        WHEN age_group IN ("35-40") THEN "30-44"
        WHEN age_group IN ("40-45") THEN "30-44"
        WHEN age_group IN ("45-50") THEN "45-64"
        WHEN age_group IN ("50-55") THEN "45-64"
        WHEN age_group IN ("55-60") THEN "45-64"
        WHEN age_group IN ("60-65") THEN "45-64"
        WHEN age_group IN ("65-70") THEN "65-74"
        WHEN age_group IN ("70-75") THEN "65-74"
        WHEN age_group IN ("75-80") THEN "75-84"
        WHEN age_group IN ("80-85") THEN "75-84"
        WHEN age_group IN ("85-90") THEN "85+"
        WHEN age_group IN ("90-95") THEN "85+"
        WHEN age_group IN ("95") THEN "85+"
        WHEN age_group IN ("0-65") THEN "0-64"
        WHEN age_group IN ("65-75") THEN "65-74"
        WHEN age_group IN ("75-85") THEN "75-84"
        WHEN age_group IN ("85") THEN "85+"
        ELSE age_group
      END AS "age_group",
      population
    FROM
      population.imp_einwohner
  ) a
GROUP BY
  jurisdiction,
  age_group,
  year
ORDER BY
  jurisdiction,
  age_group,
  year;