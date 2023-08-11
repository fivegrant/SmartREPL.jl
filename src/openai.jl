OPENAI_API_KEY = get(CONFIG_FILE, "openai_api_key", missing)
OPENAI_API = "https://api.openai.com/v1"

struct OpenAIProvider <: Provider 
  model::String
  temperature::Float64
  OpenAIProvider(
    model::String="gpt-3.5-turbo", 
    temperature::Float64=0.1
  ) = new(model,temperature)
end


"""
  step_llm(context::QueryContext, provider::OpenAIProvider)::String

Send query to OpenAI (cost incurred for each use)  
"""
function step_llm!(context::QueryContext, provider::OpenAIProvider)
  if ismissing(OPENAI_API_KEY) throw("No OpenAI key provided.") end

  currentstate = context.states[end].action
  messages = [
      Dict("role" => "system", "content" => systemprompt(currentstate)),
      Dict("role" => "user", "content"=> context.query)
  ]  

  completions = joinpath(OPENAI_API, "chat/completions")
  headers = ["Content-Type" => "application/json", "Authorization" => "Bearer " * OPENAI_API_KEY]
  request = Dict(
    "model" => provider.model,
    "messages" => messages,
    "temperature" => provider.temperature
  ) |> JSON.write

  # TODO: CATCH HTTP.Exceptions.StatusError(400
  response = @mock HTTP.post(completions, headers, request)
  body = response.body |> JSON.read
  context.states[end].result = body.choices[1].message.content
  if currentstate == pick 
    picked = string(strip(context.states[end].result))
    context.states[end].result = picked 
    push!(context.states, ActionState(picked))
  end
  context
end
