using Signals, MLStyle
import HTTP

#input should be a typed signal of only Commands
mutable struct Tab
    process
    input
    output
    id
    command_ids
end

function Tab(ws_url::T) where T <: AbstractString
    #input should be some kind of init script
    input = Signal(nothing)
    output = Signal(nothing)

    process = ws_open(ws_url, input, output)
    id = split(ws_url,"/")[end]
    command_ids = Dict()
    tab = Tab(process, input, output, id, command_ids)

    #this logic should be in its own function
    #but it needs a reference to the tab

    Signal(output) do x
        @match x begin
            Dict("id" => id, "result" => result) => begin
                tab.command_ids[id] = unpack_result(result)
            end
            nothing => nothing #this for first signal
            x => "Match was unknown $x"
        end
    end
    tab
end

#TODO this not type stable :/
function unpack_result(x)

    @match x begin
        Dict("result" => result) => @match result begin
            Dict("value" => n, "type" => t) && if t == "number" end => n
            Dict("value" => s, "type" => t) && if t == "string" end => s
            Dict("type" => t, "objectId" => j) && if t == "object" end => JSON.parse(j)
            _ => error("no match js")
        end
        _ => x
    end
end


#needs to import protocal command to put type here
function (tab::Tab)(cmd ; timeout=3)

    tab.command_ids[cmd.id] = nothing
    tab.input(cmd)

    timedwait(float(timeout)) do
        tab.command_ids[cmd.id] != nothing
    end

    if tab.command_ids[cmd.id] == nothing
        error("timedout")
    else
        result = tab.command_ids[cmd.id]
        delete!(tab.command_ids, cmd.id)
        result
    end
end

function close(tab::Tab; timeout=3)
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

#Should validate the url more throughtly
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

function ws_open(url, input, output; timeout=3)

    #need to find a way to kill task when browser closes
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
