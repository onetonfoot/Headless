using Headless.Protocol: Page, Runtime, DOM, Network, Event
using Headless.Browser: init_script
using Headless: Browser
import JSON

chrome = Browser.Chrome(headless=false)

# Hacker new example
json = Page.add_script_to_evaluate_on_new_document(init_script) |>
Page.navigate("https://news.ycombinator.com/") |>
Runtime.evaluate("""
o = [...document.querySelectorAll(".storylink")].map((x) => {
  return {"link" : x.href, "title" : x.innerHTML}
})
JSON.stringify(o)
""") |> chrome[:tab1]

Base.close(chrome)
