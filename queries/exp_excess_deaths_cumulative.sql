DROP TABLE IF EXISTS deaths.deaths_excess_week;

CREATE TABLE deaths.deaths_excess_week AS
SELECT
    state,
    year,
    week,
    year_week,
    age_group,
    baseline_deaths,
    deaths,
    deaths_projected,
    CASE
        WHEN deaths <> '' THEN deaths
        ELSE deaths_projected
    END AS 'deaths_all',
    CASE
        WHEN deaths <> '' THEN deaths - baseline_deaths
        ELSE ''
    END AS 'deaths_excess',
    CASE
        WHEN deaths_reported <> '' THEN deaths_reported - baseline_deaths
        ELSE deaths - baseline_deaths
    END AS 'deaths_reported_excess',
    CASE
        WHEN deaths_projected <> '' THEN deaths_projected - baseline_deaths
        ELSE deaths - baseline_deaths
    END AS 'deaths_projected_excess',
    CASE
        WHEN deaths_lower_projected <> '' THEN deaths_lower_projected - baseline_deaths
        ELSE deaths - baseline_deaths
    END AS 'deaths_lower_projected_excess',
    CASE
        WHEN deaths_upper_projected <> '' THEN deaths_upper_projected - baseline_deaths
        ELSE deaths - baseline_deaths
    END AS 'deaths_upper_projected_excess'
FROM
    deaths.imp_deaths_week_s
WHERE
    (
        deaths <> ''
        OR deaths_projected <> ''
    )
ORDER BY
    state,
    year_week,
    age_group;

CREATE INDEX IF NOT EXISTS idx_all ON deaths.deaths_excess_week (state, year, week, age_group);

DROP TABLE IF EXISTS deaths.deaths_excess_cumulative_week;

CREATE TABLE deaths.deaths_excess_cumulative_week AS
SELECT
    state,
    year,
    week,
    year_week,
    age_group,
    round(deaths_baseline_cumulative) AS 'deaths_baseline_cumulative',
    round(deaths_all_cumulative) AS 'deaths_all_cumulative',
    CASE
        WHEN deaths <> '' THEN round(deaths_cumulative)
        ELSE ''
    END AS 'deaths_cumulative',
    CASE
        WHEN deaths <> '' THEN round(deaths_excess_cumulative)
        ELSE ''
    END AS 'deaths_excess_cumulative',
    CASE
        WHEN deaths_projected <> '' THEN round(deaths_reported_excess_cumulative)
        ELSE ''
    END AS 'deaths_reported_excess_cumulative',
    CASE
        WHEN deaths_projected <> '' THEN round(deaths_projected_excess_cumulative)
        ELSE ''
    END AS 'deaths_projected_excess_cumulative',
    CASE
        WHEN deaths_projected <> '' THEN round(
            deaths_lower_projected_excess_cumulative
        )
        ELSE ''
    END AS 'deaths_lower_projected_excess_cumulative',
    CASE
        WHEN deaths_projected <> '' THEN round(
            deaths_upper_projected_excess_cumulative
        )
        ELSE ''
    END AS 'deaths_upper_projected_excess_cumulative'
FROM
    (
        SELECT
            state,
            year,
            week,
            year_week,
            age_group,
            deaths,
            deaths_projected,
            sum(baseline_deaths) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_baseline_cumulative,
            sum(deaths) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_cumulative,
            sum(deaths_all) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_all_cumulative,
            sum(deaths_excess) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_excess_cumulative,
            sum(deaths_reported_excess) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS 'deaths_reported_excess_cumulative',
            sum(deaths_projected_excess) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_projected_excess_cumulative,
            sum(deaths_lower_projected_excess) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_lower_projected_excess_cumulative,
            sum(deaths_upper_projected_excess) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_upper_projected_excess_cumulative
        FROM
            deaths.deaths_excess_week
        ORDER BY
            state,
            age_group,
            year_week
    ) a
ORDER BY
    state,
    age_group,
    year_week;

SELECT
    *
FROM
    deaths.deaths_excess_cumulative_week;