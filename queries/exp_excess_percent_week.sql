SELECT
    state,
    year,
    week,
    year_week,
    age_group,
    IFNULL(
        CASE
            WHEN mortality <> '' THEN round(
                (mortality - baseline_mortality) / baseline_mortality,
                3
            )
            ELSE NULL
        END,
        ''
    ) AS mortality_excess_percent,
    IFNULL(
        CASE
            WHEN mortality_reported <> '' THEN round(
                (mortality_reported - baseline_mortality) / baseline_mortality,
                3
            )
            ELSE NULL
        END,
        ''
    ) AS mortality_reported_excess_percent,
    IFNULL(
        CASE
            WHEN mortality_projected <> '' THEN round(
                (mortality_projected - baseline_mortality) / baseline_mortality,
                3
            )
            ELSE NULL
        END,
        ''
    ) AS mortality_projected_excess_percent,
    IFNULL(
        CASE
            WHEN mortality_upper_projected <> '' THEN round(
                (mortality_upper_projected - baseline_mortality) / baseline_mortality,
                3
            )
            ELSE NULL
        END,
        ''
    ) AS mortality_upper_projected_excess_percent,
    IFNULL(
        CASE
            WHEN mortality_lower_projected <> '' THEN round(
                (mortality_lower_projected - baseline_mortality) / baseline_mortality,
                3
            )
            ELSE NULL
        END,
        ''
    ) AS mortality_lower_projected_excess_percent,
    0 AS baseline_excess_percent,
    round(
        -2 * baseline_mortality_stddev / baseline_mortality,
        3
    ) AS baseline_excess_percent_normal_lower,
    round(
        2 * baseline_mortality_stddev / baseline_mortality,
        3
    ) AS baseline_excess_percent_normal_upper,
    round(
        4 * baseline_mortality_stddev / baseline_mortality,
        3
    ) AS baseline_excess_percent_excess
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