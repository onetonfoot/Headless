using Test, Plumber
using Headless:Browser, Protocol
using Headless.Protocol: Page, DOM, Runtime, protocols, create_command, rmlines

@testset "create_command" begin
    @testset "args" begin
        collectClass = filter(x -> x["name"] == "collectClassNamesFromSubtree", protocols["DOM"]["commands"] )[1]
        ans = quote
            function collect_class_names_from_subtree(node_id;)
                Command(
                    Int(rand(UInt16)),
                    "DOM.collectClassNamesFromSubtree",
                    Dict(
                        "nodeId" => node_id
                    )
                )
            end
        end  |> rmlines
        result = @pipe create_command(collectClass,"DOM") |> rmlines |> _.args[1]
        @test result == ans
    end


    @testset "kwargs" begin
        copyTo = filter(x -> x["name"] == "copyTo", protocols["DOM"]["commands"] )[1]
        ans = quote
            function copy_to(node_id, target_node_id; insert_before_node_id = nothing)
                Command(
                    Int(rand(UInt16)),
                    "DOM.copyTo",
                    Dict("nodeId" => node_id,
                         "targetNodeId" => target_node_id,
                         "insertBeforeNodeId" => insert_before_node_id)
                    )
            end
        end |> rmlines
        result = @pipe create_command(copyTo,"DOM") |> rmlines |> _.args[1]
        @test result == ans
    end
end


@testset "Page" begin

    #TODO handle https and trailing slashes!
    @testset "navigate" begin
        chrome = Browser.Chrome(headless=true)
        tab1 = chrome.tabs[:tab1]
        url = "https://www.facebook.com/"
        tab1(Page.navigate(url))
        @test Runtime.evaluate("window.location.href") |> tab1 == url
        Browser.close(chrome)
    end
end
