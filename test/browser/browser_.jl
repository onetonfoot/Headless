using Test
using Headless.Browser
using Headless.Browser: PortAlreadyInUse, TabAlreadyExists, NoTabExists
using Headless.Protocol: Runtime

@testset "browser open and close" begin
    @testset "free port" begin
         chrome = Browser.Chrome()
         @test process_running(chrome.process)
         close(chrome)
     end

    @testset "isportfree" begin
         chrome = Browser.Chrome()
         @test Browser.isportfree(9222) == false
         close(chrome)
     end

    @testset "used port" begin
         chrome = Browser.Chrome()
         @test_throws PortAlreadyInUse(9222) Browser.Chrome()
         close(chrome)
     end

    # @testset "flags" begin
    #     chrome = Browser.Chrome(flags = "--disable-web-security")
    #     @test_skip PortAlreadyInUse(9222)  Browser.Chrome()
    #     close(chrome)
    #  end
end

@testset "get_ws_urls" begin
    base = "ws://127.0.0.1/devtools/browser/"
    chrome = Browser.Chrome()
    urls = Browser.get_ws_urls(9222)
    close(chrome)
    @test length(urls) == 1
end

@testset "tab open and close" begin

    #Check that there is always a tab!
    @testset "can open new tabs" begin
        chrome = Browser.Chrome(headless=true)
        tab1 = Browser.opentab!(chrome, :tab2, "http://www.facebook.com")
        tab2 = Browser.opentab!(chrome, :tab3, "http://www.google.com")
        tab3 = Browser.opentab!(chrome, :tab4)
        @test istaskstarted(tab1.process)
        @test istaskstarted(tab2.process)
        @test istaskstarted(tab3.process)
        @test_throws TabAlreadyExists(:tab2) Browser.opentab!(chrome,:tab2)
        close(chrome)
    end

    @testset "can close tabs" begin
        chrome = Browser.Chrome(headless=true)
        tab2 = Browser.opentab!(chrome, :tab2)
        Browser.closetab!(chrome, :tab2)
        @test istaskdone(tab2.process)
        @test length(chrome.tabs) == 1
        @test_throws NoTabExists(:tab2) Browser.closetab!(chrome, :tab2)
        close(chrome)
    end


    @testset  "activatetab!" begin
        # TravisCI requires extra config for test that require GUIs
        @test_skip begin
            chrome = Browser.Chrome(headless=false)
            tab2 = Browser.opentab!(chrome, :tab2)
            Browser.activatetab!(chrome, :tab1)
            close(chrome)
        end
    end
end


# TODO store the output of the process for debgugging chrome
# for example when flags are passes the don't work
# TODO add test for flags

# port = 9222
# user_data_dir = tempdir()
# if !isdir(user_data_dir)
#     mkdir(user_data_dir)
# end
# cmd =  `'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'`
# cmd = `$cmd --no-first-run --remote-debugging-port=$port --user-data-dir=$user_data_dir`
# pipeline(cmd, stdout=devnull, stderr=devnull) |> open
