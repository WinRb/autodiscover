# Prefix LOAD_PATH with lib sub-directory to ensure we're
# testing the intended version.
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

# Load HTTPClient before webmock so the HTTPClient adapter will be used.
require 'httpclient'
require 'webmock/test_unit'
require 'test/unit'
require 'autodiscover'

SETTINGS_AUTODISCOVER_RESPONSE = <<END
<?xml version="1.0" encoding="utf-8"?>
<Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006">
  <Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a">
    <User>
      <DisplayName>spiff</DisplayName>
      <LegacyDN>/o=outlook/ou=Exchange Administrative Group (spacecommand)/cn=Recipients/cn=spiff</LegacyDN>
      <DeploymentId>11111111-2222-3333-4444-555555555555</DeploymentId>
    </User>
    <Account>
      <AccountType>email</AccountType>
      <Action>settings</Action>
      <Protocol>
        <Type>EXPR</Type>
        <Server>outlook.spacecommand.sol</Server>
        <SSL>On</SSL>
        <AuthPackage>Basic</AuthPackage>
        <EwsUrl>https://ews.spacecommand.sol/EWS/Exchange.asmx</EwsUrl>
      </Protocol>
    </Account>
  </Response>
</Autodiscover>
END

REDIRECTURL_AUTODISCOVER_RESPONSE = <<END
<?xml version="1.0" encoding="utf-8"?>
  <Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006">
  <Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a">
    <Account>
      <Action>redirectUrl</Action>
      <RedirectUrl>https://earthcommand.org/autodiscover/autodiscover.xml</RedirectUrl>
    </Account>
  </Response>
</Autodiscover>
END

REDIRECTADDR_AUTODISCOVER_RESPONSE = <<END
<?xml version="1.0" encoding="utf-8"?>
  <Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006">
  <Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a">
    <Account>
      <Action>redirectAddr</Action>
      <RedirectAddr>calvin@spacecommand.sol</RedirectAddr>
    </Account>
  </Response>
</Autodiscover>
END

