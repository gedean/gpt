module GPT
  class Responses
    def initialize(client)
      @client = client
    end

    def create(payload)
      res = @client.json_post('/v1/responses', body: payload)
      res.extend(GPT::ResponseExtender) if res.is_a?(Hash)
      res
    end

    def get(response_id, include: nil, include_obfuscation: nil, starting_after: nil, stream: nil)
      query = []
      Array(include).each { |v| query << ['include[]', v] } if include
      query << ['include_obfuscation', include_obfuscation] unless include_obfuscation.nil?
      query << ['starting_after', starting_after] if starting_after
      query << ['stream', stream] unless stream.nil?
      res = @client.json_get("/v1/responses/#{response_id}", query: query)
      res.extend(GPT::ResponseExtender) if res.is_a?(Hash)
      res
    end

    def delete(response_id)
      @client.json_delete("/v1/responses/#{response_id}")
    end

    def cancel(response_id)
      @client.json_post("/v1/responses/#{response_id}/cancel")
    end

    def input_items(response_id, after: nil, before: nil, include: nil, limit: nil, order: nil)
      query = {}
      query['after'] = after if after
      query['before'] = before if before
      query['include[]'] = include if include
      query['limit'] = limit if limit
      query['order'] = order if order
      @client.json_get("/v1/responses/#{response_id}/input_items", query: query)
    end

    def stream(payload)
      payload = payload.dup
      payload['stream'] = true
      @client.sse_stream('/v1/responses', body: payload) do |chunk|
        yield chunk if block_given?
      end
    end

    def stream_text(payload)
      buffer = ''.dup
      stream(payload) do |chunk|
        buffer << chunk
        parts = buffer.split("\n\n", -1)
        buffer = parts.pop || ''.dup
        parts.each do |raw_event|
          lines = raw_event.split("\n")
          event_name = nil
          data_lines = []
          lines.each do |line|
            if line.start_with?('event:')
              event_name = line.sub('event:', '').strip
            elsif line.start_with?('data:')
              data_lines << line.sub('data:', '').strip
            end
          end
          next if data_lines.empty?
          data = data_lines.join("\n")
          next if data == '[DONE]'
          begin
            json = Oj.load(data)
          rescue Oj::ParseError
            next
          end
          case event_name
          when 'response.output_text.delta'
            delta = json['delta']
            yield delta if delta && !delta.empty?
          when 'response.delta'
            delta = json.dig('delta', 'content')
            if delta.is_a?(Array)
              text_piece = delta.find { |c| c['type'] == 'output_text' || c['type'] == 'text' }
              yield(text_piece['text']) if text_piece && text_piece['text'] && !text_piece['text'].empty?
            end
          else
            # ignore other events
          end
        end
      end
      true
    end
  end
end


