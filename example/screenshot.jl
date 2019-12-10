using Headless
using Headless.Protocol: Page
using Base64: base64decode

chrome = Chrome()

tab = opentab!(chrome, :tab2, "https://news.ycombinator.com")

base_string = tab(Page.capture_screenshot())["data"]
bytes = base64decode(base_string)

open("hackernews.png","w") do f
    write(f, bytes)
end

close(chrome)
