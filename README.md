# gpt

Cliente Ruby simples para a API Responses.

Instalação
```
gem build gpt.gemspec && gem install ./gpt-0.0.1.gem
```

Uso básico
```ruby
require 'gpt'

client = GPT.client

res = client.responses.create({
  'model' => 'gpt-4.1',
  'input' => 'Diga olá em uma frase.'
})

puts res['id']
```

Streaming SSE
```ruby
require 'gpt'

GPT.responses.stream({
  'model' => 'gpt-4.1',
  'input' => 'Conte uma história curta.'
}) do |chunk|
  print chunk
end
```

Outras operações
```ruby
id = res['id']
GPT.responses.get(id)
GPT.responses.input_items(id)
GPT.responses.cancel(id)
GPT.responses.delete(id)
```
