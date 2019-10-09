using Headless: Browser
using Headless.Protocol: Page
using Base64

chrome = Browser.Chrome(headless=true)

json = Page.navigate("https://www.google.com") |> Page.print_to_pdf() |> chrome[:tab1]
pdf = Base64.base64decode(json["data"])

open("google.pdf","w") do f
    write(f, pdf)
end

# rm("google.pdf")

close(chrome)