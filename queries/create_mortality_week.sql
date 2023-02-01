CREATE INDEX IF NOT EXISTS idx_all ON deaths.deaths_week_projected (state, year, age_group);

CREATE INDEX IF NOT EXISTS idx_all ON population.imp_population (jurisdiction, year, age_group);

-- ***
-- Create Mortality table, per 100k.
-- ***
DROP TABLE IF EXISTS population.population_weights_2022;

CREATE TABLE population.population_weights_2022 AS
SELECT
    a.jurisdiction,
    a.age_group,
    a.population / b.population AS f
FROM
    population.imp_population a
    JOIN population.imp_population b ON a.jurisdiction = b.jurisdiction
    AND a.year = 2022
    AND b.year = 2022
    AND b.age_group = "all";

DROP TABLE IF EXISTS deaths.mortality_week_tmp;

CREATE TABLE deaths.mortality_week_tmp AS
SELECT
    state,
    cast(a.year AS integer) AS "year",
    cast(week AS integer) AS "week",
    a.age_group,
    deaths,
    deaths_covid,
    deaths_projected,
    deaths_lower_projected,
    deaths_upper_projected,
    has_projection,
    population,
    @mortality := deaths / population * 100000 AS 'mortality',
    @mortality_projected := deaths_projected / population * 100000 AS 'mortality_projected',
    @mortality_lower_projected := deaths_lower_projected / population * 100000 AS 'mortality_lower_projected',
    @mortality_upper_projected := deaths_upper_projected / population * 100000 AS 'mortality_upper_projected',
    CASE
        WHEN a.age_group = "all" THEN ''
        ELSE @mortality * c.f
    END AS 'adj_mortality',
    CASE
        WHEN a.age_group = "all" THEN ''
        ELSE @mortality_projected * c.f
    END AS 'adj_mortality_projected',
    CASE
        WHEN a.age_group = "all" THEN ''
        ELSE @mortality_lower_projected * c.f
    END AS 'adj_mortality_lower_projected',
    CASE
        WHEN a.age_group = "all" THEN ''
        ELSE @mortality_upper_projected * c.f
    END AS 'adj_mortality_upper_projected',
    CASE
        WHEN a.age_group = "all" THEN ''
        ELSE @mortality * d.f
    END AS 'adj_mortality_std',
    CASE
        WHEN a.age_group = "all" THEN ''
        ELSE @mortality_projected * d.f
    END AS 'adj_mortality_std_projected',
    CASE
        WHEN a.age_group = "all" THEN ''
        ELSE @mortality_lower_projected * d.f
    END AS 'adj_mortality_std_lower_projected',
    CASE
        WHEN a.age_group = "all" THEN ''
        ELSE @mortality_upper_projected * d.f
    END AS 'adj_mortality_std_upper_projected',
    is_calculated
FROM
    deaths.deaths_week_projected a
    JOIN population.imp_population b ON b.jurisdiction = a.state
    AND b.age_group = a.age_group
    AND b.year = a.year
    JOIN population.population_weights_2022 c ON a.state = c.jurisdiction
    AND a.age_group = c.age_group
    JOIN population.imp_population_std d ON a.age_group = d.age_group;

DROP TABLE IF EXISTS deaths.mortality_week;

CREATE TABLE deaths.mortality_week AS
SELECT
    a.state,
    a.year,
    a.week,
    a.age_group,
    a.deaths,
    a.deaths_covid,
    a.deaths_projected,
    a.deaths_lower_projected,
    a.deaths_upper_projected,
    a.population,
    a.mortality,
    a.mortality_projected,
    a.mortality_lower_projected,
    a.mortality_upper_projected,
    CASE
        WHEN a.age_group = "all" THEN b.adj_mortality
        ELSE a.adj_mortality
    END AS "adj_mortality",
    CASE
        WHEN a.age_group = "all" THEN b.adj_mortality_projected
        ELSE a.adj_mortality_projected
    END AS "adj_mortality_projected",
    CASE
        WHEN a.age_group = "all" THEN b.adj_mortality_lower_projected
        ELSE a.adj_mortality_lower_projected
    END AS "adj_mortality_lower_projected",
    CASE
        WHEN a.age_group = "all" THEN b.adj_mortality_upper_projected
        ELSE a.adj_mortality_upper_projected
    END AS "adj_mortality_upper_projected",
    CASE
        WHEN a.age_group = "all" THEN b.adj_mortality_std
        ELSE a.adj_mortality_std
    END AS "adj_mortality_std",
    CASE
        WHEN a.age_group = "all" THEN b.adj_mortality_std_projected
        ELSE a.adj_mortality_std_projected
    END AS "adj_mortality_std_projected",
    CASE
        WHEN a.age_group = "all" THEN b.adj_mortality_std_lower_projected
        ELSE a.adj_mortality_std_lower_projected
    END AS "adj_mortality_std_lower_projected",
    CASE
        WHEN a.age_group = "all" THEN b.adj_mortality_std_upper_projected
        ELSE a.adj_mortality_std_upper_projected
    END AS "adj_mortality_std_upper_projected",
    has_projection
FROM
    deaths.mortality_week_tmp a
    JOIN (
        SELECT
            state,
            year,
            week,
            sum(adj_mortality) AS adj_mortality,
            sum(adj_mortality_projected) AS adj_mortality_projected,
            sum(adj_mortality_lower_projected) AS adj_mortality_lower_projected,
            sum(adj_mortality_upper_projected) AS adj_mortality_upper_projected,
            sum(adj_mortality_std) AS adj_mortality_std,
            sum(adj_mortality_std_projected) AS adj_mortality_std_projected,
            sum(adj_mortality_std_lower_projected) AS adj_mortality_std_lower_projected,
            sum(adj_mortality_std_upper_projected) AS adj_mortality_std_upper_projected
        FROM
            deaths.mortality_week_tmp a
        WHERE
            age_group <> "all"
            AND is_calculated = 0
        GROUP BY
            state,
            year,
            week
    ) b ON a.state = b.state
    AND a.year = b.year
    AND a.week = b.week
ORDER BY
    state,
    year,
    week,
    age_group;

CREATE INDEX IF NOT EXISTS idx_all ON deaths.mortality_week (state, year, week, age_group);