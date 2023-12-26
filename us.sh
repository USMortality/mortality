#!/bin/bash
set -x

if [[ $(uname) == "Darwin" ]]; then
  date() { gdate "$@"; }
fi

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

while ! [[ $start > $end ]]; do
  start=$(date -d "$start + 1 week" +%F)
  week=$(date -d $start +%Y)"_"$(date -d $start +%U)

  rm data/deaths.csv

  if wget --spider --server-response \
    "https://s3.mortality.watch/data/deaths/usa/deaths_weekly_${week}.csv" \
    2>&1 | grep "HTTP/1.1 404"; then
    echo "File for $week is missing!"
    exit 1
  else
    wget \
      "https://s3.mortality.watch/data/deaths/usa/deaths_weekly_${week}.csv" \
      -O "data/deaths.csv"
    echo "File downloaded successfully"
  fi

  import_csv deaths.csv deaths

  # Create combined table
  mysql -h 127.0.0.1 -u root deaths <queries/us/create_deaths_week.sql >"data/deaths_${week}.tsv"
done

./archive.sh

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
