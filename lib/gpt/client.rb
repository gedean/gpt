module GPT
  class Client
    DEFAULT_BASE_URL = 'https://api.openai.com'.freeze
    DEFAULT_TIMEOUT = 120

    attr_reader :api_key, :base_url, :timeout, :organization, :project

    def initialize(api_key: ENV['OPENAI_API_KEY'], base_url: nil, timeout: nil, organization: ENV['OPENAI_ORG_ID'], project: ENV['OPENAI_PROJECT_ID'])
      @api_key = api_key
      @base_url = base_url || DEFAULT_BASE_URL
      @timeout = (timeout || DEFAULT_TIMEOUT).to_i
      @organization = organization
      @project = project
    end

    def json_get(path, query: nil)
      request(:get, path, query: query)
    end

    def json_post(path, body: nil)
      request(:post, path, body: body)
    end

    def json_delete(path)
      request(:delete, path)
    end

    def sse_stream(path, body: nil, query: nil)
      uri = build_uri(path, query: query)
      http = build_http(uri)
      req = Net::HTTP::Post.new(uri)
      apply_headers(req)
      req['Accept'] = 'text/event-stream'
      req.content_type = 'application/json'
      req.body = body ? Oj.dump(body) : nil

      http.request(req) do |res|
        raise_http_error(res) unless res.is_a?(Net::HTTPSuccess)
        res.read_body do |chunk|
          yield chunk if block_given?
        end
      end
      true
    end

    private

    def request(method, path, body: nil, query: nil)
      uri = build_uri(path, query: query)
      http = build_http(uri)
      req = build_request(method, uri)
      apply_headers(req)
      if body
        req.content_type = 'application/json'
        req.body = Oj.dump(body)
      end
      res = http.request(req)
      parse_response(res)
    end

    def build_uri(path, query: nil)
      uri = URI.join(base_url, path)
      if query && query.any?
        uri.query = URI.encode_www_form(query)
      end
      uri
    end

    def build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.read_timeout = timeout
      http.open_timeout = timeout
      http.write_timeout = timeout
      http
    end

    def build_request(method, uri)
      case method
      when :get then Net::HTTP::Get.new(uri)
      when :post then Net::HTTP::Post.new(uri)
      when :delete then Net::HTTP::Delete.new(uri)
      else
        raise ArgumentError, 'unsupported method'
      end
    end

    def apply_headers(req)
      req['Authorization'] = "Bearer #{api_key}"
      req['OpenAI-Organization'] = organization if organization && !organization.empty?
      req['OpenAI-Project'] = project if project && !project.empty?
      req['User-Agent'] = 'gpt-ruby/0.0.1'
    end

    def parse_response(res)
      body = res.body
      if res['Content-Type']&.include?('application/json')
        parsed = body && !body.empty? ? Oj.load(body) : nil
      else
        parsed = body
      end

      unless res.is_a?(Net::HTTPSuccess)
        message = if parsed.is_a?(Hash) && parsed['error']
          parsed['error']['message'] || parsed['error'].to_s
        else
          body.to_s
        end
        raise GPT::Error.new(message, status: res.code.to_i, headers: res.each_header.to_h, response: parsed)
      end

      parsed
    end

    def raise_http_error(res)
      raise GPT::Error.new("HTTP #{res.code}", status: res.code.to_i, headers: res.each_header.to_h, response: res.body)
    end
  end
end


