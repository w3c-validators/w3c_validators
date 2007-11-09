require 'cgi'
require 'net/http'
require 'uri'
require 'rexml/document'
require 'logger'

module W3CValidators
  class MarkupValidator

    USER_AGENT                = 'Ruby W3C Validator/0.9 (http://code.dunae.ca/w3c_validators/)'
    VERSION                   = '0.9.0'
    VALIDATOR_URI             = 'http://validator.w3.org/check'
    HEAD_STATUS_HEADER        = 'X-W3C-Validator-Status'
    HEAD_ERROR_COUNT_HEADER   = 'X-W3C-Validator-Errors'
    SOAP_OUTPUT_PARAM         = 'soap12'

    attr_reader :results, :validator_uri

    # Create a new instance of the MarkupValidator.
    #
    # ==== Options
    # The +options+ hash allows you to set request parameters (see http://validator.w3.org/docs/api.html#requestformat) 
    # quickly. Request parameters can also be set using set_charset!, set_debug! and set_doctype!.
    #
    # You can pass in your own validator's URI (i.e. <tt>MarkupValidator.new({:validator_uri => 'http://validator.localhost/check'})</tt>).
    def initialize(options = {})
      if options[:validator_uri]
        @validator_uri = URI.parse(options[:validator_uri])
        options.delete(options[:validator_uri])
      else
        @validator_uri = URI.parse(VALIDATOR_URI)
      end
      @options = options
    end
    
    # Specify the character encoding to use when parsing the document. 
    #
    # When +only_as_fallback+ is +true+, the given encoding will only be 
    # used as a fallback value, in case the +charset+ is absent or unrecognized. 
    #
    # +charset+ can be a string (e.g. <tt>set_charset!('utf-8')</tt>) or 
    # a symbol (e.g. <tt>set_charset!(:utf_8)</tt>) from the W3CValidators::CHARSETS hash.
    #
    # Has no effect when using validate_uri_quickly.
    def set_charset!(charset, only_as_fallback = false)
      if charset.kind_of?(Symbol)
        if CHARSETS.has_key?(charset)
          charset = CHARSETS[charset]
        else
          return
        end
      end
      @options[:charset] = charset
      @options[:fbc] = only_as_fallback
    end

    # Specify the Document Type (+DOCTYPE+) to use when parsing the document. 
    #
    # When +only_as_fallback+ is +true+, the given document type will only be 
    # used as a fallback value, in case the document's +DOCTYPE+ declaration 
    # is missing or unrecognized.
    #
    # +doctype+ can be a string (e.g. <tt>set_doctype!('HTML 3.2')</tt>) or 
    # a symbol (e.g. <tt>set_doctype!(:html32)</tt>) from the W3CValidators::DOCTYPES hash.
    #
    # Has no effect when using validate_uri_quickly.
    def set_doctype!(doctype, only_as_fallback = false)
      if doctype.kind_of?(Symbol)
        if DOCTYPES.has_key?(doctype)
          doctype = DOCTYPES[doctype]
        else
          return
        end
      end
      @options[:doctype] = doctype
      @options[:fbd] = only_as_fallback
    end

    # When set the validator will output some extra debugging information on the validated resource (such as HTTP headers) 
    # and validation process (such as parser used, parse mode, etc.).
    #
    # Debugging information is stored in the Results +debug_messages+ hash. Custom debugging messages can be set with Results#add_debug_message.
    #
    # Has no effect when using validate_uri_quickly.
    def set_debug!(debug = true)
      @options[:debug] = debug
    end

    # Validate the markup of an URI using a +SOAP+ request.
    #
    # Returns W3CValidators::Results.
    def validate_uri(uri)
      return validate({:uri => uri}, false)
    end

    # Validate the markup of an URI using a +HEAD+ request.
    #
    # Returns W3CValidators::Results with an error count, not full error messages.
    def validate_uri_quickly(uri)
      return validate({:uri => uri}, true)
    end

    # Validate the markup of a fragment.
    #
    # Returns W3CValidators::Results.
    def validate_fragment(fragment)
      return validate({:fragment => fragment}, false)
    end
    
    # Validate the markup of a local file.
    #
    # +file_path+ must be the fully-expanded path to the file.
    #
    # Returns W3CValidators::Results.
    #--
    # TODO: needs error handling
    #++
    def validate_file(file_path)
      fh = File.new(file_path, 'r+')
      markup_src = fh.read
      fh.close
      return validate({:uploaded_file => markup_src}, false)
    end

