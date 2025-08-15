module GPT; end

require 'oj'
require 'net/http'
require 'uri'

require_relative 'gpt/error'
require_relative 'gpt/client'
require_relative 'gpt/responses'

module GPT
  def self.client
    @client ||= Client.new
  end

  def self.responses
    @responses ||= Responses.new(client)
  end
end


