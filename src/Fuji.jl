module Fuji

using HttpServer

include("route.jl")
include("request.jl")

export FujiRequest, FujiServer, route!, start

type FujiServer
    routes::Array{Route,1}
end

FujiServer() = FujiServer(Route[])
log(str...) = println(str...)

function route!(action::Function, server::FujiServer, endpoint::AbstractString)
    route = Route(action, endpoint)
    push!(server.routes, route)
end

function start(server::FujiServer, host=IPv4(127, 0, 0, 1), port=8000)
    http = HttpHandler() do req, res
        timestamp = Dates.format(now(), "u d, yyyy HH:MM:SS")

        response = Response(404)

        for route in server.routes
            if ismatch(route, req)
                request = FujiRequest(route, req)
                response = Response(route.action(request))
                break
            end
        end

        log("[", timestamp, "] ", req.method, " ", req.resource, " -> ", response.status)

        response
    end

    http.events["listen"] = (saddr) -> log(" * Running on http://$saddr/ (Press CTRL+C to quit)")

    web_server = Server(http)

    try
        run(web_server, host=host, port=port)
    catch e
        if isa(e, InterruptException)
            println("Stopping server...")
        end
    end
end

end
