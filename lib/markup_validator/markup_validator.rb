require 'cgi'
require 'net/http'
require 'uri'
require 'rexml/document'

module W3CValidators
  class MarkupValidator

    USER_AGENT                = 'Ruby HTML Validator/0.9 (http://code.dunae.ca/html_validator/)'
    VERSION                   = '0.9'
    VALIDATOR_URI             = 'http://validator.w3.org/check'
    HEAD_STATUS_HEADER        = 'X-W3C-Validator-Status'
    HEAD_ERROR_COUNT_HEADER   = 'X-W3C-Validator-Errors'
    SOAP_OUTPUT_PARAM         = 'soap12'

    #DEFAULT_OPTIONS           = {:doctype => nil, :verbose => false, :debug => false, 
    #                             :ss => false, :outline => false}

    attr_reader :results

    # Create a new instance of the MarkupValidator.
    #
    # ==== Options
    # The +options+ hash allows you to set request parameters (see http://validator.w3.org/docs/api.html#requestformat) 
    # quickly. Request parameters can also be set using set_charset! and set_doctype!.
    def initialize(options = {})
      @options = options
      @validator_uri = URI.parse(VALIDATOR_URI)
    end
    
    # Specify the character encoding to use when parsing the document. 
    #
    # When +only_as_fallback+ is +true+, the given encoding will only be used as a fallback value, 
    # in case the +charset+ is absent or unrecognized. 
    def set_charset!(charset, only_as_fallback = false)
      @options[:charset] = charset
      @options[:fbc] = only_as_fallback
    end

    # Specify the Document Type (+DOCTYPE+) to use when parsing the document. 
    #
    # When +only_as_fallback+ is +true+, the given document type will only be used as a fallback value, 
    # in case the document's +DOCTYPE+ declaration is missing or unrecognized.
    def set_doctype!(doctype, only_as_fallback = false)
      @options[:doctype] = doctype
      @options[:fbd] = only_as_fallback
    end

    # When set the validator will output some extra debugging information on the validated resource (such as HTTP headers) 
    # and validation process (such as parser used, parse mode, etc.).
    #
    # Debugging information is stored in the Results +debug_messages+ hash. Custom debugging messages can be set with Results#add_debug_message.
    def set_debug!(debug = true)
      @options[:debug] = debug
    end


    # Validate the markup of an URI.
    #
    # By setting +quick+ to +true+ the URI is validated using a +HEAD+ request
    # and only returns an error count, not full error messages.
    #
    # Returns W3CValidators::Results.
    def validate_uri(uri, quick = false)
      return validate({:uri => uri}, quick)
      #if quick
      #  return quick_validate({:uri => uri})
      #else
      #  return validate({:uri => uri})
      #end
    end

    # Validate the markup of a fragment.
    #
    # Returns W3CValidators::Results.
    def validate_fragment(fragment)
      return validate({:fragment => fragment}, false)
    end
    
    # Validate the markup of a local file.
    #
    # +file_path+ must be the fully-expanded path to an HTML file.
    #
    # Returns W3CValidators::Results.
    #--
    # TODO: needs error handling
    #++
    def validate_file(file_path)
      begin
        fh = File.new(file_path, 'r+')
        markup_src = fh.read
        fh.close
        return validate({:uploaded_file => markup_src}, false)
      end
    end


protected
    # Perform a validation request.
    #
    # Returns W3CValidators::Results.
    def validate(options, quick = false) # :nodoc:
      options = create_request_options(options, false)
      response = nil
      results = nil

      if quick # perform a HEAD request
        raise ArgumentError, "a URI must be provided for HEAD requests." unless options[:uri]
        query = create_query_string_data(options)

        Net::HTTP.start(@validator_uri.host, @validator_uri.port) do |http|
          response = http.request_head(@validator_uri.path + '?' + query)
        end

        results = parse_head_response(response, options[:uri])
      else # perform a SOAP request
        if options.has_key?(:uri) # send a GET request
          query = create_query_string_data(options)

          Net::HTTP.start(@validator_uri.host, @validator_uri.port) do |http| 
            response = http.get(@validator_uri.path + '?' + query).body
          end
        else # send a multipart form request
          query, boundary = create_multipart_data(options)
          Net::HTTP.start(@validator_uri.host, @validator_uri.port) do |http|
            response = http.post2("/check", query, "Content-type" => "multipart/form-data; boundary=" + boundary).body
          end
        end
        results = parse_soap_response(response)
      end

      @results = results
    end

    # Parse the SOAP XML response into W3CValidators::Results.
    #
    # +response+ must be a Net::HTTPResponse.
    #
    # Returns Results.
    #--
    # TODO: add support for m:debug options
    #++
    def parse_soap_response(response)
      doc = REXML::Document.new(response)
      result_params = {}

      {:doctype => 'm:doctype', :uri => 'm:uri', :charset => 'm:charset', 
       :checked_by => 'm:checkedby', :validity => 'm:validity'}.each do |local_key, remote_key|        
        if val = doc.elements["env:Envelope/env:Body/m:markupvalidationresponse/#{remote_key}"]
          result_params[local_key] = val.text
        end
      end

      puts result_params.inspect
      
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

  end
end