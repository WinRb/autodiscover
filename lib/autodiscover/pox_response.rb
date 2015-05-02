module Autodiscover
  class PoxResponse

    RESPONSE_SCHEMA = "http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a"

    attr_reader :xml

    def initialize(response)
      @xml = Nokogiri::XML(response)
    end

    def exchange_version
      hexver = xml.xpath("//s:ServerVersion", s: RESPONSE_SCHEMA)[0].text
      ServerVersionParser.new(hexver).exchange_version
    end

    def ews_url
      v = xml.xpath("//s:EwsUrl[../s:Type='EXPR']", s: RESPONSE_SCHEMA).text
      v.empty? ? nil : v
    end

  end
end
