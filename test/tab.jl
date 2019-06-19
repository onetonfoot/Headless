using Headless, Test
import Headless: Browser, Protocol
using Sockets, Signals

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
        @test tab(Protocol.evaluate("10")) == 10
        @test tab(Protocol.evaluate("'hello'")) == "hello"
        Browser.close(chrome)
    end

    #TODO how to handle objects?

end
