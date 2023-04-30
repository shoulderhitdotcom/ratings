using Pkg;
Pkg.activate(".");

using Chain: @chain
using DataFrameMacros: @subset, @transform, @combine
using DataFrames: DataFrame, innerjoin, groupby, select, stack, Not, unstack, rename, leftjoin
using Dates: Date
using GLM: glm, term, Term, Binomial, LogitLink, coefnames, coef
using Parquet2: Dataset
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

using Dates: Day
const CUT_OFF_DATE_1YR = Date(maximum(last_2_years.date)) - Day(365)

last_1_years = @chain last_2_years begin
    @subset Date(:date) >= CUT_OFF_DATE_1YR
end

const PLAYERS_W_ENOUGH_GAMES_1YR = @chain DataFrame(player=vcat(last_1_years.black, last_1_years.white)) begin
    groupby(:player)
    @combine(@nrow)
    @subset :nrow >= div(MIN_GAME_THRESHOLD, 2)
    _.player
end

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


data_for_model = make_glm_data(last_2_years, PLAYERS_W_ENOUGH_GAMES)
formula = Term(:target) ~ term(-1) + sum(Term.(Symbol.(names(data_for_model[:, Not(:target)]))))
output = glm(formula, data_for_model, Binomial(), LogitLink())

data_for_model_1yr = make_glm_data(last_1_years, PLAYERS_W_ENOUGH_GAMES_1YR)
formula_1yr = Term(:target) ~ term(-1) + sum(Term.(Symbol.(names(data_for_model_1yr[:, Not(:target)]))))
output_1yr = glm(formula_1yr, data_for_model_1yr, Binomial(), LogitLink())

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
    @subset :strength != 0 # these are usually the NA values
    @transform :rank_1yr = @bycol 1:length(:player)
    rename(:strength => :strength_1yr)
    innerjoin(a, on=:player)
    @subset :strength != 0 # these are usually the NA values
    sort(:rank)
    @transform :strength_1yr = :strength_1yr + adj
    @transform :Rating = :strength * 400 / log(10)
    @transform :Rating_1yr = :strength_1yr * 400 / log(10)
end


# figure out the adjustment needed for each day
sjs_ratings = scrape_tables("https://www.goratings.org/en/players/1313.html")[2] |> DataFrame

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

n_2yr = @chain DataFrame(player=vcat(last_2_years.black, last_2_years.white)) begin
    groupby(:player)
    @combine(:n = @nrow)
end

n_1yr = @chain DataFrame(player=vcat(last_1_years.black, last_1_years.white)) begin
    groupby(:player)
    @combine(:n_1yr = @nrow)
end

player_info = Dataset("player-info.parquet") |> DataFrame
player_names_mapping = Dataset("player_names_mapping.parquet") |> DataFrame

d = @chain c begin
    @transform :Rating = round(Int, :Rating + rating_adjustment)
    @transform :Rating_1yr = round(Int, :Rating_1yr + rating_adjustment)
    leftjoin(n_2yr, on=:player)
    leftjoin(n_1yr, on=:player)
    leftjoin(player_names_mapping, on=:player=>:name)
    @transform :english = coalesce(:english, :player)
    leftjoin(player_info, on=:english)
    select(:rank, :english=>:name, :Rating, :rank_1yr, :Rating_1yr, :n, :n_1yr, :country, :sex, :date_of_birth, :player)
    sort(:rank)
end


# trying to figure out which player has no stronger older player
# 1) only young plyers can stronger  (noows)
# 2) no one younger is stronger    (noyis)
e = @chain d begin
    @transform :date_of_birth = @passmissing Date(:date_of_birth)
    @transform :youngest = @bycol accumulate(max, :date_of_birth)
    @transform :noyis = @passmissing begin
        :date_of_birth == :youngest ? "noyis" : ""
    end
    @transform :oldest = @bycol accumulate(min, :date_of_birth)
    @transform :noows = @passmissing begin
        :date_of_birth > :oldest ? "" : "noois"
    end
    select(Not([:youngest, :oldest]))
end

df_to_md(e, "docs/index.md")


new_games = Dataset("additions-today.parquet") |> DataFrame

io = open("docs/index.md", "a")
writeln("io", "noyis = no one younger is stronger")
writeln("io", "noois = no one older is stronger")
writeln(io, "\n## Newly added games\n")
df_to_md(new_games, io)

close(io)
