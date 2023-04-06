#!/bin/bash

function import_csv() {
    cd tools
    ./import_csv.sh "../out/${1}" $2
    cd ~-
}

rm -rf out/*

mysql -h 127.0.0.1 -u root -e \
    "SET GLOBAL collation_connection = 'utf8mb4_general_ci';"
mysql -h 127.0.0.1 -u root -e "SET GLOBAL sql_mode = '';"

mysql -h 127.0.0.1 -u root deaths <queries/create_mortality_week.sql
mysql -h 127.0.0.1 -u root deaths <queries/create_mortality_baseline.sql

mysql -h 127.0.0.1 -u root deaths <queries/exp_deaths_week.sql >./out/deaths_week.tsv
cat ./out/deaths_week.tsv | sed -E 's/\t/,/g' >./out/deaths_week_s.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_mortality_week.sql >./out/mortality_week.tsv
cat ./out/mortality_week.tsv | sed -E 's/\t/,/g' >./out/mortality_week_s.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_adj_mortality_week.sql >./out/adj_mortality_week.tsv
cat ./out/adj_mortality_week.tsv | sed -E 's/\t/,/g' >./out/adj_mortality_week_s.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_adj_mortality_std_week.sql >./out/adj_mortality_std_week.tsv
cat ./out/adj_mortality_std_week.tsv | sed -E 's/\t/,/g' >./out/adj_mortality_std_week_s.csv

import_csv deaths_week_s.csv deaths
import_csv mortality_week_s.csv deaths
import_csv adj_mortality_std_week_s.csv deaths

mysql -h 127.0.0.1 -u root deaths <queries/exp_zscore_week.sql >./out/zscore_week.tsv
cat ./out/zscore_week.tsv | sed -E 's/\t/,/g' >./out/zscore_week.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_percent_week.sql >./out/excess_percent_week.tsv
cat ./out/excess_percent_week.tsv | sed -E 's/\t/,/g' >./out/excess_percent_week.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_deaths_cumulative.sql >./out/excess_deaths_cumulative.tsv
cat ./out/excess_deaths_cumulative.tsv | sed -E 's/\t/,/g' >./out/excess_deaths_cumulative.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_deaths_yearly_cumulative.sql >./out/excess_deaths_yearly_cumulative.tsv
cat ./out/excess_deaths_yearly_cumulative.tsv | sed -E 's/\t/,/g' >./out/excess_deaths_yearly_cumulative.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_deaths_seasonal_cumulative.sql >./out/excess_deaths_seasonal_cumulative.tsv
cat ./out/excess_deaths_seasonal_cumulative.tsv | sed -E 's/\t/,/g' >./out/excess_deaths_seasonal_cumulative.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_mortality_cumulative.sql >./out/excess_mortality_cumulative.tsv
cat ./out/excess_mortality_cumulative.tsv | sed -E 's/\t/,/g' >./out/excess_mortality_cumulative.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_mortality_percent_cumulative.sql >./out/excess_mortality_percent_cumulative.tsv
cat ./out/excess_mortality_percent_cumulative.tsv | sed -E 's/\t/,/g' >./out/excess_mortality_percent_cumulative.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_mortality_rank_week.sql >./out/excess_mortality_rank_week.tsv
cat ./out/excess_mortality_rank_week.tsv | sed -E 's/\t/,/g' >./out/excess_mortality_rank_week.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_year_week_max.sql >./out/_year_week_max.tsv
cat ./out/_year_week_max.tsv | sed -E 's/\t/,/g' >./out/year_week_max.csv

rm -rf ./out/*.tsv
