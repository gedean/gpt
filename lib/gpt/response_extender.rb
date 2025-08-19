module GPT
  module ResponseExtender
    def message
      if self['choices']
        dig('choices', 0, 'message') || {}
      else
        output_message = if self['output'].is_a?(Array)
          self['output'].find { |i| i['type'] == 'message' } || self['output'].first
        end
        output_message || {}
      end
    end

    def content
      if self['choices']
        dig('choices', 0, 'message', 'content')
      else
        msg = message
        contents = msg && msg['content']
        return nil unless contents.is_a?(Array)
        text_item = contents.find { |c| c['type'] == 'output_text' || c['type'] == 'text' }
        text_item && text_item['text']
      end
    end

    def content?
      !content.nil? && !content.empty?
    end

    def usage
      self['usage'] || {}
    end

    def prompt_tokens
      usage['prompt_tokens'] || 0
    end

    def completion_tokens
      usage['completion_tokens'] || 0
    end

    def total_tokens
      usage['total_tokens'] || 0
    end

    def model
      self['model']
    end

    def created_at
      if self['created']
        Time.at(self['created'])
      elsif self['created_at']
        Time.at(self['created_at'])
      end
    end

    def to_h
      {
        content: content,
        role: message['role'],
        model: model,
        usage: usage,
        created_at: created_at
      }.compact
    end

    def to_s
      content || '[No content]'
    end
  end
end


