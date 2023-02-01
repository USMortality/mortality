SELECT
    state,
    year,
    week,
    year_week,
    age_group,
    IFNULL(
        CASE
            WHEN mortality <> '' THEN round(
                (mortality - baseline_mortality) / baseline_mortality_stddev,
                2
            )
            ELSE NULL
        END,
        ''
    ) AS mortality_zscore,
    IFNULL(
        CASE
            WHEN mortality_reported <> '' THEN round(
                (mortality_reported - baseline_mortality) / baseline_mortality_stddev,
                3
            )
            ELSE NULL
        END,
        ''
    ) AS mortality_reported_zscore,
    IFNULL(
        CASE
            WHEN mortality_projected <> '' THEN round(
                (mortality_projected - baseline_mortality) / baseline_mortality_stddev,
                3
            )
            ELSE NULL
        END,
        ''
    ) AS mortality_projected_zscore,
    IFNULL(
        CASE
            WHEN mortality_upper_projected <> '' THEN round(
                (mortality_upper_projected - baseline_mortality) / baseline_mortality_stddev,
                3
            )
            ELSE NULL
        END,
        ''
    ) AS mortality_upper_projected_zscore,
    IFNULL(
        CASE
            WHEN mortality_lower_projected <> '' THEN round(
                (mortality_lower_projected - baseline_mortality) / baseline_mortality_stddev,
                3
            )
            ELSE NULL
        END,
        ''
    ) AS mortality_lower_projected_zscore,
    0 AS baseline_zscore,
    -2 AS baseline_zscore_normal_lower,
    2 AS baseline_zscore_normal_upper,
    4 AS baseline_zscore_excess
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