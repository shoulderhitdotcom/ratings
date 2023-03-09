pwd

python3 1-get-bigquery.py

julia --project=.. 2-run-job.jl

bq load \
--source_format=PARQUET \
--noreplace \
testing-of-bigquery:shoulderhit.kifu_depot_games \
additions-today.parquet

julia --project=.. 2a-obtain-komi.jl

bq load \
--source_format=PARQUET \
--noreplace \
testing-of-bigquery:shoulderhit.kifu_depot_sgfs \
additions-today-w-sgf.parquet

python3 3a-extract-data-for-rating-estimation.py

julia --project=.. 3b-estimate-rating.jl

git commit docs/index.md -m "updated ratings"
git push

