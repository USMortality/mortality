DROP TABLE IF EXISTS deaths.deaths_week_projected;

CREATE TABLE deaths.deaths_week_projected AS
SELECT
    state,
    year,
    week,
    age_group,
    deaths,
    deaths_covid,
    NULL AS 'deaths_projected',
    NULL AS 'deaths_lower_projected',
    NULL AS 'deaths_upper_projected',
    0 AS 'has_projection',
    0 AS 'is_calculated'
FROM
    deaths.imp_deaths;

CREATE INDEX idx_state ON deaths.deaths_week_projected (state);

CREATE INDEX idx_year ON deaths.deaths_week_projected (year);

CREATE INDEX idx_week ON deaths.deaths_week_projected (week);