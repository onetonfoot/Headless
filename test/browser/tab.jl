using Headless, Test
using Headless: Browser
using Headless.Protocol: Runtime
using Headless.Browser: JsError, TimedoutError

# TODO first time browser opens without a user data folder it will ask for permisions
# to be the default browser and doesn't create a single tab. This results
# in the test falling the first time they are run

@testset "tab" begin
    @testset "single tab" begin
        chrome = Browser.Chrome()
        sleep(1)
        t = chrome.tabs[:tab1].process
        #TODO check that the tab is running in chrome
        #and not just that julia has started the task
        @test istaskstarted(t)
        Browser.close(chrome)
    end
end

@testset "commands" begin
    @testset "strings and numbers" begin
        chrome = Browser.Chrome()
        tab = chrome.tabs[:tab1]
        @test tab(Runtime.evaluate("10")) == 10
        @test tab(Runtime.evaluate("'hello'")) == "hello"
        Browser.close(chrome)
    end


    @testset "chaining commannds" begin
        chrome = Browser.Chrome()
        tab  = chrome.tabs[:tab1]
        result =  Runtime.evaluate("x = 10") |>
        Runtime.evaluate("x * 2") |>
        tab
        @test result == 20
        Browser.close(chrome)
    end

    @testset "javascript errors" begin
        chrome = Browser.Chrome()
        tab = chrome.tabs[:tab1]
        @test_throws JsError tab(Runtime.evaluate("x"))
        Browser.close(chrome)
    end

    @testset "timeouts" begin
        chrome = Browser.Chrome()
        tab = chrome.tabs[:tab1]

        js =  """

        function sleep(millis) {
            var date = new Date();
            var curDate = null;
            do { curDate = new Date(); }
            while(curDate-date < millis);
        }

        sleep(10000)
        """

        @test_throws TimedoutError tab(Runtime.evaluate(js), timeout=1.0)
        Browser.close(chrome)
    end
end


@testset "events" begin


end
