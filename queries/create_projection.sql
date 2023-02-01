SET
    @n = 8;

SET
    @z = 1.860;

-- -------------------------
DROP TABLE IF EXISTS archive.exp_delay_correction_mean_stddv;

CREATE TABLE archive.exp_delay_correction_mean_stddv AS
SELECT
    state,
    age_group,
    rank,
    AVG(increase) AS 'mean',
    STDDEV(increase) AS 'stddv',
    STDDEV(increase) / SQRT(@n) AS 'stderr'
FROM
    archive.diff_all
GROUP BY
    state,
    age_group,
    rank;

-- ----------------------------
DROP TABLE IF EXISTS deaths.delay_correction;

CREATE TABLE deaths.delay_correction AS
SELECT
    a.state,
    a.age_group,
    rank,
    mean,
    mean - @z * stderr AS 'lpi',
    mean + @z * stderr AS 'upi'
FROM
    (
        SELECT
            *,
            rank() over (
                PARTITION by state,
                age_group
                ORDER BY
                    rank ASC,
                    age_group ASC
            ) AS a_rank
        FROM
            archive.exp_delay_correction_mean_stddv
    ) a
WHERE
    a_rank = rank
    AND rank <= @n
ORDER BY
    state,
    age_group,
    rank DESC;

-- Calculate cumulative correction factor
DROP VIEW IF EXISTS archive.exp_delay_correction_mean_cum;

CREATE VIEW archive.exp_delay_correction_mean_cum AS
SELECT
    *
FROM
    (
        SELECT
            state,
            age_group,
            rank,
            (
                SELECT
                    EXP(SUM(LOG(mean)))
                FROM
                    deaths.delay_correction
                WHERE
                    state = a.state
                    AND age_group = a.age_group
                    AND rank >= a.rank
            ) AS mean_cum,
            (
                SELECT
                    EXP(SUM(LOG(lpi)))
                FROM
                    deaths.delay_correction
                WHERE
                    state = a.state
                    AND age_group = a.age_group
                    AND rank >= a.rank
            ) AS lpi_cum,
            (
                SELECT
                    EXP(SUM(LOG(upi)))
                FROM
                    deaths.delay_correction
                WHERE
                    state = a.state
                    AND age_group = a.age_group
                    AND rank >= a.rank
            ) AS upi_cum
        FROM
            deaths.delay_correction a
        GROUP BY
            state,
            age_group,
            rank
    ) a
WHERE
    mean_cum >= 1.025
    AND rank <= 8;