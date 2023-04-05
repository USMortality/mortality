#!/bin/bash

date=$(date --date="14 days ago" +"%Y")"_"$(date --date="14 days ago" +"%U")

wget "https://data.cdc.gov/api/views/y5bj-9g5w/rows.csv?accessType=DOWNLOAD" \
  -O "data/Weekly_counts_of_deaths_by_jurisdiction_and_age_group_${date}.csv"

zip -9r data/Weekly_counts_of_deaths_by_jurisdiction_and_age_group_${date}.csv.zip \
  data/Weekly_counts_of_deaths_by_jurisdiction_and_age_group_${date}.csv

mc cp data/Weekly_counts_of_deaths_by_jurisdiction_and_age_group_${date}.csv.zip \
  minio/data/deaths/usa/Weekly_counts_of_deaths_by_jurisdiction_and_age_group_${date}.csv.zip

wget "https://data.cdc.gov/api/views/muzy-jte6/rows.csv?accessType=DOWNLOAD" \
  -O "data/Weekly_counts_of_deaths_by_state_and_cause_${date}.csv"

mc cp data/Weekly_counts_of_deaths_by_state_and_cause_${date}.csv \
  minio/data/deaths/usa/Weekly_counts_of_deaths_by_state_and_cause_${date}.csv
