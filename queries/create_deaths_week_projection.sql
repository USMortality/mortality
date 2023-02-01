DROP TABLE IF EXISTS deaths.deaths_week_projected;

CREATE TABLE deaths.deaths_week_projected AS
SELECT
    a.state,
    a.year,
    a.week,
    a.age_group,
    deaths,
    CASE
        WHEN a.rank = b.rank THEN round(deaths_covid * mean_cum)
        ELSE deaths_covid
    END "deaths_covid",
    CASE
        WHEN a.rank = b.rank THEN round(deaths * mean_cum)
        ELSE deaths
    END deaths_projected,
    CASE
        WHEN a.rank = b.rank THEN round(deaths * lpi_cum)
        ELSE deaths
    END deaths_lower_projected,
    CASE
        WHEN a.rank = b.rank THEN round(deaths * upi_cum)
        ELSE deaths
    END deaths_upper_projected,
    CASE
        WHEN a.rank = b.rank THEN 1
        ELSE 0
    END AS 'has_projection',
    0 AS 'is_calculated'
FROM
    (
        SELECT
            state,
            year,
            week,
            age_group,
            deaths,
            deaths_covid,
            rank() over (
                PARTITION by state,
                age_group
                ORDER BY
                    year_week DESC
            ) 'rank'
        FROM
            deaths.imp_deaths
        GROUP BY
            state,
            year,
            week,
            age_group
    ) a
    LEFT JOIN archive.exp_delay_correction_mean_cum b ON a.state = b.state
    AND a.age_group = b.age_group
    AND a.rank = b.rank;

CREATE INDEX idx_state ON deaths.deaths_week_projected (state);

CREATE INDEX idx_year ON deaths.deaths_week_projected (year);

CREATE INDEX idx_week ON deaths.deaths_week_projected (week);