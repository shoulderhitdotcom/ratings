using JDF
using DataFrames: DataFrame, antijoin, nrow
using StatsBase
using TableScraper
using BadukGoWeiqiTools: scrape_kifu_depot_table
using Dates
# save tbl as parquet
using Parquet2: Dataset, writefile
using Chain: @chain
using DataFrameMacros: @subset
## load the python file

existing_data = Dataset("kifu-depot-latest.parquet") |> DataFrame

# # find the date where we've definitely gone over
stop_at_date = maximum(existing_data.date)

function download_kifu_until_stop(stop_at_date)
    today_str = Dates.today()
    tmp_path = "tmp-$today_str"
    if !isdir(tmp_path)
        mkdir(tmp_path)
    end

    # download data until data is right
    found_stop_at_date = false
    i = 1
    while !found_stop_at_date
        println("downloading page $i")
        # url = "https://kifudepot.net/index.php?page=$(i)&move=&player=&event=&sort="
        tbl_to_add = scrape_kifu_depot_table(; page=i)
        JDF.save(joinpath(tmp_path, "$i.jdf"), tbl_to_add)
        println(maximum(tbl_to_add.date))
        found_stop_at_date = stop_at_date > maximum(tbl_to_add.date)
        i += 1
    end
    tmp_path
end

@time tmp_path = download_kifu_until_stop(stop_at_date)

tbls_new = mapreduce(vcat, readdir(tmp_path; join=true)) do path
    path |>
    JDF.load |>
    DataFrame
end

existing_links = existing_data.kifu_link
# remove tables already in existing_data
tmp = @chain tbls_new begin
    @subset :date >= stop_at_date
    @subset !(:kifu_link in existing_links)
end

@info "Number of accounts to add: $(nrow(tmp))"


writefile("additions-today.parquet", tmp)

