require File.expand_path('test_helper', File.dirname(__FILE__))

require 'webrick'
require 'webrick/httpproxy'

# Test cases for the ProxyTests.
class ProxyTests < Test::Unit::TestCase
  include W3CValidators

  def setup
    @ps = WEBrick::HTTPProxyServer.new(:Port => 9999, :ServerType => Thread, :RequestCallback => Proc.new{|req,res| puts req.request_line, req.raw_header})
  
    ['TERM', 'INT'].each do |signal|
      trap(signal){ @ps.shutdown }
    end

    @ps.start

    @v = MarkupValidator.new({:proxy_server => 'localhost', :proxy_port => 9999})
    sleep 1
  end


  def test_validating_uri_with_head_request
    r = @v.validate_uri_quickly('http://code.dunae.ca/w3c_validators/test/invalid_markup.html')
    assert_errors r, 1
  end
end
