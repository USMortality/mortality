SELECT
  state,
  age_group,
  left(max(year_week), 4) AS 'year_max',
  right(max(year_week), 2) AS 'week_max'
FROM
  deaths.exp_deaths_week
WHERE
  has_projection = 1
GROUP BY
  state,
  age_group;