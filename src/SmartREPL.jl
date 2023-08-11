module SmartREPL

import ReplMaker: initrepl
import TOML: parsefile
import HTTP
import JSON3 as JSON
import Markdown
import MLStyle: @match, @data
import Mocking: Mocking, @mock

# TODO: Allow configuration location to be more flexible
CONFIG_FILE = parsefile(joinpath(homedir(), ".smartrepl.toml"))
active() = isdefined(Base, :active_repl)

abstract type Provider end

# TODO: Fix the case on these
@data Action begin 
    pick 
    code 
    explain 
end

pick_prompt = """
    You are a picking mechanism given two options: 'code' and 'explain'.
    You will be given some kind of natural language query and you will
    try to pick if the 'code' or 'explain' tools to apply.

    `code`: This tool transforms natural language into Julia code.
    This is probably used most of the time.

    `explain`: This tool is a catcahll for queries that wouldn't
    fit code.

    ONLY respond with a single word 'code' or 'explain' without
    punctuation or ANY additional words.
"""

code_prompt = """
    You are a Julia code generator. You will receive a query by
    a user working in the REPL. You will respond to this query
    with a code that is ready to paste in the REPL. You will NOT
    enclose the code with backticks. Any non-Julia text should
    be put in a Julia comment, however, comments should be minimal
"""

explain_prompt = """
    You are a general assistant embedded in a Julia REPL. 
    You will receive a question by the user, probably related to
    Julia.
"""

systemprompt(action::Action) = @match action begin
    pick => pick_prompt
    code => code_prompt
    explain => explain_prompt
end

liftaction(str::String)::Action = @match str begin
    "pick" => pick
    "code" => code
    "explain" => explain
    _ => throw("'{str}' does not parse to action")
end

mutable struct ActionState
    action::Action
    result::Union{String, Nothing}
    ActionState(action::Action,  result::Union{String, Nothing}=nothing) = new(action, result)
    ActionState(action::String,  result::Union{String, Nothing}=nothing) = new(liftaction(action), result)
end

mutable struct QueryContext
    query::String
    states::Vector{ActionState}
    QueryContext(query::String, states::Vector{ActionState}=[ActionState(pick)]) = new(query, states)
end

"""
  step_llm!(context::QueryContext, provider)::String  

Make LLM-specific call
"""
function step_llm! end

# TODO: Include more providers
include("./openai.jl")

PROVIDER = OpenAIProvider()

function llmquery(input)
    context = QueryContext(input)
    # TODO: Make this into a full blown 'agent'
    context = step_llm!(context, PROVIDER) # Run pick
    context = step_llm!(context, PROVIDER) # Run chosen operation
    context.states[end].result
end

mode_response(_, _, llm_response::AbstractString) = (display ∘ Markdown.parse)(llm_response)


function register_mode()
    initrepl(llmquery;
        show_function=mode_response,
        start_key='$',
        prompt_color=:red,
        mode_name=:smart_mode,
        prompt_text="smart> ",
    )
end

__init__() = active() ? register_mode() : nothing

end # module SmartREPL