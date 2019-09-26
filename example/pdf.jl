using Headless
using Headless.Protocol: Page
using Base64: base64decode

chrome = Chrome(port=9300)

tab = opentab!(chrome, :tab2, "https://news.ycombinator.com")
sleep(1)
# Only works in headless mode atm
# see https://bugs.chromium.org/p/chromium/issues/detail?id=753118
base_string = tab(Page.print_to_pdf())["data"]
bytes = base64decode(base_string)

open("hackernews.pdf","w") do f
    write(f, bytes)
end

close(chrome)
