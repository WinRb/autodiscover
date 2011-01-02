#--
# Copyright (c) 2010-2011 WIMM Labs, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'httpclient'
require 'nokogiri'

module Autodiscover
  REDIRECT_LIMIT = 10  # attempts
  CONNECT_TIMEOUT_DEFAULT = 10  # seconds

  # Client objects are used to make queries to the autodiscover server, to
  # specify configuration values, and to maintain state between requests.
  class Client
    # Creates a Client object.
    #
    # The following options can be specified:
    #
    # <tt>:connect_timeout</tt>::  Number of seconds to wait when trying to establish
    #                              a connection. The default value is 10 seconds.
    # <tt>:debug_dev</tt>::        Device that debug messages and all HTTP
    #                              requests and responses are dumped to. The debug
    #                              device must respond to <tt><<</tt> for dump. 
    def initialize(options={})
      @debug_dev = options[:debug_dev]

      @http = HTTPClient.new
      @http.connect_timeout = options[:connect_timeout] || CONNECT_TIMEOUT_DEFAULT
      @http.debug_dev = @debug_dev if @debug_dev

      @redirect_count = 0
    end

    # Get a Services object from an \Autodiscover server that is
    # available on an authenticated endpoint determined by the
    # specified Credentials object.
    def get_services(credentials, reset_redirect_count=true)
      @redirect_count = 0 if reset_redirect_count

      req_body = build_request_body credentials.email

      try_standard_secure_urls(credentials, req_body) ||
      try_standard_redirection_url(credentials, req_body) ||
      try_dns_serv_record
    end

    private

    def try_standard_secure_urls(credentials, req_body)
      response = nil
      [ "https://#{credentials.smtp_domain}/autodiscover/autodiscover.xml",
        "https://autodiscover.#{credentials.smtp_domain}/autodiscover/autodiscover.xml"
      ].each do |url|
        @debug_dev << "AUTODISCOVER: trying #{url}\n" if @debug_dev
        response = try_secure_url(url, credentials, req_body)
        break if response
      end
      response
    end

    def try_standard_redirection_url(credentials, req_body)
      url = "http://autodiscover.#{credentials.smtp_domain}/autodiscover/autodiscover.xml"
      @debug_dev << "AUTODISCOVER: looking for redirect from #{url}\n" if @debug_dev
      response = @http.get(url) rescue nil
      return nil unless response

      if response.status_code == 302
        try_redirect_url(response.header['Location'].first, credentials, req_body)
      else
        nil
      end
    end

    def try_secure_url(url, credentials, req_body)
      @http.set_auth(url, credentials.email, credentials.password)

      response = @http.post(url, req_body, {'Content-Type' => 'text/xml; charset=utf-8'}) rescue nil
      return nil unless response

      if response.status_code == 302
        try_redirect_url(response.header['Location'].first, credentials, req_body)
      elsif HTTP::Status.successful?(response.status_code)
        result = parse_response(response.content)
        case result
          when Autodiscover::Services
            return result
          when Autodiscover::RedirectUrl
            try_redirect_url(result.url, credentials, req_body)
          when Autodiscover::RedirectAddress
            begin
              credentials.email = result.address
            rescue ArgumentError
              # An invalid email address was returned
              return nil
            end
            
            try_redirect_addr(credentials)
        end
      else
        nil
      end
    end

    def try_redirect_url(url, credentials, req_body)
      @redirect_count += 1
      return nil if @redirect_count > REDIRECT_LIMIT

      # Only permit redirects to secure addresses
      return nil unless url =~ /^https:/i
      try_secure_url(url, credentials, req_body)
    end

    def try_redirect_addr(credentials)
      @redirect_count += 1
      return nil if @redirect_count > REDIRECT_LIMIT

      get_services(credentials, false)
    end

    def try_dns_serv_record
      nil
    end

    def build_request_body(email)
      Nokogiri::XML::Builder.new do |xml| 
        xml.Autodiscover('xmlns' => 'http://schemas.microsoft.com/exchange/autodiscover/outlook/requestschema/2006') {
          xml.Request {
            xml.EMailAddress email
            xml.AcceptableResponseSchema 'http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a'
          }
        }
      end.to_xml
    end

    NAMESPACES = {
      'a' => 'http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006',
      'o' => 'http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a'        
    }  #:nodoc:

    def parse_response(body)
      doc = parse_xml body
      return nil unless doc

      # The response must include an Account element. Return an error if not found.
      account_e = doc.at_xpath('a:Autodiscover/o:Response/o:Account', NAMESPACES)
      return nil unless account_e

      # The response must include an Action element. Return an error if not found.
      action_e = account_e.at_xpath('o:Action', NAMESPACES)
      return nil unless action_e

      case action_e.content
        when /^settings$/i
          # Response contains configuration settings in <Protocol> elements
          # Only care about about "EXPR" type protocol configuration values
          # for accessing Exchange services outside of the firewall
          settings = {}
          if protocol_e = account_e.at_xpath('o:Protocol[o:Type="EXPR"]', NAMESPACES)
            # URL for the Web services virtual directory.
            ews_url_e = protocol_e.at_xpath('o:EwsUrl', NAMESPACES)
            settings['ews_url'] = ews_url_e.content if ews_url_e
            # Time to Live (TTL) in hours. Default is 1 hour if no element is
            # returned.
            ttl_e = protocol_e.at_xpath('o:TTL', NAMESPACES)
            settings['ttl'] = ttl_e ? ttl_e.content : 1
          end
          Autodiscover::Services.new(settings)
        when /^redirectAddr$/i
          # Response contains a new address that must be used to re-­Autodiscover
          redirect_addr_e = account_e.at_xpath('o:RedirectAddr', NAMESPACES)
          address = redirect_addr_e ? redirect_addr_e.content : nil
          return nil unless address
          Autodiscover::RedirectAddress.new(address)
        when /^redirectUrl$/i
          # Response contains a new URL that must be used to re-Autodiscover
          redirect_url_e = account_e.at_xpath('o:RedirectUrl', NAMESPACES)
          url = redirect_url_e ? redirect_url_e.content : nil
          return nil unless url
          Autodiscover::RedirectUrl.new(url)          
        else
          nil
      end
    end

    def parse_xml(doc)
      Nokogiri::XML(doc) { |c| c.options = Nokogiri::XML::ParseOptions::STRICT }
    rescue Nokogiri::XML::SyntaxError
      nil
    end
  end

  class RedirectUrl  #:nodoc: all
    attr_reader :url

    def initialize(url)
      @url = url
    end
  end

  class RedirectAddress  #:nodoc: all
    attr_reader :address

    def initialize(address)
      @address = address
    end
  end
end