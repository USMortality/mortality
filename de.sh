#!/bin/bash

function import_csv() {
  cd tools
  ./import_csv.sh "../data/${1}" $2
  cd ~-
}

# Download latest data
start=$(gdate -d "(date) - 2 weeks" +%F)
week=$(gdate -d $start +%Y)"_"$(gdate -d $start +%U)
wget https://s3.mortality.watch/data/mortality/deu/deaths.csv \
  -O data/de/Tote_${week}.csv

# Process data
ln -sf "de/Einwohner.csv" "data/einwohner.csv"
import_csv einwohner.csv population
mysql -h 127.0.0.1 -u root population <queries/de/create_population.sql >"data/population.tsv"
rm ./data/population.csv
cat ./data/population.tsv | sed -E 's/\t/,/g' >./data/population.csv
rm data/population.tsv data/einwohner.csv

ln -sf "de/esp2013.csv" "data/population_std.csv"

start=$(gdate -d "(date) - 10 weeks" +%F)
end=$(gdate -d "(date) - 3 weeks" +%F)

while ! [[ $start > $end ]]; do
  start=$(gdate -d "$start + 1 week" +%F)
  week=$(gdate -d $start +%Y)"_"$(gdate -d $start +%U)

  ln -sf "de/Tote_${week}.csv" "data/deaths.csv"
  import_csv deaths.csv deaths

  # Create combined table
  mysql -h 127.0.0.1 -u root deaths <queries/de/create_deaths_week.sql >"data/deaths_${week}.tsv"
done

rm data/deaths.csv

./archive.sh

mc cp ../mortality/out/deaths_week_s.csv minio/data/mortality/deu/deaths_week_s.csv
mc cp ../mortality/out/mortality_week_s.csv minio/data/mortality/deu/mortality_week_s.csv
mc cp ../mortality/out/adj_mortality_week_s.csv minio/data/mortality/deu/adj_mortality_week_s.csv
mc cp ../mortality/out/adj_mortality_std_week_s.csv minio/data/mortality/deu/adj_mortality_std_week_s.csv
mc cp ../mortality/out/exp_zscore_week.csv minio/data/mortality/deu/zscore_week.csv
mc cp ../mortality/out/exp_excess_percent_week.csv minio/data/mortality/deu/excess_percent_week.csv
mc cp ../mortality/out/exp_excess_deaths_cumulative.csv minio/data/mortality/deu/excess_deaths_cumulative.csv
mc cp ../mortality/out/exp_excess_deaths_yearly_cumulative.csv minio/data/mortality/deu/excess_deaths_yearly_cumulative.csv
mc cp ../mortality/out/exp_excess_deaths_seasonal_cumulative.csv minio/data/mortality/deu/excess_deaths_seasonal_cumulative.csv
mc cp ../mortality/out/exp_excess_mortality_cumulative.csv minio/data/mortality/deu/excess_mortality_cumulative.csv
mc cp ../mortality/out/exp_excess_mortality_percent_cumulative.csv minio/data/mortality/deu/excess_mortality_percent_cumulative.csv
mc cp ../mortality/out/exp_excess_mortality_rank_week.csv minio/data/mortality/deu/excess_mortality_rank_week.csv
