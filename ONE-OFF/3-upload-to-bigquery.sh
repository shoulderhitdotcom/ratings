# bg --location=australia-southeast2 mk \
# --table \
# --description="Kifu Depot sgfs" \
# testing-of-bigquery:shoulderhit.kifu_depot_sgfs

bq load \
--source_format=PARQUET \
shoulderhit.kifu_depot_sgfs \
./ONE-OFF/for_init_upload_to_bigquery.parquet

# testing-of-bigquery:shoulderhit.kifu_depot_games \
# additions-today.parquet