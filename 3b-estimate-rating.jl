using Parquet2: Dataset
using DataFrames: DataFrame, innerjoin, groupby, select, stack, Not, unstack, rename
using DataFrameMacros: @subset, @transform
using Chain: @chain
using GLM
using Statistics: mean
using TableScraper: scrape_tables

include("0-setup.jl")
include("utils.jl")

last_2_years = Dataset("kifu-depot-2yrs.parquet") |> DataFrame

const PLAYERS_W_ENOUGH_GAMES = @chain DataFrame(player=vcat(last_2_years.black, last_2_years.white)) begin
    groupby(:player)
    @combine(@nrow)
    @subset :nrow >= MIN_GAME_THRESHOLD
    _.player
end

const WHO_WIN_FIX = Dict("b" => "B", "w" => "W")
const KOMI_FIX = Dict(8.0 => 7.5)

last_1_years = @chain last_2_years begin
    @subset :date >= "2022-03-03"
end

const PLAYERS_W_ENOUGH_GAMES_1YR = @chain DataFrame(player=vcat(last_1_years.black, last_1_years.white)) begin
    groupby(:player)
    @combine(@nrow)
    @subset :nrow >= div(MIN_GAME_THRESHOLD, 2)
    _.player
end

bb = make_glm_data(last_1_years, PLAYERS_W_ENOUGH_GAMES_1YR)

function make_glm_data(last_2_years, PLAYERS_W_ENOUGH_GAMES)
    last_2_years1 = @chain last_2_years begin
        @subset (:black in PLAYERS_W_ENOUGH_GAMES) & (:white in PLAYERS_W_ENOUGH_GAMES)
        @transform :who_win = get(WHO_WIN_FIX, :who_win, :who_win)
        @subset :who_win in ["B", "W"]
        @transform :komi = get(KOMI_FIX, :komi, :komi)
        select(:black, :white, :komi, :who_win)
        @transform :rowid = @bycol 1:length(:black)
        # groupby([:who_win, :komi])
        # combine(nrow)
    end

    last_2_years2 = @chain last_2_years1 begin
        stack([:black, :white], [:komi, :who_win, :rowid])
        @transform :side = :variable == "black" ? 1 : -1
        select(Not(:variable))
        sort(:value)
        unstack(:rowid, :value, :side, fill=0)
    end

    last_2_years3 = @chain last_2_years1 begin
        stack([:komi], [:rowid])
        select(Not(:variable))
        @transform :val = 1
        unstack(:rowid, :value, :val, fill=0)
        innerjoin(last_2_years2, on=:rowid)

    end

    last_2_years4 = @chain last_2_years1 begin
        @transform :target = :who_win == "B"
        select(:komi, :rowid, :target)
        innerjoin(last_2_years3, on=:rowid)
        select(Not([:rowid, :komi, Symbol("0.0"), Symbol("-1.0")]))
    end

    return last_2_years4
end

using StatsModels


formula = Term(:target) ~ term(-1) + sum(Term.(Symbol.(names(last_2_years4[:, Not(:target)]))))
output = glm(formula, last_2_years4, Binomial(), LogitLink())

formula_1yr = Term(:target) ~ term(-1) + sum(Term.(Symbol.(names(bb[:, Not(:target)]))))
output_1yr = glm(formula_1yr, bb, Binomial(), LogitLink())

a = @chain DataFrame(player=coefnames(output)[3:end], strength=coef(output)[3:end]) begin
    sort(:strength, rev=true)
    @transform :rank = @bycol 1:length(:player)
end

b = @chain DataFrame(player=coefnames(output_1yr)[3:end], strength=coef(output_1yr)[3:end]) begin
    sort(:strength, rev=true)
    @transform :rank_1yr = @bycol 1:length(:player)
    rename(:strength => :strength_1yr)
    innerjoin(a, on=:player)
    sort(:rank_1yr)
    @subset :rank <= 50
    @combine(mean(:strength_1yr), mean(:strength))
end

adj = (b.strength_mean-b.strength_1yr_mean)[1]

c = @chain DataFrame(player=coefnames(output_1yr)[3:end], strength=coef(output_1yr)[3:end]) begin
    sort(:strength, rev=true)
    @transform :rank_1yr = @bycol 1:length(:player)
    rename(:strength => :strength_1yr)
    innerjoin(a, on=:player)
    sort(:rank)
    @transform :strength_1yr = :strength_1yr + adj
    @transform :Rating = :strength * 400 / log(10)
    @transform :Rating_1yr = :strength_1yr * 400 / log(10)
end


# figure out the adjustment needed for each day
sjs_ratings = scrape_tables("https://www.goratings.org/en/players/1313.html")[2] |> DataFrame
using Dates: Date
sjs_ratings = @chain sjs_ratings begin
    select(:Date, :Rating)
    @transform begin
        :rating = parse(Int, :Rating)
        :date = Date(:Date)
    end
    sort!(:Date)
    unique(:Date) # because a player can play two games in one day
end

latest_sjs_rating = parse(Int, sjs_ratings.Rating[end])

rating_adjustment = @chain c begin
    @subset :player == "申眞諝"
    latest_sjs_rating - _.Rating[1]
end

d = @chain c begin
    @transform :Rating = round(Int, :Rating + rating_adjustment)
    @transform :Rating_1yr = round(Int, :Rating_1yr + rating_adjustment)
    select(:rank, :player, :Rating, :rank_1yr, :Rating_1yr)
end

df_to_md(d, "docs/index.md")
