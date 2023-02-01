SELECT
    state,
    year,
    week,
    year_week,
    season,
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
            concat(
                start_year + season_number,
                "/",
                start_year + season_number + 1
            ) AS "season",
            age_group,
            deaths,
            deaths_projected,
            sum(baseline_deaths) over (
                PARTITION by state,
                season_number,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_baseline_cumulative,
            sum(deaths) over (
                PARTITION by state,
                season_number,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_cumulative,
            sum(deaths_all) over (
                PARTITION by state,
                season_number,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_all_cumulative,
            sum(deaths_excess) over (
                PARTITION by state,
                season_number,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_excess_cumulative,
            sum(deaths_reported_excess) over (
                PARTITION by state,
                season_number,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS 'deaths_reported_excess_cumulative',
            sum(deaths_projected_excess) over (
                PARTITION by state,
                season_number,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_projected_excess_cumulative,
            sum(deaths_lower_projected_excess) over (
                PARTITION by state,
                season_number,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_lower_projected_excess_cumulative,
            sum(deaths_upper_projected_excess) over (
                PARTITION by state,
                season_number,
                age_group
                ORDER BY
                    state,
                    age_group,
                    year_week
            ) AS deaths_upper_projected_excess_cumulative
        FROM
            (
                SELECT
                    *,
                    (
                        SELECT
                            min(year)
                        FROM
                            deaths.deaths_excess_week
                    ) AS "start_year",
                    floor(
                        (
                            ROW_NUMBER() OVER (
                                PARTITION by state,
                                age_group
                                ORDER BY
                                    year ASC,
                                    cast(week AS integer)
                            ) - 27
                        ) / 52
                    ) 'season_number'
                FROM
                    deaths.deaths_excess_week
                WHERE
                    week <= 52
                GROUP BY
                    state,
                    age_group,
                    year,
                    week
                ORDER BY
                    state,
                    age_group,
                    year ASC,
                    cast(week AS integer)
            ) a
        WHERE
            season_number >= 0
        ORDER BY
            state,
            age_group,
            year_week
    ) a
ORDER BY
    state,
    age_group,
    year_week;