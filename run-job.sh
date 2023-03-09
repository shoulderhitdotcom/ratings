python3 1-get-bigquery.py

julia 2-run-job.jl

bq load \
--source_format=PARQUET \
--noreplace \
testing-of-bigquery:shoulderhit.kifu_depot_games \
additions-today.parquet

julia 2a-obtain-komi.jl

bq load \
--source_format=PARQUET \
--noreplace \
testing-of-bigquery:shoulderhit.kifu_depot_sgfs \
additions-today-w-sgf.parquet

python3 3a-extract-data-for-rating-estimation.py



mkdir docs
julia 3b-estimate-rating.jl

git clone https://$GITHUB_TOKEN@github.com/shoulderhitdotcom/ratings.git

mv docs/index.md ratings/docs/index.md

cd ratings

git config --global user.email "cloudrun@cloudrun.com"
git config --global user.name "Google Cloud Run Ratings"
git commit docs/index.md -m "updated ratings"
git push

