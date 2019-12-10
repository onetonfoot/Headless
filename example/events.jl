using Headless.Protocol: Page, Runtime, DOM, Network, Event
using Headless.Browser: init_script
using Headless: Browser
import JSON

chrome = Browser.Chrome(headless=false)

response_received = Network.response_received() do res
    @info "Reponse from call back"
    res
end |>  chrome[:tab1]

# Event return signals which can be further combined
debounce(response_received, delay=3.0) do res
    @info "Response from debounced signal $res"
end

delete!(chrome[:tab1], Network.response_received)
Page.navigate("https://google.com/") |> chrome[:tab1]

close(chrome)
