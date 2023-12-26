#!/bin/bash

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
wget https://s3.mortality.watch/data/population/deu/Einwohner.csv \
  -O data/einwohner.csv
import_csv einwohner.csv population
mysql -h 127.0.0.1 -u root population <queries/de/create_population.sql >"data/population.tsv"
rm ./data/population.csv
cat ./data/population.tsv | sed -E 's/\t/,/g' >./data/population.csv
rm data/population.tsv data/einwohner.csv

wget https://s3.mortality.watch/data/population/esp2013.csv \
  -O "data/population_std.csv"

start=$(date -d "(date) - 10 weeks" +%F)
end=$(date -d "(date) - 3 weeks" +%F)

while ! [[ $start > $end ]]; do
  start=$(date -d "$start + 1 week" +%F)
  week=$(date -d $start +%Y)"_"$(date -d $start +%U)

  rm data/deaths.csv

  if wget --spider --server-response \
    "https://s3.mortality.watch/data/deaths/deu/Tote_${week}.csv" \
    2>&1 | grep "HTTP/1.1 404"; then
    echo "File for $week is missing!"
    exit 1
  else
    wget \
      "https://s3.mortality.watch/data/deaths/deu/Tote_${week}.csv" \
      -O "data/deaths.csv"
    echo "File downloaded successfully"
  fi

  import_csv deaths.csv deaths

  # Create combined table
  mysql -h 127.0.0.1 -u root deaths <queries/de/create_deaths_week.sql >"data/deaths_${week}.tsv"
done

./archive.sh

mc cp out/deaths_week_s.csv minio/data/mortality/deu/deaths_week_s.csv
mc cp out/mortality_week_s.csv minio/data/mortality/deu/mortality_week_s.csv
mc cp out/adj_mortality_week_s.csv minio/data/mortality/deu/adj_mortality_week_s.csv
mc cp out/adj_mortality_std_week_s.csv minio/data/mortality/deu/adj_mortality_std_week_s.csv
mc cp out/zscore_week.csv minio/data/mortality/deu/zscore_week.csv
mc cp out/excess_percent_week.csv minio/data/mortality/deu/excess_percent_week.csv
mc cp out/excess_deaths_cumulative.csv minio/data/mortality/deu/excess_deaths_cumulative.csv
mc cp out/excess_deaths_yearly_cumulative.csv minio/data/mortality/deu/excess_deaths_yearly_cumulative.csv
mc cp out/excess_deaths_seasonal_cumulative.csv minio/data/mortality/deu/excess_deaths_seasonal_cumulative.csv
mc cp out/excess_mortality_cumulative.csv minio/data/mortality/deu/excess_mortality_cumulative.csv
mc cp out/excess_mortality_percent_cumulative.csv minio/data/mortality/deu/excess_mortality_percent_cumulative.csv
mc cp out/excess_mortality_rank_week.csv minio/data/mortality/deu/excess_mortality_rank_week.csv
