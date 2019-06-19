module Browser

using Signals
import JSON, HTTP, Sockets, OpenTrick
import HTTP: WebSockets

export start, Tab

include("tab.jl")

#TODO add init script that will optional be executed
#when you open a new tab
#TODO pass optional command line flags
mutable struct Chrome
    process
    # host #would be nice to be possible to lanch on something not localhost
    port
    tabs
end

function Chrome(;headless=true, port=9222)

    process = start(;headless=headless, port=port)
    ws_urls = get_ws_urls(port)
    tabs = Dict(Symbol("tab$i")=> Tab(ws_url) for (i, ws_url) in enumerate(ws_urls))
    Chrome(
        process,
        port,
        tabs,
    )

end

function isportfree(port::Int)
    try
        socket = Sockets.connect("localhost", port)
        Sockets.close(socket)
        false
    catch e
        e != Base.IOError("connect: connection refused (ECONNREFUSED)", -111) && rethrow(e)
        true
    end
end

function start(;headless=true, port=9222)
    if isportfree(port)
        cmd = `google-chrome  --remote-debugging-port=$port --user-data-dir=/tmp/user_data`
        if headless
            cmd = `google-chrome --remote-debugging-port=$port --user-data-dir=/tmp/user_data/ --headless`
        end
        process = pipeline(cmd, stdout=devnull, stderr=devnull) |> open
        #TODO replace with timed wait
        while !process_running(process)
            sleep(0.01)
        end
        process
    else
        throw(ErrorException("port already in use"))
    end
end



function close(browser::Chrome)
    map(close, collect(values(browser.tabs)))
    kill(browser.process)
    err = ErrorException("timedout closing browser")
    timederror(err, 5) do
        process_exited(browser.process)
    end
end

#TODO All of these are of the same formish
#so code could probaly be refactored

function newtab!(browser::Chrome, tabname::Symbol ,url)

    @assert !haskey(browser.tabs, tabname) "tab already exists"
    response = HTTP.get("http://localhost:$(browser.port)/json/new?$(url)")
    d = response.body |> String |> JSON.parse
    ws_url = add_port(d["webSocketDebuggerUrl"], browser.port)
    tab = Tab(ws_url)
    browser.tabs[tabname] = tab
    tab
end

newtab!(browser::Chrome, tabname::Symbol) = newtab!(browser,tabname, "")

function closetab!(browser, tabname::Symbol; timeout=3)

    try
        tab = browser.tabs[tabname]
        url = "http://localhost:$(browser.port)/json/close/$(tab.id)"
        response = HTTP.get(url)
        @assert response.body |> String == "Target is closing"
        close(tab; timeout=timeout)
        delete!(browser.tabs, tabname)
        browser
    catch e
        if e isa KeyError
            error("tab doesn't exist")
        end
        rethrow(e)
    end
    browser
end

function activatetab!(browser, tabname::Symbol; timeout=3)
    try
        tab = browser.tabs[tabname]
        url = "http://localhost:$(browser.port)/json/activate/$(tab.id)"
        response = HTTP.get(url)
        @assert response.body |> String == "Target activated"
    catch e
        rethrow(e)
    end
    browser
end

end  # modul Browser
