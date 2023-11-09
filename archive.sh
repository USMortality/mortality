#!/bin/bash

if [[ $(uname) == "Darwin" ]]; then
    date() { gdate "$@"; }
fi

function import_csv() {
    cd tools
    ./import_csv.sh "../data/${1}" $2
    cd ~-
}

function archive() {
    echo "Week $1"

    # Copy datasets into place for given week
    cat "./data/deaths_${1}.tsv" | sed -E 's/\t/,/g' >"./data/deaths.csv"
    rm "./data/deaths_${1}.tsv"

    # Clean, import and process dataset for given week
    mysql -h 127.0.0.1 -u root -e "DROP DATABASE IF EXISTS deaths;"
    import_csv deaths.csv deaths
    mysql -h 127.0.0.1 -u root deaths <queries/alter_year_week_type.sql

    # Archive current week
    mysql -h 127.0.0.1 -u root -e "CREATE DATABASE IF NOT EXISTS archive;"
    mysql -h 127.0.0.1 -u root -e "CREATE TABLE IF NOT EXISTS archive.deaths_weeks (ID INT PRIMARY KEY AUTO_INCREMENT, week VARCHAR(7));"
    mysql -h 127.0.0.1 -u root -e "INSERT INTO archive.deaths_weeks (week) VALUES ('$1');"
    mysql -h 127.0.0.1 -u root -e "DROP TABLE IF EXISTS archive.deaths_week_$1; CREATE TABLE archive.deaths_week_$1 AS SELECT * FROM deaths.imp_deaths;"
    mysql -h 127.0.0.1 -u root -e "CREATE INDEX idx_1 ON archive.deaths_week_$1 (state, year, week);"
    mysql -h 127.0.0.1 -u root -e "CREATE INDEX idx_2 ON archive.deaths_week_$1 (state);"
}

mysql -h 127.0.0.1 -u root -e "SET GLOBAL local_infile=1;"

if [ "$1" = "project" ]; then
    start=$(date -d "(date) - 10 weeks" +%F)
else
    start=$(date -d "(date) - 3 weeks" +%F)
fi
end=$(date -d "(date) - 3 weeks" +%F)

# Population
mysql -h 127.0.0.1 -u root -e "DROP DATABASE IF EXISTS population;"
import_csv population.csv population
import_csv population_std.csv population

# Single week
# week=$(date -d $end +%Y)"_"$(date -d $end +%U)
# archive $week

# Process death files for last n weeks
mysql -h 127.0.0.1 -u root -e "DROP DATABASE IF EXISTS archive;"
while ! [[ $start > $end ]]; do
    start=$(date -d "$start + 1 week" +%F)
    week=$(date -d $start +%Y)"_"$(date -d $start +%U)
    archive "${week}"
done

# Delay Correction
if [ "$1" = "project" ]; then
    echo "Calculating Projection"
    mysql -h 127.0.0.1 -u root deaths <queries/create_projection_proc.sql
    mysql -h 127.0.0.1 -u root deaths <queries/create_projection.sql
    mysql -h 127.0.0.1 -u root deaths <queries/create_deaths_week_projection.sql
else
    mysql -h 127.0.0.1 -u root deaths <queries/create_deaths_week_no_projection.sql
fi

mysql -h 127.0.0.1 -u root deaths <queries/create_additional_age_groups.sql

# Calculate Mortality
./export.sh
