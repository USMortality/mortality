UPDATE
  deaths.deaths_week dest,
  (
    SELECT
      state,
      year,
      week,
      age_group,
      CASE
        WHEN age_group = "0-24" THEN CASE
          WHEN round(deaths * 0.5) <= 9 THEN round(deaths * 0.5)
          ELSE 9
        END
        ELSE CASE
          WHEN deaths >= 10 THEN 9
          ELSE deaths
        END
      END AS "deaths"
    FROM
      (
        SELECT
          a.state,
          a.year,
          a.week,
          a.age_group,
          a.factor,
          b.deaths_all_ages,
          b.deaths_diff,
          round(b.deaths_diff * a.factor) AS "deaths",
          row_number() over (
            PARTITION by a.state,
            a.year,
            a.week
            ORDER BY
              factor DESC
          ) AS row_prio
        FROM
          (
            SELECT
              a.state,
              a.year,
              a.week,
              a.age_group,
              deaths / sum_deaths AS 'factor'
            FROM
              (
                SELECT
                  a.state,
                  a.year,
                  a.week,
                  a.age_group,
                  b.deaths,
                  sum(b.deaths) over (PARTITION by a.state, a.year, a.week) AS sum_deaths
                FROM
                  (
                    SELECT
                      state,
                      year,
                      week,
                      age_group,
                      deaths
                    FROM
                      deaths.deaths_week
                    WHERE
                      age_group <> "all"
                      AND isnull(deaths) = 1
                  ) a
                  JOIN (
                    SELECT
                      year,
                      week,
                      age_group,
                      deaths
                    FROM
                      deaths.deaths_week
                    WHERE
                      state = "United States"
                      AND age_group <> "all"
                  ) b ON a.year = b.year
                  AND a.week = b.week
                  AND a.age_group = b.age_group
              ) a
          ) a
          JOIN (
            -- 1) Calculate diff
            SELECT
              a.state,
              a.year,
              a.week,
              b.deaths,
              a.deaths_all_ages,
              b.deaths - a.deaths_all_ages AS "deaths_diff"
            FROM
              (
                SELECT
                  state,
                  year,
                  week,
                  sum(deaths) AS "deaths_all_ages"
                FROM
                  deaths.deaths_week
                WHERE
                  age_group <> "all"
                GROUP BY
                  state,
                  year,
                  week
              ) a
              JOIN deaths.deaths_week b ON a.state = b.state
              AND a.year = b.year
              AND a.week = b.week
              AND b.age_group = "all"
          ) b ON a.state = b.state
          AND a.year = b.year
          AND a.week = b.week
          AND b.deaths_diff > 0
      ) a
    WHERE
      row_prio = 1
  ) src
SET
  dest.deaths = src.deaths
WHERE
  src.state = dest.state
  AND src.year = dest.year
  AND src.week = dest.week
  AND src.age_group = dest.age_group;