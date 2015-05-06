require "test_helper"
require "ostruct"

describe Autodiscover::PoxRequest do
  let(:_class) {Autodiscover::PoxRequest }
  let(:http) { mock("http") }
  let(:client) { OpenStruct.new({http: http, domain: "example.local", email: "test@example.local"}) }

  it "returns a PoxResponse if the autodiscover is successful" do
    request_body = <<-EOF.gsub(/^      /,"")
      <?xml version="1.0"?>
      <Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/requestschema/2006">
        <Request>
          <EMailAddress>test@example.local</EMailAddress>
          <AcceptableResponseSchema>http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a</AcceptableResponseSchema>
        </Request>
      </Autodiscover>
    EOF
    http.expects(:post).with(
      "https://example.local/autodiscover/autodiscover.xml", request_body,
      {'Content-Type' => 'text/xml; charset=utf-8'}
    ).returns(OpenStruct.new({status: 200, body: "<test></test>"}))

    inst = _class.new(client)
    _(inst.autodiscover).must_be_instance_of(Autodiscover::PoxResponse)
  end

end
