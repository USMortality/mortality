SELECT
    state,
    year,
    week,
    year_week,
    age_group,
    round(
        mortality_cumulative - mortality_baseline_cumulative
    ) AS 'excess_mortality',
    round(
        mortality_cumulative / mortality_baseline_cumulative -1,
        3
    ) AS 'excess_percent'
FROM
    (
        SELECT
            state,
            year,
            week,
            year_week,
            age_group,
            sum(baseline_mortality) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_baseline_cumulative,
            sum(mortality_all) over (
                PARTITION by state,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS mortality_cumulative
        FROM
            deaths.mortality_excess_week
        WHERE
            year >= 2021
            OR (
                year >= 2020
                AND week >= 11
            )
    ) a
ORDER BY
    state,
    age_group,
    year_week;