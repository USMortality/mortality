DROP TABLE IF EXISTS deaths.exp_mortality_week;

CREATE TABLE deaths.exp_mortality_week AS
SELECT
    b.state,
    b.year,
    b.week,
    concat(b.year, '_', lpad(b.week, 2, 0)) AS 'year_week',
    52 * b.year + b.week -1 AS timestamp,
    b.age_group,
    a.mortality,
    a.mortality_projected,
    a.mortality_lower_projected,
    a.mortality_upper_projected,
    b.mortality_trend AS "baseline_mortality",
    b.mortality_stddev AS "baseline_mortality_stddev",
    b.population,
    a.has_projection
FROM
    deaths.mortality_week a
    RIGHT JOIN deaths.baseline b ON a.state = b.state
    AND a.year = b.year
    AND a.week = b.week
    AND a.age_group = b.age_group;

CREATE INDEX IF NOT EXISTS idx_timestamp ON deaths.exp_mortality_week (timestamp);

SELECT
    a.state,
    a.year,
    a.week,
    a.year_week,
    a.age_group,
    a.population,
    IFNULL(
        CASE
            WHEN a.has_projection = 0 THEN round(a.mortality, 2)
            ELSE NULL
        END,
        ''
    ) AS mortality,
    IFNULL(
        CASE
            WHEN a.has_projection = 1 THEN round(a.mortality, 2)
            ELSE NULL
        END,
        ''
    ) AS mortality_reported,
    IFNULL(
        CASE
            WHEN a.has_projection = 1 THEN round(a.mortality_projected, 2)
            WHEN a.has_projection = 0
            AND b.has_projection = 1 THEN round(a.mortality, 2)
            ELSE NULL
        END,
        ''
    ) AS mortality_projected,
    IFNULL(
        CASE
            WHEN a.has_projection = 1 THEN round(a.mortality_lower_projected, 2)
            WHEN a.has_projection = 0
            AND b.has_projection = 1 THEN round(a.mortality, 2)
            ELSE NULL
        END,
        ''
    ) AS mortality_lower_projected,
    IFNULL(
        CASE
            WHEN a.has_projection = 1 THEN round(a.mortality_upper_projected, 2)
            WHEN a.has_projection = 0
            AND b.has_projection = 1 THEN round(a.mortality, 2)
            ELSE NULL
        END,
        ''
    ) AS mortality_upper_projected,
    round(a.baseline_mortality, 2) AS "baseline_mortality",
    round(
        a.baseline_mortality - 2 * a.baseline_mortality_stddev,
        2
    ) AS "baseline_normal_lower",
    round(
        a.baseline_mortality + 2 * a.baseline_mortality_stddev,
        2
    ) AS "baseline_normal_upper",
    round(
        a.baseline_mortality + 4 * a.baseline_mortality_stddev,
        2
    ) AS "baseline_excess",
    a.baseline_mortality_stddev
FROM
    deaths.exp_mortality_week a
    JOIN deaths.exp_mortality_week b ON a.state = b.state
    AND a.age_group = b.age_group
    AND a.timestamp = b.timestamp - 1
ORDER BY
    FIELD (a.state, "United States") DESC,
    state,
    FIELD(
        a.age_group,
        'all',
        '0-24',
        '25-44',
        '45-64',
        '65-74',
        '75-84',
        '85+'
    ),
    a.year,
    a.week;