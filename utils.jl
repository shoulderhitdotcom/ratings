function upfirstword(str)
    words = split(str, " ")
    join([uppercasefirst(w) for w in words], " ")
end



"""
    Convert DataFrame to markdown
"""
function df_to_md(df)
    print("| ")

    line = ""

    df_names = [replace(n, "_" => " ") |> upfirstword for n in names(df)]


    for n in df_names
        print("**$n**")
        print(" | ")
        line = line * "| --- "
    end
    println()
    line = line * "|"

    println(line)

    for row in eachrow(df)
        print("| ")
        for cell in row
            print(cell)
            print(" | ")
        end
        println()
    end
end

function writeln(outfile, str="")
    write(outfile, str)
    write(outfile, "\n")
end

function df_to_md(df, outfile)
    open(outfile, "w") do outfile
        write(outfile, "| ")

        line = ""
        for n in names(df)
            write(outfile, "**$n**")
            write(outfile, " | ")
            line = line * "| --- "
        end
        writeln(outfile,)
        line = line * "|"

        writeln(outfile, line)

        for row in eachrow(df)
            write(outfile, "| ")
            for cell in row
                write(outfile, string(cell))
                write(outfile, " | ")
            end
            writeln(outfile)
        end
    end

end