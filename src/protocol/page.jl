using ..Protocol: Runtime

function click(selector)
    Runtime.evaluate(
    """document.querySelector("$(selector)").click()"""
    )
end

function type(selector, value)
    Runtime.evaluate("""
        document.querySelector("$(selector)").value = "$(value)"
    """)
end

function scroll_by(x, y)
    Runtime.evaluate("""
        window.scrollBy($x,$y)
    """)
end

function scroll_to(x, y)
    Runtime.evaluate("""
        window.scrollTo($x,$y)
    """)
end

function back()
    url = Runtime.evaluate("document.referrer" ) |> chrome[:tab1]
    #TODO better error handling
    try
        Page.navigate(url)
    catch e
        @show url
        throw(e)
    end
end
