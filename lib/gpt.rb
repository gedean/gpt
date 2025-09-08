module GPT; end

require 'oj'
require 'net/http'
require 'uri'

require_relative 'gpt/version'
require_relative 'gpt/error'
require_relative 'gpt/client'
require_relative 'gpt/responses'
require_relative 'gpt/response_extender'

module GPT
  def self.client
    @client ||= Client.new
  end

  def self.responses
    @responses ||= Responses.new(client)
  end

  def self.deep_stringify(value)
    case value
    when Hash
      value.each_with_object({}) { |(k, v), acc| acc[k.to_s] = deep_stringify(v) }
    when Array
      value.map { |v| deep_stringify(v) }
    when Symbol
      value.to_s
    else
      value
    end
  end

  def self.normalize_tools(tools)
    return tools unless tools.is_a?(Array)
    tools.map do |tool|
      next tool unless tool.is_a?(Hash)
      t = deep_stringify(tool)
      if t['type'].to_s == 'function'
        fn = t['function'] || {}
        t['name'] = t['name'] || fn['name']
        t['description'] = t['description'] || fn['description']
        t['parameters'] = t['parameters'] || fn['parameters']
        # Remover strict se for nil para evitar problemas
        if t.key?('strict') || fn.key?('strict')
          t['strict'] = t.key?('strict') ? t['strict'] : fn['strict']
        end
        t.delete('function')
      end
      t
    end
  end

  def self.ask(prompt, model: 'gpt-5', stream: false, text_stream: false, **opts, &block)
    internal_tools_context = opts.key?(:tools_context) ? opts.delete(:tools_context) : opts.delete('tools_context')
    internal_max_iters = opts.key?(:max_tool_iterations) ? opts.delete(:max_tool_iterations) : opts.delete('max_tool_iterations')
    # Se tools_context foi fornecido, ativa a execução automática de tools
    internal_auto = !!internal_tools_context

    payload = { 'model' => model, 'input' => prompt }
    opts.each { |k, v| payload[k.to_s] = v }
    payload = deep_stringify(payload)
    if payload['tools']
      payload['tools'] = normalize_tools(payload['tools'])
    end

    if internal_auto
      return ask_with_auto_tools(payload, prompt: prompt, tools_context: internal_tools_context, max_tool_iterations: internal_max_iters)
    end

    if stream
      responses.stream(payload) { |chunk| yield chunk if block_given? }
    elsif text_stream
      responses.stream_text(payload) { |text| yield text if block_given? }
    else
      res = responses.create(payload)
      res.extend(ResponseExtender)
      normalize_response_output!(res)
      wait_for_response_if_needed(res)
    end
  end

  def self.ask_with_auto_tools(base_payload, prompt:, tools_context:, max_tool_iterations: 5)
    raise GPT::Error.new('auto_tools requer tools') unless base_payload['tools']
    raise GPT::Error.new('auto_tools requer tools_context') unless tools_context

    res = responses.create(base_payload)
    res.extend(ResponseExtender)
    normalize_response_output!(res)
    res = wait_for_response_if_needed(res)

    iterations = 0
    last_results = []
    loop do
      iterations += 1
      break if iterations > (max_tool_iterations || 5)

      tool_calls = extract_tool_calls(res)
      break if tool_calls.empty?

      results = tool_calls.map do |c|
        args = c['arguments'].is_a?(String) ? safe_parse_json(c['arguments']) : c['arguments']
        args = args.is_a?(Hash) ? symbolize_keys(args) : {}
        output = execute_tool(tools_context, c['name'], args)
        build_tool_result(c['id'], c['name'], output)
      end
      last_results = results

      # Construir uma mensagem completa com todo o contexto
      tool_calls_description = tool_calls.map do |tc|
        args = tc['arguments'].is_a?(String) ? tc['arguments'] : Oj.dump(tc['arguments'])
        "Chamada de ferramenta: #{tc['name']} com argumentos: #{args}"
      end.join("\n")
      
      tool_results_text = results.map do |r|
        text = r.dig('content', 0, 'text') || ''
        "Resultado de #{r['name']}: #{text}"
      end.join("\n")
      
      # Criar um prompt completo com todo o contexto
      full_context = [
        "Usuário solicitou: #{prompt}",
        "",
        "Você chamou as seguintes ferramentas:",
        tool_calls_description,
        "",
        "As ferramentas retornaram os seguintes resultados:",
        tool_results_text,
        "",
        "Agora, forneça uma resposta completa e útil ao usuário baseada nos resultados das ferramentas executadas."
      ].join("\n")
      
      # Manter as tools definidas para contexto, mas enviar como input simples
      payload = base_payload.dup
      payload['input'] = full_context
      res = responses.create(payload)
      res.extend(ResponseExtender)
      normalize_response_output!(res)
      res = wait_for_response_if_needed(res)
    end

    if (!res['output_text'] || res['output_text'].empty?) && last_results.is_a?(Array) && last_results.any?
      texts = last_results.map { |r| r.dig('content', 0, 'text') }.compact.join
      res['output_text'] = texts unless texts.empty?
    end
    res
  end

  def self.normalize_tool_call(call)
    return call unless call.is_a?(Hash)
    if call['type'] == 'function_call'
      {
        'id' => call['call_id'] || call['id'],
        'type' => 'tool_call',
        'name' => call['name'],
        'arguments' => call['arguments']
      }
    else
      call
    end
  end

  def self.extract_tool_calls(res)
    if res.is_a?(Hash)
      output = res['output']
      if output.is_a?(Array)
        calls = output.select { |i| i.is_a?(Hash) && (i['type'] == 'tool_call' || i['type'] == 'function_call') }
        return calls.map { |c| normalize_tool_call(c) } if calls.any?
      end
      if res['choices'].is_a?(Array)
        msg = res.dig('choices', 0, 'message') || {}
        calls = msg['tool_calls']
        if calls.is_a?(Array)
          return calls.map do |c|
            {
              'id' => c['id'],
              'type' => 'tool_call',
              'name' => c.dig('function', 'name') || c['name'],
              'arguments' => c.dig('function', 'arguments') || c['arguments']
            }
          end
        end
      end
    end
    []
  end

  def self.build_tool_result(tool_call_id, name, output)
    {
      'type' => 'tool_result',
      'tool_call_id' => tool_call_id,
      'name' => name,
      'content' => [{ 'type' => 'output_text', 'text' => output.to_s }]
    }
  end

  def self.safe_parse_json(str)
    return {} unless str.is_a?(String)
    Oj.load(str)
  rescue Oj::ParseError
    {}
  end

  def self.symbolize_keys(h)
    h.each_with_object({}) { |(k, v), acc| acc[(k.to_sym rescue k)] = v }
  end

  def self.execute_tool(ctx, name, args)
    if ctx.respond_to?(name)
      ctx.public_send(name, **args)
    else
      raise GPT::Error.new("Ferramenta não encontrada: #{name}")
    end
  end

  def self.normalize_response_output!(res)
    return unless res.is_a?(Hash)
    return if res['output_text'].is_a?(String) && !res['output_text'].empty?
    # 1) Responses API: output array
    if res['output'].is_a?(Array)
      texts = res['output'].map do |i|
        if i.is_a?(Hash)
          if i['type'] == 'output_text' || i['type'] == 'text'
            i['text']
          elsif i['type'] == 'message'
            content = i['content']
            if content.is_a?(Array)
              item = content.find { |c| c['type'] == 'output_text' || c['type'] == 'text' }
              item && item['text']
            end
          end
        end
      end.compact
      combined = texts.join
      res['output_text'] = combined unless combined.empty?
    end
    # 2) Chat style: choices[0].message.content can be string or array
    if (!res['output_text'] || res['output_text'].empty?) && res['choices'].is_a?(Array)
      msg = res.dig('choices', 0, 'message') || {}
      if msg['content'].is_a?(String)
        res['output_text'] = msg['content'] unless msg['content'].empty?
      elsif msg['content'].is_a?(Array)
        item = msg['content'].find { |c| c['type'] == 'text' || c['type'] == 'output_text' }
        res['output_text'] = item['text'] if item && item['text'] && !item['text'].empty?
      end
    end
  end

  def self.wait_for_response_if_needed(res, poll_interval: 0.5, timeout_s: 60)
    start_time = Time.now
    loop do
      if response_has_content_or_calls?(res)
        return res
      end
      id = res['id']
      break unless id
      if Time.now - start_time > timeout_s
        puts "DEBUG wait: Timeout atingido" if ENV['DEBUG_WAIT']
        break
      end
      sleep poll_interval
      refreshed = responses.get(id, include: ['output'])
      refreshed.extend(ResponseExtender) if refreshed.is_a?(Hash)
      normalize_response_output!(refreshed)
      res = refreshed
    end
    res
  end

  def self.response_has_content_or_calls?(res)
    return false unless res.is_a?(Hash)
    ot = res['output_text']
    return true if ot.is_a?(String) && !ot.empty?
    out = res['output']
    if out.is_a?(Array)
      has_text = out.any? { |i| i.is_a?(Hash) && ((i['type'] == 'output_text' || i['type'] == 'text') && i['text'] && !i['text'].empty?) }
      return true if has_text
      has_message_text = out.any? do |i|
        i.is_a?(Hash) && i['type'] == 'message' && i['content'].is_a?(Array) && i['content'].any? { |c| (c['type'] == 'text' || c['type'] == 'output_text') && c['text'] && !c['text'].empty? }
      end
      return true if has_message_text
      has_calls = out.any? { |i| i.is_a?(Hash) && (i['type'] == 'tool_call' || i['type'] == 'function_call') }
      return true if has_calls
    end
    if res['choices'].is_a?(Array)
      msg = res.dig('choices', 0, 'message') || {}
      cont = msg['content']
      return true if cont.is_a?(String) && !cont.empty?
      if cont.is_a?(Array)
        item = cont.find { |c| (c['type'] == 'text' || c['type'] == 'output_text') && c['text'] && !c['text'].empty? }
        return true if item
      end
    end
    status = res['status']
    return true if %w[completed failed cancelled error errored].include?(status.to_s)
    false
  end
end