protected
    # Perform a validation request.
    #
    # Returns W3CValidators::Results.
    def validate(options, quick = false)
      options = create_request_options(options, false)
      response = nil
      results = nil

      begin 
        Net::HTTP.start(@validator_uri.host, @validator_uri.port) do |http|
          if quick 
            # perform a HEAD request
            raise ArgumentError, "a URI must be provided for HEAD requests." unless options[:uri]
            query = create_query_string_data(options)
            response = http.request_head(@validator_uri.path + '?' + query)
            results = parse_head_response(response, options[:uri])
          else 
            # perform a SOAP request
            if options.has_key?(:uri) or options.has_key?(:fragment) 
              # send a GET request
              query = create_query_string_data(options)          
              response = http.get(@validator_uri.path + '?' + query)
            else 
              # send a multipart form request
              query, boundary = create_multipart_data(options)
              response = http.post2("/check", query, "Content-type" => "multipart/form-data; boundary=" + boundary)
            end
            response.value
            results = parse_soap_response(response.body)
          end
        end
      rescue Exception => e
        handle_exception e
      end
      @results = results
    end

    # Parse the SOAP XML response.
    #
    # +response+ must be a Net::HTTPResponse.
    #
    # Returns W3CValidators::Results.
    def parse_soap_response(response)
      begin
        doc = REXML::Document.new(response)
      rescue Exception => e
        handle_exception e
      end
      result_params = {}

      {:doctype => 'm:doctype', :uri => 'm:uri', :charset => 'm:charset', 
       :checked_by => 'm:checkedby', :validity => 'm:validity'}.each do |local_key, remote_key|        
        if val = doc.elements["env:Envelope/env:Body/m:markupvalidationresponse/#{remote_key}"]
          result_params[local_key] = val.text
        end
      end

      results = Results.new(result_params)

      {:warning => 'm:warnings/m:warninglist/m:warning', :error => 'm:errors/m:errorlist/m:error'}.each do |local_type, remote_type|
        doc.elements.each("env:Envelope/env:Body/m:markupvalidationresponse/#{remote_type}") do |message|
          message_params = {}
          message.each_element_with_text do |el|
            message_params[el.name.to_sym] = el.text
          end
          results.add_message(local_type, message_params)
        end
      end
      
      doc.elements.each("env:Envelope/env:Body/m:markupvalidationresponse/m:debug") do |debug|
        results.add_debug_message(debug.attribute('name').value, debug.text)
      end
      results
    end

    # Parse the HEAD response into HTMLValidator::Results.
    #
    # +response+ must be a Net::HTTPResponse.
    #
    # Returns Results.
    def parse_head_response(response, validated_uri = nil) # :nodoc:
      validity = (response[HEAD_STATUS_HEADER].downcase == 'valid')
      
      results = Results.new(:uri => validated_uri, :validity => validity)

      # Fill the results with empty error messages so we can count them
      errors = response[HEAD_ERROR_COUNT_HEADER].to_i
      errors.times { results.add_error }

      results
    end

    # Perform sanity checks on request params
    def create_request_options(options, quick) # :nodoc:
      options = @options.merge(options)
     

      options[:output] = SOAP_OUTPUT_PARAM unless quick
      
      unless options[:uri] or options[:uploaded_file] or options[:fragment]
        raise ArgumentError, "an uri, uploaded file or fragment is required."
      end

      # URI should be a string.  If it is a URI object, .to_s will
      # be seamless; if it is not an exception will be raised.
      if options[:uri] and not options[:uri].kind_of?(String)
        options[:uri] = options[:uri].to_s
      end
      
      # Convert booleans to integers
      [:fbc, :fbd, :verbose, :debug, :ss, :outline].each do |k|
        if options.has_key?(k) and not options[k].kind_of?(Fixnum)
          options[k] = options[k] ? 1 : 0
        end
      end

      options
    end

    def create_multipart_data(options) # :nodoc:
      boundary = '349832898984244898448024464570528145'
      params = []
      if options[:uploaded_file]
        filename = options[:file_path] ||= 'temp.html'
        content = options[:uploaded_file]
        params << "Content-Disposition: form-data; name=\"uploaded_file\"; filename=\"#{filename}\"\r\n" + "Content-Type: text/html\r\n" + "\r\n" + "#{content}\r\n"
        options.delete(:uploaded_file)
        options.delete(:file_path)
      end
      
      options.each do |key, value|
        if value
          params << "Content-Disposition: form-data; name=\"#{CGI::escape(key.to_s)}\"\r\n" + "\r\n" + "#{value}\r\n"
        end
      end

      multipart_query = params.collect {|p| '--' + boundary + "\r\n" + p}.join('') + "--" + boundary + "--\r\n" 

      [multipart_query, boundary]
    end

    def create_query_string_data(options) # :nodoc:
      qs = ''
      options.each do |key, value| 
        if value
          qs += "#{key}=" + URI.escape(value.to_s) + "&"
        end
      end
      qs
    end

  private
    #--
    # Big thanks to ara.t.howard and Joel VanderWerf on Ruby-Talk for the exception handling help.
    #++
    def handle_exception(e, msg = '')
      case e      
        when Net::HTTPServerException
          msg = "unable to connect to the validator at #{@validator_uri} (response was #{e.message})."
          raise ValidatorUnavailable, msg, caller
        when REXML::ParseException
          msg = "unable to parse the response from the validator."
          raise ParsingError, msg, caller
        else
          raise e
      end

      if e.respond_to?(:error_handler_before)
        fcall(e, :error_handler_before, self)
      end

      if e.respond_to?(:error_handler_instead)
        fcall(e, :error_handler_instead, self)
      else
        if e.respond_to? :status
          exit_status(( e.status ))
        end

        if SystemExit === e
          stderr.puts e.message unless(SystemExit === e and e.message.to_s == 'exit') ### avoids double message for abort('message')
        end
      end

      if e.respond_to?(:error_handler_after)
        fcall(e, :error_handler_after, self)
      end

      exit_status(( exit_failure )) if exit_status == exit_success
      exit_status(( Integer(exit_status) rescue(exit_status ? 0 : 1) ))
      exit exit_status
    end 
  end
end