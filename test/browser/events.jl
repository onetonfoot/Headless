using Test
using Headless: Browser
using Headless.Protocol: Page, Network, Runtime
import Headless.Protocol: protocols

using Signals
using Base.CoreLogging
using Logging
logger = SimpleLogger(stdout, Logging.Debug)
global_logger(logger)

@testset "Network" begin
    @testset "loading_finished" begin
        @test_skip begin
            chrome = Browser.Chrome(headless=false)
            tab1 = chrome.tabs[:tab1]
            
            Network.enable() |> tab1
            l = []
            Network.loading_finished() do x
                push!(l,x)
            end |> tab1
            Page.navigate("https://www.facebook.com") |> tab1
            sleep(4)
            @test !isempty(l)
            Browser.close(chrome)
        end
    end
end
