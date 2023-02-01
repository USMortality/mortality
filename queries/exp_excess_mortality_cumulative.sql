DROP TABLE IF EXISTS deaths.mortality_excess_week;

CREATE TABLE deaths.mortality_excess_week AS
SELECT
    state,
    year,
    week,
    year_week,
    age_group,
    baseline_mortality,
    mortality,
    mortality_projected,
    CASE
        WHEN mortality <> '' THEN mortality
        ELSE mortality_projected
    END AS 'mortality_all',
    CASE
        WHEN mortality <> '' THEN mortality - baseline_mortality
        ELSE ''
    END AS 'mortality_excess',
    CASE
        WHEN mortality_reported <> '' THEN mortality_reported - baseline_mortality
        ELSE mortality - baseline_mortality
    END AS 'mortality_reported_excess',
    CASE
        WHEN mortality_projected <> '' THEN mortality_projected - baseline_mortality
        ELSE mortality - baseline_mortality
    END AS 'mortality_projected_excess',
    CASE
        WHEN mortality_lower_projected <> '' THEN mortality_lower_projected - baseline_mortality
        ELSE mortality - baseline_mortality
    END AS 'mortality_lower_projected_excess',
    CASE
        WHEN mortality_upper_projected <> '' THEN mortality_upper_projected - baseline_mortality
        ELSE mortality - baseline_mortality
    END AS 'mortality_upper_projected_excess'
FROM
    (
        -- age_group=all, age-adj.std.
        SELECT
            *
        FROM
            deaths.imp_adj_mortality_std_week_s
        UNION
        ALL -- all other age groups
        SELECT
            *
        FROM
            deaths.imp_mortality_week_s
        WHERE
            age_group <> "all"
    ) a
WHERE
    (
        mortality <> ''
        OR mortality_projected <> ''
    )
ORDER BY
    state,
    year_week,
    age_group;

CREATE INDEX IF NOT EXISTS idx_all ON deaths.mortality_excess_week (state, year, week, age_group);

DROP TABLE IF EXISTS deaths.mortality_excess_cumulative_week;

CREATE TABLE deaths.mortality_excess_cumulative_week AS
SELECT
    state,
    year,
    week,
    year_week,
    age_group,
    round(mortality_baseline_cumulative, 1) AS 'mortality_baseline_cumulative',
    round(mortality_all_cumulative, 1) AS 'mortality_all_cumulative',
    CASE
        WHEN mortality <> '' THEN round(mortality_cumulative, 1)
        ELSE ''
    END AS 'mortality_cumulative',
    CASE
        WHEN mortality <> '' THEN round(mortality_excess_cumulative, 1)
        ELSE ''
    END AS 'mortality_excess_cumulative',
    CASE
        WHEN mortality_projected <> '' THEN round(mortality_reported_excess_cumulative, 1)
        ELSE ''
    END AS 'mortality_reported_excess_cumulative',
    CASE
        WHEN mortality_projected <> '' THEN round(mortality_projected_excess_cumulative, 1)
        ELSE ''
    END AS 'mortality_projected_excess_cumulative',
    CASE
        WHEN mortality_projected <> '' THEN round(
            mortality_lower_projected_excess_cumulative,
            1
        )
        ELSE ''
    END AS 'mortality_lower_projected_excess_cumulative',
    CASE
        WHEN mortality_projected <> '' THEN round(
            mortality_upper_projected_excess_cumulative,
            1
        )
        ELSE ''
    END AS 'mortality_upper_projected_excess_cumulative'
FROM
    (
        SELECT
            state,
            year,
            week,
            year_week,
            age_group,
            mortality,
            mortality_projected,
            sum(baseline_mortality) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_baseline_cumulative,
            sum(mortality) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_cumulative,
            sum(mortality_all) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_all_cumulative,
            sum(mortality_excess) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_excess_cumulative,
            sum(mortality_reported_excess) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS 'mortality_reported_excess_cumulative',
            sum(mortality_projected_excess) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_projected_excess_cumulative,
            sum(mortality_lower_projected_excess) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_lower_projected_excess_cumulative,
            sum(mortality_upper_projected_excess) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_upper_projected_excess_cumulative
        FROM
            deaths.mortality_excess_week
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
    deaths.mortality_excess_cumulative_week;