using Headless: Browser
using Headless.Protocol: Page, Network, Fetch

chrome = Browser.Chrome(headless=false)
tab = chrome[:tab1]
tab(Fetch.enable())

Fetch.request_paused() do request
    request = request["params"] 
    if request["resourceType"] == "Image"
        Fetch.fail_request(request["requestId"], "Aborted") |> tab
    else
        Fetch.continue_request(request["requestId"]) |> tab
    end
end |> chrome[:tab1]

Page.navigate("https://www.news.google.com/news") |> tab

close(chrome)