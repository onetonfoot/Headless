module Repl

using ReplMaker, MLStyle, REPL
using REPL.TerminalMenus

using ..Browser
using ..Protocol: Runtime

# To start REPL mode you should pass your own instance of chrome

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
    tab2 = Browser.opentab!(chrome, :tab2)
    tab2  = chrome.tabs[:tab2];
end

function selection_mode()

    events = [
        "dblclick",
        "click",
    ]
    menu = MultiSelectMenu(events)
    choices = request("Select event you'd like to listen to" ,menu)
    keys = events[collect(choices)]
    print("Enabling listening for $keys")

    # Need to select the correct javascript
    js = read(joinpath(@__DIR__,"selection_mode.js"), String)

    for tab in values(chrome.tabs)
        tab(Runtime.evaluate(js))
    end
end

function select_tab()
    global chrome
    tabnames = chrome.tabs |> keys .|> String
    if length(tabnames) < 2
        println("Less than 2 tabs")
    else
        menu = RadioMenu(tabnames, pagesize=4)
        choice = request("Select a tab:", menu)
        if choice == -1
            println("No tab selected")
        else
            tab = tabnames[choice]
            activatetab!(chrome, Symbol(tab))
            println("Tab selected was $tab")
        end
    end
end

function enter_url()

end


function capture_input()

    println("Capturing for user input any key to stop listening...")

end

# Browser.close(chrome)

end
