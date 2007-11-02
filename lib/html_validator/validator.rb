require 'cgi'
require 'net/http'
require 'uri'
require 'rexml/document'

module HTMLValidator
  class Validator

    USER_AGENT                = 'Ruby HTML Validator/0.9 (http://code.dunae.ca/html_validator/)'
    VERSION                   = '0.9'
    VALIDATOR_URI             = 'http://validator.w3.org/check'
    HEAD_STATUS_HEADER        = 'X-W3C-Validator-Status'
    HEAD_ERROR_COUNT_HEADER   = 'X-W3C-Validator-Errors'
    SOAP_OUTPUT_PARAM         = 'soap12'

    attr_accessor :results

    def self.quick_validate(url, options = {})
      options.merge!(:uri => url)

      request = create_request(options.merge!(:uri => url))

      response = nil
      Net::HTTP.start(request.host, request.port) do |http|
        response = http.request_head(request.path)
      end

      v_status = response[HEAD_STATUS_HEADER].downcase.to_sym
      v_errors = response[HEAD_ERROR_COUNT_HEADER].to_i
      
      validity = (v_status == :valid)
      results = Results.new(:uri => url, :validity => validity)
      v_errors.times { results.add_error() }

      results
    end
    
    
    
    
    
    

    #--
    # TODO: add support for m:debug options
    #++
    def self.validate(url, options = {})
      options.merge!(:output => SOAP_OUTPUT_PARAM, :uri => url)

      request = create_request(options)

      response = nil
      Net::HTTP.start(request.host, request.port) { |http| response = http.get(request.path).body }

      doc = REXML::Document.new(response)

      self.parse_soap_response(doc)
    end

  private
    # Parse the SOAP XML response into HTMLValidator::Results.
    def self.parse_soap_response(response)
      result_params = {}
      {:doctype => 'm:doctype', :uri => 'm:uri', :charset => 'm:charset', 
       :checked_by => 'm:checkedby', :validity => 'm:validity'}.each do |local_key, remote_key|        
        if val = response.elements["env:Envelope/env:Body/m:markupvalidationresponse/#{remote_key}"]
          result_params[local_key] = val.text
        end
      end

      results = Results.new(result_params)
      {:warning => 'm:warnings/m:warninglist/m:warning', :error => 'm:errors/m:errorlist/m:error'}.each do |local_type, remote_type|
        response.elements.each("env:Envelope/env:Body/m:markupvalidationresponse/#{remote_type}") do |message|
          message_params = {}
          message.each_element_with_text do |el|
            message_params[el.name.to_sym] = el.text
          end
          results.add_message(local_type, message_params)
        end
      end
      results
    end

    def self.create_request(options) # :nodoc:
      options = {:uri => nil, :uploaded_file => nil, :fragment => nil, :doctype => nil, 
                 :verbose => 0, :debug => 0, :ss => 0, :outline => 0
                }.merge(options)

      raise ArgumentError unless options[:uri] or options[:uploaded_file] or options[:fragment]

      request_uri = VALIDATOR_URI + '?'
      options.each { |k, v| request_uri += "#{k}=#{CGI.escape(v.to_s)}&" }
      URI.parse(request_uri)
    end
  end
end