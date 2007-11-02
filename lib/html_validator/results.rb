module HTMLValidator
  class Results
    attr_accessor :uri, :checked_by, :doctype, :charset, :validity

    def initialize(options = {})
      @messages = []      
      @uri = options[:uri]
      @checked_by = options[:checked_by]
      @doctype = options[:doctype]
      @charset = options[:charset]
      @validity = options[:validity]
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

    def is_valid?
      @validity.downcase.strip == 'true'
    end

    # Returns an array of HTMLValidator messages.
    def errors
      errors = []
      @messages.each { |msg| errors << msg if msg.is_error? }
      errors
    end

    # Returns an array of HTMLValidator messages.
    def warnings
      errors = []
      @messages.each { |msg| errors << msg if msg.is_warning? }
      errors
    end
  end
end