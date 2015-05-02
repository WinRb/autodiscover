module Autodiscover
  class PoxRequest

    attr_reader :client

    # @param client [Autodiscover::Client]
    def initialize(client)
      @client = client
    end

    def autodiscover
      available_urls.each do |url|
        begin
          response = client.http.post(url, request_body, {'Content-Type' => 'text/xml; charset=utf-8'})
          return PoxResponse.new(response.body) if good_response?(response)
        rescue Errno::ENETUNREACH
          next
        end
      end
    end


    private


    def good_response?(response)
      response.status == 200
    end

    def available_urls(&block)
      return to_enum(__method__) unless block_given?
      formatted_https_urls.each {|url|
        yield url
      }
      yield redirected_http_url
    end

    def formatted_https_urls
      @formatted_urls ||= %W{
        https://#{client.domain}/autodiscover/autodiscover.xml
        https://autodiscover.#{client.domain}/autodiscover/autodiscover.xml
      }
    end

    def redirected_http_url
      @redirected_http_url ||=
        begin
          response = client.http.get("http://autodiscover.#{client.domain}/autodiscover/autodiscover.xml")
          (response.status == 302) ? response.headers["Location"] : nil
        end
    end

    def request_body
      Nokogiri::XML::Builder.new do |xml| 
        xml.Autodiscover('xmlns' => 'http://schemas.microsoft.com/exchange/autodiscover/outlook/requestschema/2006') {
          xml.Request {
            xml.EMailAddress client.email
            xml.AcceptableResponseSchema 'http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a'
          }
        }
      end.to_xml
    end

  end
end
