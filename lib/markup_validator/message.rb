module W3CValidators
  class Message
    attr_accessor :type, :line, :col, :source, :explanation, :message, :message_id
    
    MESSAGE_TYPES = [:warning, :error]

    def initialize(message_type, options = {})
      @type = message_type
      @line = options[:line]
      @col = options[:col]
      @source = options[:source]
      @explanation = options[:explanation]
      @message = options[:message]
      @message_id = options[:messageid]
    end

    def is_error?
      @type == :error
    end
    
    def is_warning?
      @type == :warning
    end

    def to_s
      return '' unless @message and not @message.empty?
      @type.to_s.upcase + ": line #{@line}, col #{@col}: #{@message}"
    end

  end
end