DROP VIEW IF EXISTS deaths.mortality_lreg;

CREATE VIEW deaths.mortality_lreg AS
SELECT
  state,
  age_group,
  slope,
  slope_adj,
  slope_adj_std,
  y_bar_max - x_bar_max * slope AS intercept,
  y_adj_bar_max - x_bar_max * slope_adj AS intercept_adj,
  y_adj_std_bar_max - x_bar_max * slope_adj_std AS intercept_adj_std
FROM
  (
    SELECT
      state,
      age_group,
      sum(x_bar_delta * y_bar_delta) / sum(x_bar_delta * x_bar_delta) AS slope,
      sum(x_bar_delta * y_adj_bar_delta) / sum(x_bar_delta * x_bar_delta) AS slope_adj,
      sum(x_bar_delta * y_adj_std_bar_delta) / sum(x_bar_delta * x_bar_delta) AS slope_adj_std,
      max(x_bar) AS x_bar_max,
      max(y_bar) AS y_bar_max,
      max(y_adj_bar) AS y_adj_bar_max,
      max(y_adj_std_bar) AS y_adj_std_bar_max
    FROM
      (
        SELECT
          *,
          x - x_bar AS 'x_bar_delta',
          y - y_bar AS 'y_bar_delta',
          y_adj - y_adj_bar AS 'y_adj_bar_delta',
          y_adj_std - y_adj_std_bar AS 'y_adj_std_bar_delta'
        FROM
          (
            SELECT
              state,
              age_group,
              x,
              avg(x) over (
                PARTITION by state,
                age_group
              ) AS x_bar,
              y,
              avg(y) over (
                PARTITION by state,
                age_group
              ) AS y_bar,
              y_adj,
              avg(y_adj) over (
                PARTITION by state,
                age_group
              ) AS y_adj_bar,
              y_adj_std,
              avg(y_adj_std) over (
                PARTITION by state,
                age_group
              ) AS y_adj_std_bar
            FROM
              (
                SELECT
                  state,
                  age_group,
                  year AS x,
                  sum(mortality) AS y,
                  sum(adj_mortality) AS y_adj,
                  sum(adj_mortality_std) AS y_adj_std
                FROM
                  deaths.mortality_week
                WHERE
                  year IN (
                    2010,
                    2011,
                    2012,
                    2013,
                    2014,
                    2015,
                    2016,
                    2017,
                    2018,
                    2019
                  )
                  AND week <= 52
                GROUP BY
                  state,
                  year,
                  age_group
                ORDER BY
                  state,
                  age_group,
                  year
              ) a
          ) a
      ) a
    GROUP BY
      state,
      age_group
  ) a;

DROP VIEW IF EXISTS deaths.mortality_baseline_correction;

CREATE VIEW deaths.mortality_baseline_correction AS
SELECT
  a.state,
  year,
  a.age_group,
  b.baseline / a.baseline AS baseline_correction,
  b.baseline_adj / a.baseline_adj AS baseline_correction_adj,
  b.baseline_adj_std / a.baseline_adj_std AS baseline_correction_adj_std
FROM
  (
    SELECT
      state,
      age_group,
      avg(2017 * slope + intercept) AS baseline,
      avg(2017 * slope_adj + intercept_adj) AS baseline_adj,
      avg(2017 * slope_adj_std + intercept_adj_std) AS baseline_adj_std
    FROM
      deaths.mortality_lreg
    GROUP BY
      state,
      age_group
  ) a
  JOIN (
    SELECT
      DISTINCT state,
      year,
      age_group,
      year * slope + intercept AS baseline,
      year * slope_adj + intercept_adj AS baseline_adj,
      year * slope_adj_std + intercept_adj_std AS baseline_adj_std
    FROM
      (
        SELECT
          2014 AS year
        UNION
        SELECT
          DISTINCT year
        FROM
          deaths.mortality_week
        UNION
        SELECT
          2023 AS year
      ) a
      JOIN deaths.mortality_lreg b
  ) b ON a.state = b.state
  AND a.age_group = b.age_group;

DROP TABLE IF EXISTS deaths.baseline;

-- 5y avg/trend baseline; use week 52 data for week 53
CREATE TABLE deaths.baseline AS
SELECT
  a.state,
  b.year,
  week,
  cast(b.population AS UNSIGNED) AS "population",
  a.age_group,
  mortality,
  mortality * baseline_correction AS "mortality_trend",
  mortality_stddev,
  adj_mortality,
  adj_mortality * baseline_correction_adj AS "adj_mortality_trend",
  adj_mortality_stddev,
  adj_mortality_std,
  adj_mortality_std * baseline_correction_adj_std AS "adj_mortality_std_trend",
  adj_mortality_std_stddev
FROM
  (
    SELECT
      state,
      week,
      age_group,
      avg(mortality) AS "mortality",
      stddev(mortality) AS "mortality_stddev",
      avg(adj_mortality) AS "adj_mortality",
      stddev(adj_mortality) AS "adj_mortality_stddev",
      avg(adj_mortality_std) AS "adj_mortality_std",
      stddev(adj_mortality_std) AS "adj_mortality_std_stddev"
    FROM
      deaths.mortality_week
    WHERE
      year IN (
        2010,
        2011,
        2012,
        2013,
        2014,
        2015,
        2016,
        2017,
        2018,
        2019
      )
    GROUP BY
      state,
      week,
      age_group -- UNION
      -- ALL
      -- SELECT
      --   state,
      --   53 AS week,
      --   age_group,
      --   avg(mortality) AS "mortality",
      --   stddev(mortality) AS "mortality_stddev",
      --   avg(adj_mortality) AS "adj_mortality",
      --   stddev(adj_mortality) AS "adj_mortality_stddev",
      --   avg(adj_mortality_std) AS "adj_mortality_std",
      --   stddev(adj_mortality_std) AS "adj_mortality_std_stddev"
      -- FROM
      --   deaths.mortality_week
      -- WHERE
      --   year IN (2015, 2016, 2017, 2018, 2019)
      --   AND week = 52
      -- GROUP BY
      --   state,
      --   week,
      --   age_group
  ) a
  JOIN population.imp_population b ON a.state = b.jurisdiction
  AND b.year = b.year
  AND a.age_group = b.age_group
  JOIN deaths.mortality_baseline_correction c ON a.state = c.state
  AND b.year = c.year
  AND a.age_group = c.age_group
ORDER BY
  state,
  year,
  week,
  age_group;

CREATE INDEX IF NOT EXISTS idx_all ON deaths.baseline (state, year, week, age_group);