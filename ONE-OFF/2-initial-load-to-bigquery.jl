using JDF, DataFrames, DataFrameMacros, Chain

using Parquet2: writefile

@time tbl_w_sgf = JDF.load("/mnt/c/weiqi/web-scraping/kifu-depot-games-with-sgf.jdf") |> DataFrame |> unique

for_upload_to_bigquery = @chain tbl_w_sgf begin
    select(:date, :kifu_link, :sgf, :komi)
end

writefile("ONE-OFF/for_init_upload_to_bigquery.parquet", for_upload_to_bigquery)