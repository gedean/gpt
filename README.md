# gpt

Cliente Ruby simples para a Responses API, com foco no GPT-5, com uma API de alto nível inspirada no OpenAIExt.

## Instalação
```bash
gem install gpt
```

## Configuração
- Defina `OPENAI_API_KEY` ou `OPENAI_ACCESS_TOKEN` no ambiente.
- Opcional: `OPENAI_ORG_ID` ou `OPENAI_ORGANIZATION_ID`, `OPENAI_PROJECT_ID`.
- Opcional: `OPENAI_REQUEST_TIMEOUT` (segundos, padrão 120).

## Uso básico (GPT-5)
```ruby
require 'gpt'

res = GPT.ask('Diga olá em uma frase.', model: 'gpt-5')
puts res.content
```

## Reasoning mínimo (minimal)
```ruby
res = GPT.responses.create({
  'model' => 'gpt-5',
  'input' => 'Quanto ouro seria necessário para cobrir a Estátua da Liberdade com 1mm?',
  'reasoning' => { 'effort' => 'minimal' }
})
```

## Verbosidade baixa
```ruby
res = GPT.responses.create({
  'model' => 'gpt-5',
  'input' => 'Qual é a resposta para a vida, o universo e tudo mais?',
  'text' => { 'verbosity' => 'low' }
})
```

## Ferramentas personalizadas (custom tools)
```ruby
res = GPT.responses.create({
  'model' => 'gpt-5',
  'input' => 'Use a ferramenta code_exec para calcular a área de um círculo com raio igual ao número de letras r em blueberry',
  'tools' => [
    { 'type' => 'custom', 'name' => 'code_exec', 'description' => 'Executa código Python arbitrário' }
  ]
})
```

## Restringindo ferramentas (allowed_tools)
```ruby
res = GPT.responses.create({
  'model' => 'gpt-5',
  'input' => 'Como está o tempo em São Paulo?',
  'tools' => [ { 'type' => 'function', 'name' => 'get_weather' } ],
  'tool_choice' => {
    'type' => 'allowed_tools',
    'mode' => 'auto',
    'tools' => [ { 'type' => 'function', 'name' => 'get_weather' } ]
  }
})
```

## Passando raciocínio prévio (previous_response_id)
```ruby
first = GPT.responses.create({
  'model' => 'gpt-5',
  'input' => 'Planeje passos para resolver X.'
})

followup = GPT.responses.create({
  'model' => 'gpt-5',
  'input' => 'Agora execute o primeiro passo.',
  'previous_response_id' => first['id']
})
```

## Streaming SSE
```ruby
require 'gpt'

GPT.ask('Conte uma história curta.', model: 'gpt-5', stream: true) { |chunk| print chunk }

# Streaming de texto direto
GPT.ask('Conte uma história curta.', model: 'gpt-5', text_stream: true) { |text| print text }
```

## Outras operações
```ruby
id = res['id']
GPT.responses.get(id)
GPT.responses.input_items(id)
GPT.responses.cancel(id)
GPT.responses.delete(id)
```

## Helpers de resposta
```ruby
res = GPT.ask('Qual a capital da França?', model: 'gpt-5')
res.content
res.model
res.total_tokens
res.to_h
```

## Function calling
```ruby
require 'gpt'

# Passe ferramentas diretamente para GPT.ask
res = GPT.ask(
  'Como está o tempo em São Paulo?',
  model: 'gpt-5',
  tools: [
    {
      'type' => 'function',
      'name' => 'get_weather',
      'description' => 'Obter clima atual',
      'parameters' => {
        'type' => 'object',
        'properties' => {
          'location' => { 'type' => 'string' },
          'unit' => { 'type' => 'string', 'enum' => ['celsius', 'fahrenheit'] }
        },
        'required' => ['location']
      }
    }
  ]
)

puts res.content
```

### Executando funções chamadas pelo modelo
```ruby
# Se o modelo decidir acionar uma função, você pode inspecionar e executar:
if res.functions?
  # Exemplo de contexto com um método compatível com o nome da função
  class WeatherContext
    def get_weather(location:, unit: 'celsius')
      { location: location, unit: unit, temp: 26 }
    end
  end

  tool_messages = res.functions_run_all(context: WeatherContext.new)

  # tool_messages é uma lista de hashes com:
  #   :tool_call_id, :role=>:tool, :name, :content (string/json)
  # Em Chat Completions, você pode passar estes objetos diretamente em messages.
  # Na Responses API, converta-os para input items compatíveis (ex.: tool_result).
  p tool_messages
end
```
