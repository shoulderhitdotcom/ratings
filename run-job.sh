python3 1-get-bigquery.py

julia 2-run-job.jl

julia 2a-obtain-komi.jl

python3 3a-extract-data-for-rating-estimation.py

julia 3b-estimate-rating.jl

git clone --depth=1 https://$GITHUB_TOKEN@github.com/shoulderhitdotcom/ratings.git

mv docs/index.md ratings/docs/index.md

cd ratings

git push

# bq load \
# --source_format=PARQUET \
# --noreplace \
# testing-of-bigquery:shoulderhit.kifu_depot_games \
# additions-today.parquet
