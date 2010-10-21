require 'cgi'
require 'net/http'
require 'uri'
require 'nokogiri'

require 'w3c_validators/exceptions'
require 'w3c_validators/constants'
require 'w3c_validators/results'
require 'w3c_validators/message'

module W3CValidators
  # Base class for MarkupValidator and FeedValidator.
  class Validator
    VERSION                   = '1.0.2'
    USER_AGENT                = "Ruby W3C Validators/#{Validator::VERSION} (http://code.dunae.ca/w3c_validators/)"
    HEAD_STATUS_HEADER        = 'X-W3C-Validator-Status'
    HEAD_ERROR_COUNT_HEADER   = 'X-W3C-Validator-Errors'
    SOAP_OUTPUT_PARAM         = 'soap12'

    attr_reader :results, :validator_uri

    # Create a new instance of the Validator.
    #
    # +options+ Hash can optionally include
    # - +proxy_host+
    # - +proxy_port+
    # - +proxy_user+
    # - +proxy_pass+
    def initialize(options = {})
      @options = {:proxy_host => nil, 
                  :proxy_port => nil,
                  :proxy_user => nil,
                  :proxy_pass => nil}.merge(options)
    end

  protected
    # Perform a validation request.
    #
    # +request_mode+ must be either <tt>:get</tt>, <tt>:head</tt> or <tt>:post</tt>.
    #
    # Returns Net::HTTPResponse.
    def send_request(options, request_mode = :get, following_redirect = false, params_to_post = [])
      response = nil
      results = nil

      r = Net::HTTP::Proxy(@options[:proxy_host], 
                       @options[:proxy_port],
                       @options[:proxy_user], 
                       @options[:proxy_pass]).start(@validator_uri.host, @validator_uri.port) do |http|    

        case request_mode
          when :head
            # perform a HEAD request
            raise ArgumentError, "a URI must be provided for HEAD requests." unless options[:uri]
            query = create_query_string_data(options)
            response = http.request_head(@validator_uri.path + '?' + query)
          when :get 
            # send a GET request
            query = create_query_string_data(options)          
            response = http.get(@validator_uri.path + '?' + query)
          when :post
            # send a multipart form request
            post = {}
            [params_to_post].flatten.each do |param|
              post[param] = options.delete(param)
            end
              
            qs = create_query_string_data(options)
            
            query, boundary = create_multipart_data(post)
            response = http.post2(@validator_uri.path + '?' + qs, query, "Content-type" => "multipart/form-data; boundary=" + boundary)
          else
            raise ArgumentError, "request_mode must be either :get, :head or :post"
        end
      end

      if response.kind_of?(Net::HTTPRedirection) and response['location'] and not following_redirect
        options[:url] = response['location']
        return send_request(options, request_mode, true)
      end

      response.value
      return response

      rescue Exception => e
        handle_exception e
    end

    def create_multipart_data(options) # :nodoc:
      boundary = '349832898984244898448024464570528145'

      # added 2008-03-12: HTML5 validator expects 'file' and 'content' to be the last fields so
      # we process those params separately
      last_params = []

      # added 2008-03-12: HTML5 validator expects 'file' instead of 'uploaded_file'
      if options[:file] and !options[:uploaded_file]
        options[:uploaded_file] = options[:file]
      end

      if options[:uploaded_file]
        filename = options[:file_path] ||= 'temp.html'
        content = options[:uploaded_file]
        last_params << "Content-Disposition: form-data; name=\"uploaded_file\"; filename=\"#{filename}\"\r\n" + "Content-Type: text/html\r\n" + "\r\n" + "#{content}\r\n"
        options.delete(:uploaded_file)
        options.delete(:file_path)
      end
      
      if options[:content]
          last_params << "Content-Disposition: form-data; name=\"#{CGI::escape('content')}\"\r\n" + "\r\n" + "#{options[:content]}\r\n"
      end

      misc_params = []
      options.each do |key, value|
        if value
          misc_params << "Content-Disposition: form-data; name=\"#{CGI::escape(key.to_s)}\"\r\n" + "\r\n" + "#{value}\r\n"
        end
      end

      params = misc_params + last_params

      multipart_query = params.collect {|p| '--' + boundary + "\r\n" + p}.join('') + "--" + boundary + "--\r\n" 

      [multipart_query, boundary]
    end

    def create_query_string_data(options) # :nodoc:
      qs = ''
      options.each do |key, value| 
        if value
          qs += "#{key}=" + CGI::escape(value.to_s) + "&"
        end
      end
      qs
    end

    def read_local_file(file_path) # :nodoc:
      IO.read(file_path)
    end

  private
    #--
    # Big thanks to ara.t.howard and Joel VanderWerf on Ruby-Talk for the exception handling help.
    #++
    def handle_exception(e, msg = '') # :nodoc:
      case e      
        when Net::HTTPServerException, SocketError
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
