DROP VIEW IF EXISTS deaths.all_cause_covid_week_tmp;

CREATE VIEW deaths.all_cause_covid_week_tmp AS
SELECT
    state,
    year,
    week,
    "all" AS "age_group",
    deaths,
    cast(
        IFNULL(nullif(deaths_covid, ''), 0) AS UNSIGNED
    ) AS "deaths_covid"
FROM
    (
        SELECT
            jurisdiction_of_occurrence AS "state",
            cast(mmwr_year AS INTEGER) AS "year",
            cast(mmwr_week AS INTEGER) AS "week",
            all_cause AS "deaths",
            covid19_u071_underlying "deaths_covid"
        FROM
            deaths.imp_covid_deaths
        UNION
        ALL
        SELECT
            jurisdiction_of_occurrence AS "state",
            cast(mmwr_year AS INTEGER) AS "year",
            cast(mmwr_week AS INTEGER) AS "week",
            all__cause AS "deaths",
            0 "deaths_covid"
        FROM
            deaths.imp_covid_deaths_2014_2019
        WHERE
            mmwr_year >= 2015
    ) a
ORDER BY
    state,
    year,
    week,
    age_group;

-- Combine NY & NYC
DROP TABLE IF EXISTS deaths.all_cause_covid_week;

CREATE TABLE deaths.all_cause_covid_week AS
SELECT
    "New York" AS state,
    year,
    week,
    age_group,
    sum(deaths) AS "deaths",
    sum(deaths_covid) AS "deaths_covid"
FROM
    deaths.all_cause_covid_week_tmp
WHERE
    state LIKE "New York%"
GROUP BY
    year,
    week,
    age_group
UNION
ALL
SELECT
    *
FROM
    deaths.all_cause_covid_week_tmp
WHERE
    state <> "New York";

CREATE INDEX idx_all ON deaths.all_cause_covid_week (state, year, week);