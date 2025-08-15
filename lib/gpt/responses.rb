module GPT
  class Responses
    def initialize(client)
      @client = client
    end

    def create(payload)
      @client.json_post('/v1/responses', body: payload)
    end

    def get(response_id, include: nil, include_obfuscation: nil, starting_after: nil, stream: nil)
      query = {}
      query['include[]'] = include if include
      query['include_obfuscation'] = include_obfuscation unless include_obfuscation.nil?
      query['starting_after'] = starting_after if starting_after
      query['stream'] = stream unless stream.nil?
      @client.json_get("/v1/responses/#{response_id}", query: query)
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
  end
end


