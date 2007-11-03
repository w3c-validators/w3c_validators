module W3CValidators
  class Results
    attr_reader :uri, :checked_by, :doctype, :charset, :validity, :debug_messages

    def initialize(options = {})
      @messages = []
      @uri = options[:uri]
      @checked_by = options[:checked_by]
      @doctype = options[:doctype]
      @charset = options[:charset]
      @validity = options[:validity]
      @debug_messages = {}
    end

    def add_message(type, params = {})
      @messages << Message.new(type, params)
    end    

    def add_error(params = {})
      add_message(:error, params)
    end

    def add_warning(params = {})
      add_message(:warnings, params)
    end

    def add_debug_message(key, val)
      @debug_messages[key] = val
    end

    def is_valid?
      @validity.downcase.strip == 'true'
    end

    # Returns an array of Message objects.
    def errors
      errors = []
      @messages.each { |msg| errors << msg if msg.is_error? }
      errors
    end

    # Returns an array of Message objects.
    def warnings
      errors = []
      @messages.each { |msg| errors << msg if msg.is_warning? }
      errors
    end
  end
end