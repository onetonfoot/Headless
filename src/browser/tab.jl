using Signals, MLStyle
import HTTP
using ..Protocol: Command, Event, Runtime, Page
using Plumber

#TODO tab should be its own module

const init_script = read(joinpath(@__DIR__, "init.js"),String)
const timeout = 3

#This doesn't work becasuse can't throw a error from inside timedwait! tescb
function timederror(testcb::Function, error::Exception, secs::Number; pollint=0.1)
    result = timedwait(testcb, float(secs); pollint=pollint)
    result != :ok && throw(error)
    true
end

mutable struct Tab
    process
    input
    output
    id
    command_ids
    event_listeners
end

function Tab(ws_url::T; init_script=init_script) where T <: AbstractString

    #will need to change this method name
    init_cmd = Page.add_script_to_evaluate_on_new_document(init_script)
    input = Signal(init_cmd; strict_push = true)
    output = Signal(nothing; strict_push = true)

    process = ws_open(ws_url, input, output)
    id = split(ws_url,"/")[end]
    command_ids = Dict()
    event_listeners = Dict()
    tab = Tab(process, input, output, id, command_ids, event_listeners)


    output_listener = Signal(output) do x
        @match x begin
            Dict("id" => id, "error" => e) => begin
                tab.command_ids[id] = handle_error(e)
            end
            Dict("id" => id, "result" => result) => begin
                tab.command_ids[id] = handle_result(result)
            end
            nothing => nothing #this for first signal
            x => "Match was unknown $x"
        end
    end
    init_cmd |> input
    event_listeners["output_listener"] = output_listener
    tab
end

function handle_result(x)
    @match x begin
        Dict("exceptionDetails" => details) => begin
            #TODO create a proper error hierachy
            ErrorException(details["exception"]["description"])
        end
        Dict("result" => result) => @match result begin
            Dict("value" => n, "type" => t) && if t == "number" end => n
            Dict("value" => s, "type" => t) && if t == "string" end => s

            #Unsure with this case
            Dict("type" => t, "objectId" => j) && if t == "object" end => JSON.parse(j)
            _ => x
        end
        #like with Network.enable
        x && if x == Dict() end => true
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

    if istaskdone(tab.process)
        error("tab closed")
    end

    while !isnothing(cmd.prev)
        cmd = cmd.prev
    end

    while true
        tab.command_ids[cmd.id] = nothing
        tab.input(cmd)
        result = nothing
        t = timedwait(float(timeout)) do
            result = tab.command_ids[cmd.id]
            !isnothing(result)
        end

        if t == :timed_out
            error("timedout")
        elseif result isa ErrorException
            throw(result)
        end

        delete!(tab.command_ids, cmd.id)
        if isnothing(cmd.next)
            return result
        else
            cmd = cmd.next
        end
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
    err = ErrorException("tab didn't close")
    timederror(err, timeout) do
        istaskdone(tab.process)
    end
    true
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

    err = ErrorException("timed out opening ws")
    timederror(err, timeout) do
        istaskstarted(task)
    end
    task
end
