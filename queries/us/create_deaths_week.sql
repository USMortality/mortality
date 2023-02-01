ALTER TABLE
    deaths.imp_deaths
MODIFY
    year INTEGER;

ALTER TABLE
    deaths.imp_deaths
MODIFY
    week INTEGER;

CREATE INDEX IF NOT EXISTS idx_all ON deaths.imp_deaths (jurisdiction, year, week, age_group, `type`);

-- ***
-- Create the expected weekly structure, as some weeks might be missing.
-- ***
DROP TABLE IF EXISTS deaths.deaths_structure;

CREATE TABLE deaths.deaths_structure AS
SELECT
    *
FROM
    (
        SELECT
            DISTINCT jurisdiction
        FROM
            deaths.imp_deaths
    ) a
    CROSS JOIN (
        SELECT
            DISTINCT year,
            week,
            age_group
        FROM
            deaths.imp_deaths
        WHERE
            jurisdiction = 'United States'
    ) b;

CREATE INDEX idx_all ON deaths.deaths_structure (year, week, jurisdiction, age_group);

ANALYZE TABLE deaths.deaths_structure;

ANALYZE TABLE deaths.imp_deaths;

-- ***
-- Sanitize data.
-- ***
DROP VIEW IF EXISTS deaths.deaths_week_age;

CREATE VIEW deaths.deaths_week_age AS
SELECT
    a.jurisdiction AS "state",
    a.year,
    a.week,
    CASE
        WHEN a.age_group = "Under 25 years" THEN "0-24"
        WHEN a.age_group = "25-44 years" THEN "25-44"
        WHEN a.age_group = "45-64 years" THEN "45-64"
        WHEN a.age_group = "65-74 years" THEN "65-74"
        WHEN a.age_group = "75-84 years" THEN "75-84"
        WHEN a.age_group = "85 years and older" THEN "85+"
    END AS "age_group",
    b.deaths
FROM
    deaths.deaths_structure a
    LEFT JOIN (
        -- Combine NYC and NY data
        SELECT
            "New York" AS jurisdiction,
            year,
            week,
            age_group,
            sum(number_of_deaths) AS "deaths",
            TYPE
        FROM
            deaths.imp_deaths
        WHERE
            jurisdiction LIKE "New York%"
        GROUP BY
            year,
            week,
            age_group,
            TYPE
        UNION
        -- and combine with rest
        ALL
        SELECT
            jurisdiction,
            year,
            week,
            age_group,
            number_of_deaths AS "deaths",
            TYPE
        FROM
            deaths.imp_deaths
        WHERE
            jurisdiction <> "New York"
    ) b ON a.jurisdiction = b.jurisdiction
    AND a.year = b.year
    AND a.week = b.week
    AND a.age_group = b.age_group
    AND b.`type` = "Unweighted" -- "Predicted (weighted)"
;

DROP TABLE IF EXISTS deaths.deaths_week;

CREATE TABLE deaths.deaths_week AS
SELECT
    state,
    year,
    week,
    concat(year, '_', lpad(week, 2, 0)) AS 'year_week',
    age_group,
    deaths,
    deaths_covid
FROM
    (
        SELECT
            state,
            year,
            week,
            age_group,
            deaths,
            0 AS deaths_covid
        FROM
            deaths.deaths_week_age
        UNION
        ALL
        SELECT
            state,
            year,
            week,
            age_group,
            deaths,
            deaths_covid
        FROM
            deaths.all_cause_covid_week a
    ) a
ORDER BY
    state,
    year,
    week,
    age_group;