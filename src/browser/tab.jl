using Signals, MLStyle
import HTTP
using ..Protocol: Command, Event, Runtime
using Plumber


const init_script = read(joinpath(@__DIR__, "init.js"),String)
const timeout = 3

mutable struct Tab
    process
    input
    output
    id
    command_ids
    event_listeners
end

function Tab(ws_url::T; init_script=init_script) where T <: AbstractString

    input = Signal(Runtime.evaluate(init_script); strict_push = true)
    output = Signal(nothing; strict_push = true)

    process = ws_open(ws_url, input, output)
    id = split(ws_url,"/")[end]
    command_ids = Dict()
    event_listeners = Dict()
    tab = Tab(process, input, output, id, command_ids, event_listeners)

    output_listener = Signal(output) do x

        @match x begin
            Dict("id" => id, "result" => result) => begin
                tab.command_ids[id] = handle_result(result)
            end
            Dict("id" => id, "error" => e) => begin
                tab.command_ids[id] = handle_error(e)
            end
            Dict("id" => id) => begin
                print("ID:",id)
                tab.command_ids[id] = id
            end
            nothing => nothing #this for first signal
            x => "Match was unknown $x"
        end
    end
    event_listeners["output_listener"] = output_listener
    tab
end

#TODO this not type stable :/
function handle_result(x)

    @match x begin
        Dict("result" => result) => @match result begin
            Dict("value" => n, "type" => t) && if t == "number" end => n
            Dict("value" => s, "type" => t) && if t == "string" end => s
            Dict("type" => t, "objectId" => j) && if t == "object" end => JSON.parse(j)
            _ => x
        end
        #like with Network.enable
        Dict() => true
        _ => x
    end
end

function handle_error(e)
    if haskey(e,"message")
        ErrorException(e["message"])
    else
        ErrorException("unknown error")
    end
end

function (tab::Tab)(cmd::Command; timeout=timeout)

    tab.command_ids[cmd.id] = nothing
    tab.input(cmd)

    timedwait(float(timeout)) do
        !isnothing(tab.command_ids[cmd.id])
    end

    if isnothing(tab.command_ids[cmd.id])
        error("timedout")
    elseif tab.command_ids[cmd.id] isa ErrorException
        throw(tab.command_ids[cmd.id])
    else
        result = tab.command_ids[cmd.id]
        delete!(tab.command_ids, cmd.id)
        result
    end
end

function (tab::Tab)(event::Event)
    #TODO decide on behaviour in this case
    haskey(tab.event_listeners, event.name) && @warn "listener already exists"

    condition = Signal(tab.output) do x
        haskey(x,"method") && x["method"] == event.name
    end

    signal = when(condition, tab.output) do x
        event.fn(x)
    end

    tab.output
    tab.event_listeners[event.name] = (condition, signal)
    true #return something more usefull
end

function Base.delete!(tab::Tab, event::Event)
    @pipe tab.event_listeners[event.name] |>
    indexin(_ , tab.output.children) |>
    filter(!isnothing, _) |>
    deleteat!(tab.output.children, _)
    tab
end

function close(tab::Tab; timeout=timeout)
    @async Base.throwto(tab.process,InterruptException())

    taskdone = false
    timedwait(float(timeout)) do
        taskdone = istaskdone(tab.process)
        taskdone
    end

    if taskdone
        true
    else
        error("tab didn't close")
    end
end

#Should validate the url more throughly
function add_port(url, port)
    replace(url, "/devtools" => ":$port/devtools")
end


#Technically this could get the ws_url for a browser not on local host
#allowing you to control headless browsers running on multiple  machines
#this would be great for web scrcapping
function get_ws_urls(port)
    url = "http://localhost:$(port)/json/list"
    json = HTTP.get(url).body |>  String |>  JSON.parse
    filter!(x -> x["type"] == "page", json)
    map(x -> add_port(x["webSocketDebuggerUrl"], port), json)
end

function ws_open(url, input, output; timeout=timeout)

    task = @async WebSockets.open(url) do ws

        sender = Signal(input) do cmd
            write(ws, JSON.json(cmd))
        end

        while !eof(ws)
            data = readavailable(ws)
            data |> String |> JSON.parse |> output
       end
    end

    #This timeout patttern can be refactored into a macro or function
    taskstarted = false
    timedwait(float(timeout)) do
        taskstarted = istaskstarted(task)
        taskstarted
    end

    if taskstarted
        return task
    else
        error("timed out opening ws")
    end
end
