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

  def self.ask(prompt, model: 'gpt-5', stream: false, text_stream: false, **opts, &block)
    payload = { 'model' => model, 'input' => prompt }
    opts.each { |k, v| payload[k.to_s] = v }
    if stream
      responses.stream(payload) do |chunk|
        yield chunk if block_given?
      end
    elsif text_stream
      responses.stream_text(payload) do |text|
        yield text if block_given?
      end
    else
      res = responses.create(payload)
      res.extend(ResponseExtender)
      res
    end
  end
end


