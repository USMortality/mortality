DROP TABLE IF EXISTS deaths.exp_deaths_week;

CREATE TABLE deaths.exp_deaths_week AS
SELECT
    b.state,
    b.year,
    b.week,
    concat(b.year, '_', lpad(b.week, 2, 0)) AS 'year_week',
    52 * b.year + b.week -1 AS timestamp,
    b.age_group,
    deaths,
    deaths_projected,
    deaths_lower_projected,
    deaths_upper_projected,
    round(mortality_trend * b.population / 100000) AS "baseline_deaths",
    round(b.mortality_stddev * b.population / 100000) AS "baseline_deaths_stddev",
    b.population,
    deaths_covid,
    CASE
        WHEN deaths_covid = NULL THEN deaths
        ELSE deaths_projected - deaths_covid
    END AS "deaths_non_covid",
    has_projection
FROM
    deaths.mortality_week a
    RIGHT JOIN deaths.baseline b ON a.state = b.state
    AND a.year = b.year
    AND a.week = b.week
    AND a.age_group = b.age_group;

CREATE INDEX IF NOT EXISTS idx_timestamp ON deaths.exp_deaths_week (timestamp);

SELECT
    a.state,
    a.year,
    a.week,
    a.year_week,
    a.age_group,
    a.population,
    IFNULL(
        CASE
            WHEN a.has_projection = 0 THEN a.deaths
            ELSE NULL
        END,
        ''
    ) AS deaths,
    IFNULL(
        CASE
            WHEN a.has_projection = 1 THEN a.deaths
            ELSE NULL
        END,
        ''
    ) AS deaths_reported,
    IFNULL(
        CASE
            WHEN a.has_projection = 1 THEN a.deaths_projected
            WHEN a.has_projection = 0
            AND b.has_projection = 1 THEN round(a.deaths, 2)
            ELSE NULL
        END,
        ''
    ) AS deaths_projected,
    IFNULL(
        CASE
            WHEN a.has_projection = 1 THEN a.deaths_lower_projected
            WHEN a.has_projection = 0
            AND b.has_projection = 1 THEN round(a.deaths, 2)
            ELSE NULL
        END,
        ''
    ) AS deaths_lower_projected,
    IFNULL(
        CASE
            WHEN a.has_projection = 1 THEN a.deaths_upper_projected
            WHEN a.has_projection = 0
            AND b.has_projection = 1 THEN round(a.deaths, 2)
            ELSE NULL
        END,
        ''
    ) AS deaths_upper_projected,
    a.baseline_deaths,
    a.baseline_deaths - 2 * a.baseline_deaths_stddev AS "baseline_normal_lower",
    a.baseline_deaths + 2 * a.baseline_deaths_stddev AS "baseline_normal_upper",
    a.baseline_deaths + 4 * a.baseline_deaths_stddev AS "baseline_excess",
    IFNULL(a.deaths_covid, '') AS "deaths_covid",
    IFNULL(a.deaths_non_covid, '') AS "deaths_non_covid"
FROM
    deaths.exp_deaths_week a
    JOIN deaths.exp_deaths_week b ON a.state = b.state
    AND a.age_group = b.age_group
    AND a.timestamp = b.timestamp - 1
ORDER BY
    FIELD (a.state, "United States") DESC,
    state,
    FIELD(
        a.age_group,
        'all',
        '0-64',
        '0-24',
        '0-29',
        '25-44',
        '45-64',
        '65-74',
        '75-84',
        '85+',
        '65+'
    ),
    a.year,
    a.week;