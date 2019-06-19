using Headless, Test
import Headless: Browser
using Headless.Protocol: Runtime

#TODO first time browser opens without user data it will ask for permisions
#and doesn't create a single tab

@testset "tab" begin
    @testset "single tab" begin
        chrome = Browser.Chrome()
        sleep(1)
        t = chrome.tabs[:tab1].process
        @test istaskstarted(t)
        Browser.close(chrome)
    end
end

@testset "commands" begin
    @testset "strings and numbers" begin
        chrome = Browser.Chrome()
        tab  = chrome.tabs[:tab1]
        @test tab(Runtime.evaluate("10")) == 10
        @test tab(Runtime.evaluate("'hello'")) == "hello"
        Browser.close(chrome)
    end

    #TODO how to handle objects?
end
