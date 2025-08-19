# gpt

Cliente Ruby simples para a Responses API, com foco no GPT-5.

## Instalação
```
bash build_and_install.sh
```

## Configuração
- Defina `OPENAI_API_KEY` no ambiente.
- Opcional: `OPENAI_ORG_ID`, `OPENAI_PROJECT_ID`.

## Uso básico (GPT-5)
```ruby
require 'gpt'

res = GPT.responses.create({
  'model' => 'gpt-5',
  'input' => 'Diga olá em uma frase.'
})

puts res['id']
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

GPT.responses.stream({
  'model' => 'gpt-5',
  'input' => 'Conte uma história curta.'
}) do |chunk|
  print chunk
end
```

## Outras operações
```ruby
id = res['id']
GPT.responses.get(id)
GPT.responses.input_items(id)
GPT.responses.cancel(id)
GPT.responses.delete(id)
```
