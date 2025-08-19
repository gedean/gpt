# gpt

Cliente Ruby simples para a Responses API, com foco no GPT-5, com uma API de alto nível inspirada no OpenAIExt.

## Instalação
```
bash build_and_install.sh
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
