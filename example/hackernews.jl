using Headless.Protocol: Page, Runtime
using Headless: Browser
using JSON

chrome = Browser.Chrome(headless=false)

json = Page.navigate("https://news.ycombinator.com/") |>
Runtime.evaluate("""
o = [...document.querySelectorAll(".storylink")].map((x) => {
  return {"link" : x.href, "title" : x.innerHTML}
})
JSON.stringify(o)
""") |> 
chrome[:tab1] |> 
JSON.parse

@show json

close(chrome)