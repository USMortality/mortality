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

mysql -h 127.0.0.1 -u root deaths <queries/exp_deaths_week.sql >./out/exp_deaths_week.tsv
cat ./out/exp_deaths_week.tsv | sed -E 's/\t/,/g' >./out/deaths_week_s.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_mortality_week.sql >./out/exp_mortality_week.tsv
cat ./out/exp_mortality_week.tsv | sed -E 's/\t/,/g' >./out/mortality_week_s.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_adj_mortality_week.sql >./out/exp_adj_mortality_week.tsv
cat ./out/exp_adj_mortality_week.tsv | sed -E 's/\t/,/g' >./out/adj_mortality_week_s.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_adj_mortality_std_week.sql >./out/exp_adj_mortality_std_week.tsv
cat ./out/exp_adj_mortality_std_week.tsv | sed -E 's/\t/,/g' >./out/adj_mortality_std_week_s.csv

import_csv deaths_week_s.csv deaths
import_csv mortality_week_s.csv deaths
import_csv adj_mortality_std_week_s.csv deaths

mysql -h 127.0.0.1 -u root deaths <queries/exp_zscore_week.sql >./out/exp_zscore_week.tsv
cat ./out/exp_zscore_week.tsv | sed -E 's/\t/,/g' >./out/exp_zscore_week.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_percent_week.sql >./out/exp_excess_percent_week.tsv
cat ./out/exp_excess_percent_week.tsv | sed -E 's/\t/,/g' >./out/exp_excess_percent_week.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_deaths_cumulative.sql >./out/exp_excess_deaths_cumulative.tsv
cat ./out/exp_excess_deaths_cumulative.tsv | sed -E 's/\t/,/g' >./out/exp_excess_deaths_cumulative.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_deaths_yearly_cumulative.sql >./out/exp_excess_deaths_yearly_cumulative.tsv
cat ./out/exp_excess_deaths_yearly_cumulative.tsv | sed -E 's/\t/,/g' >./out/exp_excess_deaths_yearly_cumulative.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_deaths_seasonal_cumulative.sql >./out/exp_excess_deaths_seasonal_cumulative.tsv
cat ./out/exp_excess_deaths_seasonal_cumulative.tsv | sed -E 's/\t/,/g' >./out/exp_excess_deaths_seasonal_cumulative.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_mortality_cumulative.sql >./out/exp_excess_mortality_cumulative.tsv
cat ./out/exp_excess_mortality_cumulative.tsv | sed -E 's/\t/,/g' >./out/exp_excess_mortality_cumulative.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_mortality_percent_cumulative.sql >./out/exp_excess_mortality_percent_cumulative.tsv
cat ./out/exp_excess_mortality_percent_cumulative.tsv | sed -E 's/\t/,/g' >./out/exp_excess_mortality_percent_cumulative.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_excess_mortality_rank_week.sql >./out/exp_excess_mortality_rank_week.tsv
cat ./out/exp_excess_mortality_rank_week.tsv | sed -E 's/\t/,/g' >./out/exp_excess_mortality_rank_week.csv

mysql -h 127.0.0.1 -u root deaths <queries/exp_year_week_max.sql >./out/exp_year_week_max.tsv
cat ./out/exp_year_week_max.tsv | sed -E 's/\t/,/g' >./out/exp_year_week_max.csv

rm -rf ./out/*.tsv
