module Repl

using ReplMaker, MLStyle, REPL
using REPL.TerminalMenus

using ..Browser
using ..Protocol: Runtime, Target
using JSON, Gumbo
using ..Browser: get_tab_json, add_port, Tab


# To start REPL mode you should pass your own instance of chrome?
chrome = nothing

function start()

    global chrome

    if isnothing(chrome)
        print("CHORME is nothing")
    else
        if !Browser.isportfree(9222)
            Browser.close(chrome)
            sleep(1)
        end
    end

    chrome = Browser.Chrome(;headless=false)

    tab1 = chrome[:tab1]
    # Target.enable() |> tab1

    Target.target_created() do x
        println("TARGET CREATED!!")
        println(x)
    end |> tab1

    # tab2 = Browser.opentab!(chrome, :tab2)
    # tab2  = chrome.tabs[:tab2];
end


# enable and disable should be in one high order function

function enable_events()

    event2module = Dict(
        "network" => Protocol.Network,
        "page" => Protocol.Page,
    )

    events = collect(keys(event2module))
    menu = MultiSelectMenu(events)
    choices = request("Select which events you'd like like to enable" , menu)

    events = [  event2module[events[idx]] for idx in choices ]

    for tab in values(chrome.tabs)
        for event in events
            #if enable else disale
            tab(event.enable())
        end
    end
end


# This should allow a user to select which event listners
# they would like to enable for capture input mode

function enable_event_listeners()

    events = [
        "dblclick",
        "click",
    ]
    menu = MultiSelectMenu(events)
    choices = request("Select event you'd like to listen to" ,menu)
    keys = events[collect(choices)]
    print("Enabling listening for $keys")

    # Need to select the correct javascript as oposed to evaluating the whole file
    js = read(joinpath(@__DIR__,"event_listeners.js"), String)

    for tab in values(chrome.tabs)
        tab(Runtime.evaluate(js))
    end
end

# Idealy this function should caputure all user input that is on via `enable_event_listeners`
# and return the equivalent Headless.Commands to achieve the same thing

function capture_input()

    println("Capturing for user input any key to stop listening...")
    # First need to figure out how to get the active tab and monitor tab changes

end


function get_activate_tab(chrome)

end


function update_tabs!(chrome)

    tabs = collect(values(chrome.tabs))
    tab_ids = map(t -> t.id, tabs)
    all_tabs = get_tab_json(chrome.port)

    for d in all_tabs
        if !(d["id"] in tab_ids)
            ws_url = add_port(d["webSocketDebuggerUrl"], chrome.port)
            @show ws_url
            tab = Tab(ws_url)
            #should check name doesn't already exists...
            tabname = Symbol("unamed$(length(tabs) + 1)")
            chrome.tabs[tabname] = tab
            println("Added tab $tabname")
        end
    end
end


function enter_selection_mode()

    global chrome
    update_tabs!(chrome)

    active_tab = nothing
    js = read(joinpath(@__DIR__,"selection_mode.js"), String)

    for tab in values(chrome.tabs)
        if !tab(Runtime.evaluate("document.hidden"))
            active_tab = tab
            active_tab(Runtime.evaluate(js))
        end
    end

    if isnothing(active_tab)
        print("No activate tab!")
        return
    end

    print("Select the elements you'd like to scrape. Press any key to finish")
    readline()

    active_tab(Runtime.evaluate("selectedToString()")) |> JSON.parse .|> parsehtml
end


# Algorithm that can print selector that is in common  with them all
# https://en.wikipedia.org/wiki/Longest_common_substring_problem

# Could first try to find it the elements have common attributes between the elements
# If not maybe there parents do?

function find_common_selector(element::Array{HTMLElement})

end


# should be able to eneter a css selector in REPL mode and it should run on the current tab
# should make $ = querySelector and $$ querySelectorAll


end
