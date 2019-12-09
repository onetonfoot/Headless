module Browser

using Signals
import JSON, HTTP, Sockets
import HTTP: WebSockets
import Base.Sys: islinux, isapple

export opentab!, activatetab!, closetab!, tabnames, Chrome

include("tab.jl")

struct PortAlreadyInUse <: Exception
    port
end

struct TabAlreadyExists <: Exception
    name
end

struct NoTabExists <: Exception
    name
end

mutable struct Chrome
    process
    # host # TODO Would be nice launch on something that's not localhost
    port
    tabs
end

# TODO add init_fn that will optional be executed each time you open a new tab
# https://peter.sh/experiments/chromium-command-line-switches/
# https://www.chromium.org/developers/how-tos/run-chromium-with-flags

"""Starts an instance chrome browsers"""
function Chrome(;headless=true, user_data_dir=tempdir(), port=9222)

    if !isportfree(port)
        PortAlreadyInUse(port)
    end

    process = start(;headless=headless, user_data_dir=user_data_dir, port=port)
    ws_urls = get_ws_urls(port)
    tabs = Dict(Symbol("tab$i")=> Tab(ws_url) for (i, ws_url) in enumerate(ws_urls))
    Chrome(
        process,
        port,
        tabs,
    )

end

Base.getindex(browser::Chrome, key::Symbol) = getindex(browser.tabs, key)
Base.setindex!(browser::Chrome, key::Symbol) = setindex!(browser.tabs, key)
tabnames(chrome::Chrome) = collect(keys(chrome.tabs))


function Base.show(io::IO, chrome::Chrome)
    #TODO make this prettier :/
    print(io, """Chrome:
                - running - $(process_running(chrome.process))
                - port - $(chrome.port)
                - num tabs - $(length(chrome.tabs))""")
end


function start(;headless=true, user_data_dir=tempdir(), port=9222)
    if isportfree(port)

        cmd = if islinux()
            `google-chrome`
        elseif isapple()
            `'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'`
        else
            error("Windows is currently not supported")
        end

        # TODO there should be a cleaner way to find if the binary exist across differnet OSes
        if isapple() && !isfile(cmd.exec[1])
            error("You don't have the chrome binary in the default location - $(cmd.exec[1])")
        end

        # More default flags can be found here
        # https://github.com/puppeteer/puppeteer/blob/master/lib/Launcher.js

        if !isdir(user_data_dir)
            mkdir(user_data_dir)
        end

        cmd = `$cmd --no-first-run --remote-debugging-port=$port --user-data-dir=$user_data_dir`

        if headless
            cmd = `$cmd --headless`
        end

        process = pipeline(cmd, stdout=devnull, stderr=devnull) |> open

        while !process_running(process)
            sleep(0.01)
        end
        process
    else
        throw(PortAlreadyInUse(port))
    end
end

function Base.close(browser::Chrome)
    map(close, collect(values(browser.tabs)))
    kill(browser.process)
    err = ErrorException("timedout closing browser")
    timederror(err, 5) do
        process_exited(browser.process)
    end
end

function opentab!(browser::Chrome, tabname::Symbol, url)

    if haskey(browser.tabs, tabname)
        throw(TabAlreadyExists(tabname))
    end

    response = HTTP.get("http://localhost:$(browser.port)/json/new?$(url)")
    d = response.body |> String |> JSON.parse
    ws_url = add_port(d["webSocketDebuggerUrl"], browser.port)
    tab = Tab(ws_url)
    browser.tabs[tabname] = tab
    tab
end

opentab!(browser::Chrome, tabname::Symbol) = opentab!(browser,tabname, "")

function closetab!(browser::Chrome, tabname::Symbol; timeout=3)

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
            throw(NoTabExists(tabname))
        end
        rethrow(e)
    end
    browser
end

"""Used to bring the given tab name into focus"""
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

function isportfree(port::Int)
    try
        socket = Sockets.connect("localhost", port)
        Sockets.close(socket)
        false
    catch e
        if e isa Base.IOError
            true
        else
            rethrow(e)
        end
    end
end

end  # module Browser
