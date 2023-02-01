SET @n = 8;

set @weeks_n = 8;

SET @z = 1.860;

DROP PROCEDURE IF EXISTS diffWeeks;

DELIMITER $$

CREATE PROCEDURE diffWeeks() BEGIN

    DECLARE counter INT DEFAULT 0;
    DECLARE counter_p INT DEFAULT 1;
    DECLARE result VARCHAR(1024) DEFAULT 'CREATE TABLE archive.diff_all AS ';

    REPEAT
        SELECT
            week INTO @week_to
        FROM
            archive.deaths_weeks
        ORDER BY
            id DESC
        LIMIT
            counter, 1;

        SELECT
            week INTO @week_from
        FROM
            archive.deaths_weeks
        ORDER BY
            id DESC
        LIMIT
            counter_p, 1;

        SET @weeks = CONCAT(@week_from, '_', @week_to);

        -- ------------------------------------------------------------
        SET
            @sql = CONCAT(
                'DROP TABLE IF EXISTS archive.diff_',
                @weeks,
                ';'
            );

        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- ------------------------------------------------------------
        SET
            @sql = CONCAT(
                'CREATE TABLE archive.diff_',
                @weeks,
                ' AS ',
                'SELECT',
                '  a.state,',
                '  a.week,',
                '  a.age_group,',
                '  b.rank,',
                '  COALESCE(a.deaths / COALESCE(b.deaths, 0), 1) AS "increase"',
                'FROM',
                '  archive.deaths_week_',
                @week_to,
                ' a',
                '  JOIN (',
                '    SELECT',
                '      *,',
                '      rank() over (',
                '        PARTITION by state,',
                '        age_group',
                '        ORDER BY',
                '          state,',
                '          year DESC,',
                '          week DESC',
                '      ) AS rank',
                '    FROM',
                '      archive.deaths_week_',
                @week_from,
                '  ) b ON a.state = b.state',
                '  AND a.year = b.year',
                '  AND a.week = b.week',
                '  AND a.age_group = b.age_group ',
                'ORDER BY',
                '  a.state,',
                '  a.year DESC,',
                '  a.week DESC,',
                '  a.age_group;'
            );

        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- ------------------------------------------------------------
        SET
            @sql = CONCAT(
                'CREATE INDEX idx_all ON archive.diff_',
                @weeks,
                ' (state, week, rank);'
            );

        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- ------------------------------------------------------------
        SET
            result = CONCAT(
                result,
                " ",
                'SELECT * FROM archive.diff_',
                @weeks,
                ' WHERE RANK <= ',
                @n,
                ' UNION ALL '
            );

        SET counter = counter + 1;
        SET counter_p = counter + 1;

    UNTIL counter = @weeks_n -1
    END REPEAT;

    -- Create final table
    SET @sql = "DROP TABLE IF EXISTS archive.diff_all;";

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @sql = CONCAT(trim(TRAILING ' UNION ALL ' FROM result), ";");

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
END $$
DELIMITER ;
-- ------------------------------------------------------------

call diffWeeks();