#!/bin/bash

function import_csv() {
  cd tools
  ./import_csv.sh "../data/${1}" $2
  cd ~-
}

rm -rf data/*
rm -rf out/*

# Process data
mysql -h 127.0.0.1 -u root -e \
  "SET GLOBAL collation_connection = 'utf8mb4_general_ci';"
mysql -h 127.0.0.1 -u root -e "SET GLOBAL sql_mode = '';"

wget https://s3.mortality.watch/data/population/usa/population20152021.csv \
  -O "data/population.csv"
wget https://s3.mortality.watch/data/population/usa/std_population2000.csv \
  -O "data/population_std.csv"

start=$(date -d "(date) - 10 weeks" +%F)
end=$(date -d "(date) - 3 weeks" +%F)

# Import Covid Deaths
wget https://s3.mortality.watch/data/deaths/usa/Weekly_Counts_of_Deaths_by_State_and_Select_Causes_2014-2019.csv \
  -O data/covid_deaths_2014-2019.csv

import_csv "covid_deaths_2014-2019.csv" deaths

while ! [[ $start > $end ]]; do
  start=$(date -d "$start + 1 week" +%F)
  week=$(date -d $start +%Y)"_"$(date -d $start +%U)
  echo "Week $week"

  wget https://s3.mortality.watch/data/deaths/usa/Weekly_counts_of_deaths_by_jurisdiction_and_age_group_${week}.csv.zip \
    -O data/Weekly_counts_of_deaths_by_jurisdiction_and_age_group_${week}.csv.zip
  cd data
  unzip Weekly_counts_of_deaths_by_jurisdiction_and_age_group_${week}.csv.zip
  ln -sf "Weekly_counts_of_deaths_by_jurisdiction_and_age_group_${week}.csv" "deaths.csv"
  cd ~-
  import_csv deaths.csv deaths

  # Import Latest Covid Deaths
  cd data
  wget https://s3.mortality.watch/data/deaths/usa/Weekly_counts_of_deaths_by_state_and_cause_${week}.csv \
    -O Weekly_counts_of_deaths_by_state_and_cause_${week}.csv
  ln -sf "Weekly_counts_of_deaths_by_state_and_cause_${week}.csv" "covid_deaths.csv"
  csvcut --columns=2,3,4,6,20 covid_deaths.csv >covid_deaths.csv.bak
  sed -i.bak -e 's/"COVID-19 (U071, Underlying Cause of Death)"/"covid19_u071_underlying"/g' covid_deaths.csv.bak
  mv covid_deaths.csv.bak covid_deaths.csv
  rm covid_deaths.csv.bak.bak
  cd ~-
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

./archive.sh project

cd out

zip -9 deaths_week_s.csv.zip deaths_week_s.csv
mc cp deaths_week_s.csv.zip minio/data/mortality/usa/deaths_week_s.csv.zip

zip -9 mortality_week_s.csv.zip mortality_week_s.csv
mc cp mortality_week_s.csv.zip minio/data/mortality/usa/mortality_week_s.csv.zip

zip -9 adj_mortality_week_s.csv.zip adj_mortality_week_s.csv
mc cp adj_mortality_week_s.csv.zip minio/data/mortality/usa/adj_mortality_week_s.csv.zip

zip -9 adj_mortality_std_week_s.csv.zip adj_mortality_std_week_s.csv
mc cp adj_mortality_std_week_s.csv.zip minio/data/mortality/usa/adj_mortality_std_week_s.csv.zip

zip -9 zscore_week.csv.zip zscore_week.csv
mc cp zscore_week.csv.zip minio/data/mortality/usa/zscore_week.csv.zip

zip -9 excess_percent_week.csv.zip excess_percent_week.csv
mc cp excess_percent_week.csv.zip minio/data/mortality/usa/excess_percent_week.csv.zip

zip -9 excess_deaths_cumulative.csv.zip excess_deaths_cumulative.csv
mc cp excess_deaths_cumulative.csv.zip minio/data/mortality/usa/excess_deaths_cumulative.csv.zip

zip -9 excess_deaths_yearly_cumulative.csv.zip excess_deaths_yearly_cumulative.csv
mc cp excess_deaths_yearly_cumulative.csv.zip minio/data/mortality/usa/excess_deaths_yearly_cumulative.csv.zip

zip -9 excess_deaths_seasonal_cumulative.csv.zip excess_deaths_seasonal_cumulative.csv
mc cp excess_deaths_seasonal_cumulative.csv.zip minio/data/mortality/usa/excess_deaths_seasonal_cumulative.csv.zip

zip -9 excess_mortality_cumulative.csv.zip excess_mortality_cumulative.csv
mc cp excess_mortality_cumulative.csv.zip minio/data/mortality/usa/excess_mortality_cumulative.csv.zip

zip -9 excess_mortality_percent_cumulative.csv.zip excess_mortality_percent_cumulative.csv
mc cp excess_mortality_percent_cumulative.csv.zip minio/data/mortality/usa/excess_mortality_percent_cumulative.csv.zip

zip -9 excess_mortality_rank_week.csv.zip excess_mortality_rank_week.csv
mc cp excess_mortality_rank_week.csv.zip minio/data/mortality/usa/excess_mortality_rank_week.csv.zip
