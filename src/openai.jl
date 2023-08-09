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
  request_generate(provider::OpenAIProvider, text::String)  

Generate code using OpenAI API
"""
function request_generate(provider::OpenAIProvider, text::String)
  if ismissing(OPENAI_API_KEY) throw("No OpenAI key provided.") end
  completions = joinpath(OPENAI_API, "chat/completions")
  headers = ["Content-Type" => "application/json", "Authorization" => "Bearer " * OPENAI_API_KEY]
  request = Dict(
    "model" => provider.model,
    "messages" => [
      Dict("role" => "system", "content" => generate_prompt)
      Dict("role"=> "user", "content"=> text)
    ],
    "temperature" => provider.temperature
  ) |> JSON.write
  # TODO: CATCH HTTP.Exceptions.StatusError(400
  response = HTTP.post(completions, headers, request).body |> JSON.read
  response.choices[1].message.content
end

"""
  ask(provider::OpenAIProvider, text::String)::String

Send query to OpenAI (cost incurred for each use)  
"""
function ask(provider::OpenAIProvider, text::String)
  if ismissing(OPENAI_API_KEY) throw("No OpenAI key provided.") end
  completions = joinpath(OPENAI_API, "chat/completions")
  headers = ["Content-Type" => "application/json", "Authorization" => "Bearer " * OPENAI_API_KEY]
  request = Dict(
    "model" => provider.model,
    "messages" => [
      Dict("role"=> "user", "content"=> text)
    ],
    "temperature" => provider.temperature
  ) |> JSON.write
  # TODO: CATCH HTTP.Exceptions.StatusError(400
  response = HTTP.post(completions, headers, request).body |> JSON.read
  response.choices[1].message.content
end
