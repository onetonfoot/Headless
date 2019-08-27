using Headless.Protocol: Page, Runtime, DOM, Network, Event
using Headless.Browser: init_script
using Headless: Browser
import JSON

chrome = Browser.Chrome(headless=false)

# Hacker new example

Network.response_received() do res
    @show res
end |> chrome[:tab1]

DOM.enable() |> chrome[:tab1]

doc_loaded = DOM.document_updated() do x
    print("page fully loaded event fired")
end

doc_loaded |> chrome[:tab1]

# delete!(chrome[:tab1], doc_loaded)

Page.navigate("https://news.ycombinator.com/") |> chrome[:tab1]
Browser.close(chrome)
