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
        if contents.is_a?(Array)
          text_item = contents.find { |c| c['type'] == 'output_text' || c['type'] == 'text' }
          return text_item['text'] if text_item && text_item['text'] && !text_item['text'].empty?
        end
        if self['output'].is_a?(Array)
          text_item = self['output'].find { |i| i['type'] == 'output_text' || i['type'] == 'text' }
          return text_item['text'] if text_item && text_item['text'] && !text_item['text'].empty?
        end
        if self['output_text'].is_a?(String) && !self['output_text'].empty?
          return self['output_text']
        end
        if self['content'].is_a?(String) && !self['content'].empty?
          return self['content']
        end
        nil
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
    
    def functions
      return [] unless tool_calls?
  
      tool_functions = tool_calls.select { |tool| tool['type'] == 'function' }
      return [] if tool_functions.empty?
  
      tool_functions.map { |function| build_function_object(function) }
    end
  
    def functions?
      functions.any?
    end
  
    def functions_run_all(context:)
      raise OpenAIExt::FunctionExecutionError, 'No functions to execute' if functions.empty?
      raise OpenAIExt::FunctionExecutionError, 'Context cannot be nil' if context.nil?
  
      functions.map { |function| function.run(context: context) }
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
      content || self['output_text'] || '[No content]'
    end
  end
end
