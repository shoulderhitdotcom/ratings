using Pkg;

const PKG_LIST = ["JDF",
    "DataFrames",
    "StatsBase",
    "TableScraper",
    "BadukGoWeiqiTools",
    "Dates", "Parquet2", "PackageCompiler", "Chain", "DataFrameMacros"]

Pkg.add(PKG_LIST)

println("Working directory is $(pwd())")


using JDF
using DataFrames
using StatsBase
using TableScraper
using BadukGoWeiqiTools: scrape_kifu_depot_table
using Dates
# save tbl as parquet
using Parquet2

# using PackageCompiler
# create_sysimage(PKG_LIST; sysimage_path="test.so")