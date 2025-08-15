class GPT::Error < StandardError
  attr_reader :status, :headers, :response

  def initialize(message, status: nil, headers: nil, response: nil)
    super(message)
    @status = status
    @headers = headers
    @response = response
  end
end