class AutodiscoverResponseTest < Test::Unit::TestCase
  def setup
    @credentials = Autodiscover::Credentials.new('spiff@spacecommand.sol', 'spiff@spacecommand.sol', 'hobbes')
    @client = Autodiscover::Client.new
    WebMock::stub_request(:any, /spacecommand.sol/).to_timeout
  end

  # Test the cases where the Autodiscover service is configured to listen on
  # the standard secure endpoint addresses.
  [ "https://spiff%40spacecommand.sol:hobbes@spacecommand.sol/autodiscover/autodiscover.xml",
    "https://spiff%40spacecommand.sol:hobbes@autodiscover.spacecommand.sol/autodiscover/autodiscover.xml"
  ].each_with_index do |url, i|
    define_method "test_standard_secure_urls_#{i}" do
      WebMock::stub_request(:post, url).to_return(
        :body => SETTINGS_AUTODISCOVER_RESPONSE,
        :status => 200, 
        :headers => { 'Content-Length' => SETTINGS_AUTODISCOVER_RESPONSE.size }
      )
      response = @client.get_services(@credentials)
      assert_not_nil response
      assert_equal 'https://ews.spacecommand.sol/EWS/Exchange.asmx', response.ews_url
    end
  end

  # Test the cases where a standard secure address is used to redirect
  # to a secure endpoint that the Autodiscover service is available upon.
  def test_redirect_from_standard_secure_url
    WebMock::stub_request(:post, /spacecommand.sol/).to_return(
      :status => 302,
      :headers => { 'Location' => 'https://earthcommand.org/autodiscover/autodiscover.xml' }
    )
    WebMock::stub_request(:post, 'https://spiff%40spacecommand.sol:hobbes@earthcommand.org/autodiscover/autodiscover.xml').to_return(
      :body => SETTINGS_AUTODISCOVER_RESPONSE,
      :status => 200, 
      :headers => { 'Content-Length' => SETTINGS_AUTODISCOVER_RESPONSE.size }
    )
    response = @client.get_services(@credentials)
    assert_not_nil response
    assert_equal 'https://ews.spacecommand.sol/EWS/Exchange.asmx', response.ews_url
  end

  # Test the cases where the standard insecure redirect address is used to redirect
  # to a secure endpoint that the Autodiscover service is available upon.
  def test_standard_redirection_url
    WebMock::stub_request(:get, "http://autodiscover.spacecommand.sol/autodiscover/autodiscover.xml").to_return(
      :status => 302,
      :headers => { 'Location' => 'https://earthcommand.org/autodiscover/autodiscover.xml' }
    )
    WebMock::stub_request(:post, 'https://spiff%40spacecommand.sol:hobbes@earthcommand.org/autodiscover/autodiscover.xml').to_return(
      :body => SETTINGS_AUTODISCOVER_RESPONSE,
      :status => 200, 
      :headers => { 'Content-Length' => SETTINGS_AUTODISCOVER_RESPONSE.size }
    )
    response = @client.get_services(@credentials)
    assert_not_nil response
    assert_equal 'https://ews.spacecommand.sol/EWS/Exchange.asmx', response.ews_url
  end

  # Test the case where a post to a standard secure address returns a redirectUrl response that
  # redirects to a secure endpoint that returns a valid settings response.
  def test_redirect_url_response
    WebMock::stub_request(:post, "https://spiff%40spacecommand.sol:hobbes@spacecommand.sol/autodiscover/autodiscover.xml").to_return(
      :body => REDIRECTURL_AUTODISCOVER_RESPONSE,
      :status => 200, 
      :headers => { 'Content-Length' => REDIRECTURL_AUTODISCOVER_RESPONSE.size }
    )
    WebMock::stub_request(:post, 'https://spiff%40spacecommand.sol:hobbes@earthcommand.org/autodiscover/autodiscover.xml').to_return(
      :body => SETTINGS_AUTODISCOVER_RESPONSE,
      :status => 200, 
      :headers => { 'Content-Length' => SETTINGS_AUTODISCOVER_RESPONSE.size }
    )
    response = @client.get_services(@credentials)
    assert_not_nil response
    assert_equal 'https://ews.spacecommand.sol/EWS/Exchange.asmx', response.ews_url
  end

  # Test the case where a post to a standard secure address returns a redirectAddr response that
  # includes a new email address to use.
  def test_redirect_addr_response
    WebMock::stub_request(:post, "https://spiff%40spacecommand.sol:hobbes@autodiscover.spacecommand.sol/autodiscover/autodiscover.xml").to_return(
      :body => REDIRECTADDR_AUTODISCOVER_RESPONSE,
      :status => 200, 
      :headers => { 'Content-Length' => REDIRECTURL_AUTODISCOVER_RESPONSE.size }
    )
    WebMock::stub_request(:post, 'https://spiff%40spacecommand.sol:hobbes@spacecommand.sol/autodiscover/autodiscover.xml').to_return(
      :body => SETTINGS_AUTODISCOVER_RESPONSE,
      :status => 200, 
      :headers => { 'Content-Length' => SETTINGS_AUTODISCOVER_RESPONSE.size }
    )
    response = @client.get_services(@credentials)
    assert_not_nil response
    assert_equal 'https://ews.spacecommand.sol/EWS/Exchange.asmx', response.ews_url
  end

  # Test the case where there is an infinite loop of HTTP redirects. A limit should be hit
  # and a nil result should be returned.
  def test_http_redirect_limit
    WebMock::stub_request(:post, /spacecommand.sol/).to_return(
      :status => 302,
      :headers => { 'Location' => 'https://spacecommand.sol/autodiscover/autodiscover.xml' }
    )
    response = @client.get_services(@credentials)
    assert_nil response
  end

  # Test the case where there is an infinite loop created by circular redirectUrl responses.
  # The redirect limit should be reached and a nil result should be returned.
  def test_redirect_url_response_limit
    WebMock::stub_request(:post, "https://spiff%40spacecommand.sol:hobbes@spacecommand.sol/autodiscover/autodiscover.xml").to_return(
      :body => REDIRECTURL_AUTODISCOVER_RESPONSE,
      :status => 200, 
      :headers => { 'Content-Length' => REDIRECTURL_AUTODISCOVER_RESPONSE.size }
    )
    WebMock::stub_request(:post, 'https://spiff%40spacecommand.sol:hobbes@earthcommand.org/autodiscover/autodiscover.xml').to_return(
      :body => REDIRECTURL_AUTODISCOVER_RESPONSE,
      :status => 200, 
      :headers => { 'Content-Length' => SETTINGS_AUTODISCOVER_RESPONSE.size }
    )
    response = @client.get_services(@credentials)
    assert_nil response
  end

  def test_redirect_addr_response_limit
    WebMock::stub_request(:post, "https://spiff%40spacecommand.sol:hobbes@spacecommand.sol/autodiscover/autodiscover.xml").to_return(
      :body => REDIRECTADDR_AUTODISCOVER_RESPONSE,
      :status => 200, 
      :headers => { 'Content-Length' => REDIRECTURL_AUTODISCOVER_RESPONSE.size }
    )
    WebMock::stub_request(:post, 'https://calvin%40spacecommand.sol:hobbes@spacecommand.sol/autodiscover/autodiscover.xml').to_return(
      :body => REDIRECTADDR_AUTODISCOVER_RESPONSE,
      :status => 200, 
      :headers => { 'Content-Length' => SETTINGS_AUTODISCOVER_RESPONSE.size }
    )
    response = @client.get_services(@credentials)
    assert_nil response
  end
end
