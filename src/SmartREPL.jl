module SmartREPL

import REPL.TerminalMenus: request, RadioMenu
import ReplMaker: initrepl, enter_mode!
import TOML: parsefile
import HTTP
import JSON3 as JSON
import Markdown
import MLStyle: @match
import REPL.LineEdit: refresh_line

# TODO: Allow configuration location to be more flexible
CONFIG_FILE = parsefile(joinpath(homedir(), ".smartrepl.toml"))
abstract type Provider end

"""
  request_generate(provider, text::String)  

Generate raw code 
"""
function request_generate end

generate_prompt = """
    You are a Julia code generator. You will receive a query by
    a user working in the REPL. You will respond to this query
    with a code that is ready to paste in the REPL. You will NOT
    enclose the code with backticks. Any non-Julia text should
    be put in a Julia comment, however, comments should be minimal
"""

"""
  generate!(provider, text::String)  

Generate code to prefill next prompt
"""
function generate!(provider, text) 
    code = "apples = 'h'" #request_generate(provider, text)
    if !isdefined(Base, :active_repl) return code end
    repl = Base.active_repl
    mistate = repl.mistate
    normalmode = mistate.interface.modes[1] # Is this always correct?
    enter_mode!(mistate, normalmode)
    state = mistate.mode_state[normalmode]
    state.input_buffer = IOBuffer(code)
    refresh_line(mistate)
    nothing
end


"""
  ask(provider, text::String)::String  

Send one-off query to LLM and get a response
"""
function ask end

# TODO: Include more providers
include("./openai.jl")

PROVIDER = OpenAIProvider()

function llmquery(input)
    choices = [
        "generate",
        "ask",
        "solve",
    ]
    chosen = request("Select operation", RadioMenu(choices))
    @match chosen begin
        1 => generate!(PROVIDER, input)
        2 => ask(PROVIDER, input) 
        3 => ""
    end
end

mode_response(_, _, ::Nothing) = nothing
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

__init__ = register_mode

end # module SmartREPL