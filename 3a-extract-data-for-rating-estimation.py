import pandas as pd

from google.cloud import bigquery

print("Just before authentication")

# Construct a BigQuery client object.
client = bigquery.Client()

print("Got past authentication")

query = """
    SELECT
        a.*,
        b.komi
    FROM
        `testing-of-bigquery.shoulderhit.kifu_depot_games` as a
        left join
        `testing-of-bigquery.shoulderhit.kifu_depot_sgfs` as b
    on
        a.date = b.date and a.kifu_link = b.kifu_link
    where
        a.date >= (
            select
                cast(date_sub(cast(max(date) as date), interval 365*2-1 DAY) as string format 'YYYY-MM-DD')
            from
                `testing-of-bigquery.shoulderhit.kifu_depot_games`
                )
"""
query_job = client.query(query)  # Make an API request.

# this data will be used to calculate the ratings
tmp = query_job.to_dataframe()
tmp.to_parquet('kifu-depot-2yrs.parquet')
