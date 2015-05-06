module Autodiscover
  class Client

    attr_reader :domain, :email, :http

    # @param email [String] An e-mail to use for autodiscovery. It will be
    #   used as the default username.
    # @param password [String]
    # @param username [String] An optional username if you want to authenticate
    #   with something other than the e-mail. For instance DOMAIN\user
    # @param domain [String] An optional domain to provide as an override for
    #   the one parsed from the e-mail.
    def initialize(email:, password:, username: nil, domain: nil)
      @email = email
      @domain = domain || @email.split("@").last
      @http = HTTPClient.new
      @username = username || email
      @http.set_auth(nil, @username, password)
    end

    # @param type [Symbol] The type of response. Right now this is just :pox
    def autodiscover(type: :pox)
      case type
      when :pox
        PoxRequest.new(self).autodiscover
      else
        raise Autodiscover::ArgumentError, "Not a valid autodiscover type (#{type})."
      end
    end

  end
end
