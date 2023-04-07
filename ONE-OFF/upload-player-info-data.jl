using BadukGoWeiqiTools: create_player_info_tbl, load_namesdb;
using DataFrames: DataFrame, leftjoin
using Chain: @chain

const NAMESDB = load_namesdb()

tbl = create_player_info_tbl()

using Parquet2: writefile

namestbl = @chain DataFrame(
    name=keys(NAMESDB) |> collect,
    english=values(NAMESDB) |> collect) begin
    leftjoin(tbl, on=:english => :name)
end

writefile("ONE-OFF/player_info.parquet", namestbl)