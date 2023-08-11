import SmartREPL as src
import Test: @test, @testset
import Mocking: Mocking, @patch, apply
import EasyConfig: Config

Mocking.activate()

@test !src.active()

@testset "systemprompt" begin
    @test src.systemprompt(src.pick) == src.pick_prompt
    @test src.systemprompt(src.code) == src.code_prompt
    @test src.systemprompt(src.explain) == src.explain_prompt
end

@testset "liftaction" begin
    @test src.liftaction("pick") == src.pick
    @test src.liftaction("code") == src.code
    @test src.liftaction("explain") == src.explain
end


import HTTP

function mock_openai_json(str)
    mocked = Config()
    mocked.body = """{"choices": [{"message": {"content": "$str"}}]}"""
    mocked
end

@testset "step_llm!" begin
    response = @patch HTTP.post(_, _, _) = mock_openai_json("  code ")
    og_context = src.QueryContext("")
    provider = src.OpenAIProvider()
    apply(response) do
        context = src.step_llm!(og_context, provider)
        @test context == og_context
        @test length(context.states) == 2 
        @test context.states[1].result == "code"
    end

    
    testcode = "gen_nothing() = nothing"
    response = @patch HTTP.post(_, _, _) = mock_openai_json(testcode)
    context = src.QueryContext("", [src.ActionState("pick"),src.ActionState("code")])
    provider = src.OpenAIProvider()
    apply(response) do
        context = src.step_llm!(og_context, provider)
        @test context == og_context
        @test length(context.states) == 2 
        @test context.states[end].result == testcode
    end
end


@testset "llmquery" begin

    testcode = "gen_nothing() = nothing"
    mockstep = 1
    function mockboth()
        if mockstep == 1
            mockstep += 1
            mock_openai_json("  code      ")
        else
            mock_openai_json(testcode)
        end
    end
    response = @patch HTTP.post(_, _, _) = mockboth()
    context = src.QueryContext("")
    provider = src.OpenAIProvider()
    apply(response) do
        @test src.llmquery("query") == testcode
    end

end
