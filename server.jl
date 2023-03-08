if false
    using Pkg
    Pkg.add("HTTP")

end

# print("Workding dir:")
# println(pwd())

# print("Home dir:")
# println(expanduser("~"))

# using Pkg
# # cd(expanduser("~"))
# Pkg.activate(".")

# println("Package Status:")
# println(Pkg.status())

# println("DEPOT_PATH:")
# println(DEPOT_PATH)

# println("Packages available:")
# println(readdir.(filter(DEPOT_PATH) do path
#     if isdir(path)
#         return true
#     end
#     false
# end))



# Pkg.activate(".")
# println(Pkg.status())

using HTTP

PORT = 8080
if haskey(ENV, "PORT")
    PORT = parse(Int, ENV["PORT"])
end

println("Listening on port $PORT")

server = HTTP.serve("0.0.0.0", PORT) do request::HTTP.Request
    print("got a request")
    @show request
    @show request.method
    @show HTTP.header(request, "Content-Type")
    @show request.body
    try
        return HTTP.Response("Hello")
    catch e
        return HTTP.Response(400, "Error: $e")
    end
end

#close(server)
