module W3CValidators
  class Message
    attr_accessor :type, :line, :col, :source, :explanation, :message, :message_id
    attr_accessor :text, :message_count, :element, :parent, :value
    
    MESSAGE_TYPES = [:warning, :error]

    def initialize(message_type, options = {})
      @type = message_type

      # All validators
      @line = options[:line]
      @col = options[:col]
      
      # MarkupValidator
      @source = options[:source]
      @explanation = options[:explanation]
      @message = options[:message]
      @message_id = options[:messageid]

      # FeedValidator
      @text = options[:text]
      @message_count = options[:message_count]
      @element = options[:element]
      @parent = options[:parent]
      @value = options[:value]
    end

    def is_warning?
      @type == :warning
    end

    def is_error?
      @type == :error
    end

    def to_s
      if @message and not @message.empty?
        return @type.to_s.upcase + ": line #{@line}, col #{@col}: #{@message}"
      elsif @text and not @text.empty?
        return @type.to_s.upcase + ": line #{@line}, col #{@col}: #{@text}"
      else
        return ''
      end
    end

  end
end