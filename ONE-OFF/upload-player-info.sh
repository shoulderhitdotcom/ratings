bq load \
--source_format=PARQUET \
--replace \
testing-of-bigquery:shoulderhit.player_info \
player_info.parquet

