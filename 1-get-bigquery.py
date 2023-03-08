import pandas as pd

from google.cloud import bigquery

print("Just before authentication")

# Construct a BigQuery client object.
client = bigquery.Client()

print("Got past authentication")

query = """
    SELECT
        *
    FROM
        `testing-of-bigquery.shoulderhit.kifu_depot_games`
    where
        date in (
            select
                max(date)
            from
                `testing-of-bigquery.shoulderhit.kifu_depot_games`
                )
"""
query_job = client.query(query)  # Make an API request.

a = query_job.to_dataframe().to_parquet('kifu-depot-latest.parquet')