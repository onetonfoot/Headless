using Headless.Protocol: Page, Network
using Headless:Browser

chrome = Browser.Chrome(headless=false)

user_agent = "Mozilla/5.0 (X11; Linux x86_64)' * 'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.39 Safari/537.36"
Page.enable() |>
Network.enable() |>
Network.set_user_agent_override(user_agent) |>
Page.add_script_toevaluate_onnew_document(init_script) |>
Page.navigate("https://infosimples.github.io/detect-headless/") |> chrome[:tab1]
sleep(1)
Page.handlejavascript_dialog(true) |> chrome[:tab1]

Browser.close(chrome)
