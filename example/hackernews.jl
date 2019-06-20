using Headless.Protocol: Page, Runtime, DOM, Network
using Headless.Browser: init_script, close
using Headless: Browser
import JSON

chrome = Browser.Chrome(headless=false)

# Hacker new example
json = Page.add_script_toevaluate_onnew_document(init_script) |>
Page.navigate("https://news.ycombinator.com/") |>
Runtime.evaluate("""
o = [...document.querySelectorAll(".storylink")].map((x) => {
  return {"link" : x.href, "title" : x.innerHTML}
})
JSON.stringify(o)
""") |> chrome[:tab1]
