using Test
using Headless: Browser
using Headless.Protocol: Page, Network, Runtime, DOM
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
            close(chrome)
        end
    end
end

@testset "DOM" begin
    @testset "DOM.documenetUpdated" begin
        chrome = Browser.Chrome(headless=false)
        tab1 = chrome[:tab1]

        google = []
        DOM.document_updated() do x
            push!(google, :google)
        end |> tab1
        Page.navigate("https://www.google.com") |> tab1
        sleep(3)
        n1 = length(google)
        @test n1 >= 1

        # Current semantic are that only a single event handler is a allow for each event
        # therefore adding another on will overwrite any existing ones
        fb = []
        DOM.document_updated() do x
            push!(fb, :fb)
        end |> tab1
        Page.navigate("https://www.facebook.com") |> tab1
        sleep(3)
        @test length(fb) >= 1
        @test length(google) == n1


        should_be_empty = []

        delete!(tab1, DOM.document_updated)
        DOM.document_updated() do x
            push!(should_be_empty, :hello)
        end |> tab1
        delete!(tab1, DOM.document_updated)
        Page.navigate("https://www.reddit.com") |> tab1
        sleep(3)
        @test isempty(should_be_empty)

        close(chrome)
    end
end
