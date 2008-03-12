module W3CValidators
  class FeedValidator < Validator
    FEED_VALIDATOR_URI      = 'http://validator.w3.org/feed/check.cgi'

    # Create a new instance of the FeedValidator.
    #
    # ==== Options
    # You can pass in your own validator's URI (i.e. 
    # <tt>FeedValidator.new(:validator_uri => 'http://localhost/check')</tt>).
    def initialize(options = {})
      if options[:validator_uri]
        @validator_uri = URI.parse(options[:validator_uri])
        options.delete(options[:validator_uri])
      else
        @validator_uri = URI.parse(FEED_VALIDATOR_URI)
      end
      super(options)
    end
    
    # Validate a feed URI using a +SOAP+ request.
    #
    # Returns W3CValidators::Results.
    def validate_uri(url)
      return validate({:url => url})
    end

    # Validate a feed from a string.
    #
    # Returns W3CValidators::Results.
    def validate_text(text)
      return validate({:rawdata => text})
    end

    # Validate a local feed file.
    #
    # +file_path+ may be either the fully-expanded path to the file or
    # an IO object (like File).
    #
    # Returns W3CValidators::Results.
    def validate_file(file_path)
      if file_path.respond_to? :read
        src = file_path.read
      else
        src = read_local_file(file_path)
      end
      return validate_text(src)
    end

protected
    def validate(options) # :nodoc:
      options = get_request_options(options)
      response = send_request(options, :get)
      @results = parse_soap_response(response.body)
      @results
    end

    # Perform sanity checks on request params
    def get_request_options(options) # :nodoc:
      options = @options.merge(options)
     
      options[:output] = SOAP_OUTPUT_PARAM
      
      unless options[:url] or options[:rawdata]
        raise ArgumentError, "an url or rawdata is required."
      end

      # URL should be a string.  If it is a URL object, .to_s will
      # be seamless; if it is not an exception will be raised.
      if options[:url] and not options[:url].kind_of?(String)
        options[:url] = options[:url].to_s
      end
      
      options
    end

    # Parse the SOAP XML response.
    #
    # +response+ must be a Net::HTTPResponse.
    #
    # Returns W3CValidators::Results.
    def parse_soap_response(response) # :nodoc:
      doc = REXML::Document.new(response)

      result_params = {}

      {:uri => 'uri', :checked_by => 'checkedby', :validity => 'validity'}.each do |local_key, remote_key|        
        if val = doc.elements["//*[local-name()='feedvalidationresponse']/*[local-name()='#{remote_key.to_s}']"]
          result_params[local_key] = val.text
        end
      end

      results = Results.new(result_params)

      [:warning, :error].each do |msg_type|
        doc.elements.each("//*[local-name()='#{msg_type.to_s}']") do |message|
          message_params = {}
          message.each_element_with_text do |el|
            message_params[el.name.to_sym] = el.text
          end
          results.add_message(msg_type, message_params)
        end
      end

      return results

    rescue Exception => e
      handle_exception e
    end
  end
end