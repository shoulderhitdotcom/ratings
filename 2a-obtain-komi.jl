using Pkg; Pkg.activate(".");
# using JDF, DataFrames, DataFrameMacros, TableScraper, Chain
using Parquet2: Dataset
using DataFrames: DataFrame, nrow, select
using BadukGoWeiqiTools: extract_sgf, komi
using Chain: @chain
using Parquet2: writefile
# using Missings: disallowmissing
# using StatsBase

# at this point it is assumed that the new data of games has been submitted to bigquery
# so all I need to do now is to extract the games without sgfs and submit to the table

# to save time, let's assume the file that is downloaded contains all the kifu that we need to extract

tbl = Dataset("additions-today.parquet") |> DataFrame

# @time tbl_wo_sgf = JDF.load("kifu-depot-games.jdf") |> DataFrame |> unique
# @time tbl_w_sgf = JDF.load("kifu-depot-games-with-sgf.jdf") |> DataFrame |> unique

# tbl = @chain tbl_wo_sgf begin
#     leftjoin(select(tbl_w_sgf, [:comp, :kifu_link, :sgf, :komi]), on=[:comp, :kifu_link])
#     @transform :sgf = @bycol disallowmissing(coalesce.(:sgf, Ref("")))
#     @transform :komi = @bycol disallowmissing(coalesce.(:komi, -1.0))
#     unique
#     sort(:date, rev=true)
# end

# if false
#     tbl = tbl_wo_sgf
#     tbl[!, :sgf] .= ""
#     tbl[!, :komi] .= float(-1)
#     tbl = sort!(tbl, :date, rev=true)
# end

# @assert nrow(tbl) == nrow(tbl_wo_sgf)

# missing_kifu_rows = findall(tbl.sgf .== "")
# ndone = sum(tbl.sgf .!= "")

const KOMI_FIX = Dict(
    "65집" => "6.5",
    "750" => "7.5",
    "6.4" => "6.5",
    "5.4" => "5.5",
    "8点" => "8",
    "605" => "6.5",
    "7.50" => "7.5",
    "6.50" => "6.5",
)

# create a new column to store the sgf
tbl.sgf .= ""
tbl.komi .= -1.0


# row = missing_kifu_rows[1]
# extract sgd and add komi
for row in 1:nrow(tbl)
    # global ndone
    link = tbl[row, :kifu_link]
    try
        tbl[row, :sgf] = extract_sgf(link)
    catch e
        println("error at $row")
        tbl[row, :sgf] = "error"
        println(e)
    end

    try
        extracted_komi = komi(tbl[row, :sgf])
        extracted_komi = get(KOMI_FIX, extracted_komi, extracted_komi)
        tbl[row, :komi] = parse(Float64, extracted_komi)
    catch e
        println("error at $row")
        # println("failed to convert $extracted_komi to `Float64`")
        println(e)
    end
end

tbl_sgf = @chain tbl begin
    select(:date, :kifu_link, :sgf, :komi)
end

writefile("additions-today-w-sgf.parquet", tbl_sgf)


# using BadukGoWeiqiTools: komi
# @time tbl = @chain tbl begin
#     @transform :komi = komi(:sgf)
# end

# @time tbl = @chain tbl begin
#     @transform :komi = get(komi_fix, :komi, :komi)
# end

# countmap(tbl.komi)

# JDF.save("kifu-depot-games-with-sgf.jdf", tbl)


##################################
# upload to bitio
##################################

# if false
#     const PWD = String(read("credentials.txt"))

#     tbl = JDF.load("kifu-depot-games-with-sgf.jdf") |> DataFrame

#     sgf_tbl = @chain tbl begin
#         select([:kifu_link, :sgf])
#     end

#     tbl_for_bitio = @chain tbl begin
#         select(Not(:sgf))
#     end

#     # eltype.(eachcol(tbl_for_bitio))

#     using LibPQ, Tables, CSV
#     using TableIO

#     conn = LibPQ.Connection("postgresql://xiaodai_demo_db_connection:$PWD@db.bit.io")

#     # only need to be run once to build table

#     cols = join(["$name   text" for name in names(tbl_for_bitio)], ",\n")

#     result = execute(
#         conn,
#         """
#     CREATE TABLE if not exists "xiaodai/baduk-go-weiqi"."kifu_depot_games_v1" (
#         $cols
#     );
# """
#     )

#     TableIO.write_table!(conn, "\"xiaodai/baduk-go-weiqi\".kifu_depot_games_v1", tbl_for_bitio)



#     cols = join(["$name   text" for name in names(sgf_tbl)], ",\n")

#     result = execute(
#         conn,
#         """
#     CREATE TABLE if not exists "xiaodai/baduk-go-weiqi"."kifu_depot_sgfs" (
#         $cols
#     );
# """
#     )

#     # result = execute(conn, "SET statement_timeout $(1000*120)")

#     TableIO.write_table!(conn, "\"xiaodai/baduk-go-weiqi\".kifu_depot_sgfs", sgf_tbl[1:10_000, :])

#     close(conn)
# end
