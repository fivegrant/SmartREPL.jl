# SmartREPL.jl

## Usage
```
(@v1.9) pkg> add SmartREPL.jl
julia> using SmartREPL
julia> # just use `$` prefix to start the mode
julia> # currently, 'openai_api_key' is read from '~/.smartrepl.toml'
smart> generate a hello world function 
```

## TODOs
- [ ] Publish package
- [ ] Add tests
  - [x] Add unit tests
  - [ ] Mock REPL
  - [ ] Add coverage
- [ ] Document
  - [ ] Improve this README
  - [ ] Generate documentation
  - [ ] Move TODOs to Issues
- [ ] Add more LLM providers (i.e. wean off OpenAI)
- [ ] Create full blown 'agent'
  - [ ] Add tool error probing tool
  - [ ] Allow dynamic history lookup
- [ ] Add better error handling

## Acknowledgements 
- Inspired by [Anand](https://github.com/anandijain)'s [OpenAIReplMode](https://github.com/anandijain/OpenAIReplMode.jl)