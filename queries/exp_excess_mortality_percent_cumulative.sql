DROP TABLE IF EXISTS deaths.mortality_excess_cumulative_yearly_week;

CREATE TABLE deaths.mortality_excess_cumulative_yearly_week AS
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
                age_group,
                year
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_baseline_cumulative,
            sum(mortality) over (
                PARTITION by state,
                age_group,
                year
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_cumulative,
            sum(mortality_all) over (
                PARTITION by state,
                age_group,
                year
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_all_cumulative,
            sum(mortality_excess) over (
                PARTITION by state,
                age_group,
                year
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_excess_cumulative,
            sum(mortality_reported_excess) over (
                PARTITION by state,
                age_group,
                year
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS 'mortality_reported_excess_cumulative',
            sum(mortality_projected_excess) over (
                PARTITION by state,
                age_group,
                year
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_projected_excess_cumulative,
            sum(mortality_lower_projected_excess) over (
                PARTITION by state,
                age_group,
                year
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_lower_projected_excess_cumulative,
            sum(mortality_upper_projected_excess) over (
                PARTITION by state,
                age_group,
                year
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
    state,
    year,
    week,
    year_week,
    age_group,
    CASE
        WHEN mortality_excess_cumulative <> '' THEN round(
            mortality_excess_cumulative / mortality_baseline_cumulative,
            3
        )
        ELSE ''
    END AS 'mortality_excess_percent_cumulative',
    CASE
        WHEN mortality_reported_excess_cumulative <> '' THEN round(
            mortality_reported_excess_cumulative / mortality_baseline_cumulative,
            3
        )
        ELSE ''
    END AS 'mortality_reported_excess_percent_cumulative',
    CASE
        WHEN mortality_projected_excess_cumulative <> '' THEN round(
            mortality_projected_excess_cumulative / mortality_baseline_cumulative,
            3
        )
        ELSE ''
    END AS 'mortality_projected_excess_percent_cumulative',
    CASE
        WHEN mortality_lower_projected_excess_cumulative <> '' THEN round(
            mortality_lower_projected_excess_cumulative / mortality_baseline_cumulative,
            3
        )
        ELSE ''
    END AS 'mortality_lower_projected_excess_percent_cumulative',
    CASE
        WHEN mortality_upper_projected_excess_cumulative <> '' THEN round(
            mortality_upper_projected_excess_cumulative / mortality_baseline_cumulative,
            3
        )
        ELSE ''
    END AS 'mortality_upper_projected_excess_percent_cumulative'
FROM
    deaths.mortality_excess_cumulative_yearly_week a -- WHERE
    --     year >= 2020
    -- AND state = "United States"
    -- AND age_group = "all";