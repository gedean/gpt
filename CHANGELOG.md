# Changelog

## 0.1.0
- Suporte e exemplos para GPT-5 (reasoning minimal, text verbosity, custom tools e allowed_tools)
- Validação de `OPENAI_API_KEY` e ajuste de User-Agent
- README atualizado para GPT-5

## 0.1.1
- Adiciona `GPT.ask` para uso simplificado, com suporte a streaming
- Adiciona `GPT::ResponseExtender` com helpers (`content`, `usage`, `total_tokens`, `to_h`)
- `Responses#create/get` passam a estender a resposta com os helpers

## 0.0.1
- Primeira versão com cliente para API Responses (create/get/delete/cancel/input_items) e streaming SSE.


