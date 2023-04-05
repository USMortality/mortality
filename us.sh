#!/bin/bash
[[ $OSTYPE == 'darwin'* ]] && alias date=gdate

function import_csv() {
  cd tools
  ./import_csv.sh "../data/${1}" $2
  cd ~-
}

# Update Data
date=$(date --date="14 days ago" +"%Y")"_"$(date --date="14 days ago" +"%U")
wget "https://data.cdc.gov/api/views/y5bj-9g5w/rows.csv?accessType=DOWNLOAD" \
  -O "data/us/Weekly_counts_of_deaths_by_jurisdiction_and_age_group_${date}.csv"

wget "https://data.cdc.gov/api/views/muzy-jte6/rows.csv?accessType=DOWNLOAD" \
  -O "data/us/Weekly_counts_of_deaths_by_state_and_cause_${date}.csv"

# Process data
mysql -h 127.0.0.1 -u root -e \
  "SET GLOBAL collation_connection = 'utf8mb4_general_ci';"
mysql -h 127.0.0.1 -u root -e "SET GLOBAL sql_mode = '';"

ln -sf "us/population20152021.csv" "data/population.csv"
ln -sf "us/std_population2000.csv" "data/population_std.csv"

start=$(date -d "(date) - 10 weeks" +%F)
end=$(date -d "(date) - 3 weeks" +%F)

# Import Covid Deaths
ln -sf "us/Weekly_Counts_of_Deaths_by_State_and_Select_Causes_2014-2019.csv" "data/covid_deaths_2014-2019.csv"
import_csv "covid_deaths_2014-2019.csv" deaths

while ! [[ $start > $end ]]; do
  start=$(date -d "$start + 1 week" +%F)
  week=$(date -d $start +%Y)"_"$(date -d $start +%U)
  echo "Week $week"

  ln -sf "us/Weekly_counts_of_deaths_by_jurisdiction_and_age_group_${week}.csv" "data/deaths.csv"
  import_csv deaths.csv deaths

  # Import Latest Covid Deaths
  ln -sf "us/Weekly_counts_of_deaths_by_state_and_cause_${week}.csv" "data/covid_deaths.csv"
  csvcut --columns=2,3,4,6,20 data/covid_deaths.csv >data/covid_deaths.csv.bak
  sed -i.bak -e 's/"COVID-19 (U071, Underlying Cause of Death)"/"covid19_u071_underlying"/g' data/covid_deaths.csv.bak
  mv data/covid_deaths.csv.bak data/covid_deaths.csv
  rm data/covid_deaths.csv.bak.bak
  import_csv covid_deaths.csv deaths

  # Create combined table
  mysql -h 127.0.0.1 -u root deaths <queries/us/create_all_cause_covid_week.sql
  mysql -h 127.0.0.1 -u root deaths <queries/us/create_deaths_week.sql

  # Impute missing deaths, 6x for potentially all age groups.
  mysql -h 127.0.0.1 -u root deaths <queries/us/impute_missing_deaths.sql
  mysql -h 127.0.0.1 -u root deaths <queries/us/impute_missing_deaths.sql
  mysql -h 127.0.0.1 -u root deaths <queries/us/impute_missing_deaths.sql
  mysql -h 127.0.0.1 -u root deaths <queries/us/impute_missing_deaths.sql
  mysql -h 127.0.0.1 -u root deaths <queries/us/impute_missing_deaths.sql
  mysql -h 127.0.0.1 -u root deaths <queries/us/impute_missing_deaths.sql

  mysql -h 127.0.0.1 -u root -e "UPDATE deaths.deaths_week SET deaths = 0 WHERE isNull(deaths) = 1;"
  mysql -h 127.0.0.1 -u root -e "SELECT * FROM deaths.deaths_week ORDER BY state, age_group, year, week;" >"data/deaths_${week}.tsv"
done

rm data/covid_deaths_2014-2019.csv
rm data/covid_deaths.csv
rm data/deaths.csv

./archive.sh project
