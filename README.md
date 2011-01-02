Autodiscover
============

Ruby client for Microsoft's Autodiscover Service.

The Autodiscover Service is a component of the Exchange 2007 and Exchange 2010 architecture. Autoservice clients can access the URLs and settings needed to communicate with Exchange servers, such as the URL of the endpoint to use with the Exchange Web Services (EWS) API.

This library implements Microsoft's "Autodiscover HTTP Service Protocol Specification" to discover the endpoint for an Autodiscover server that supports a specified e-mail address and Microsoft's "Autodiscover Publishing and Lookup Protocol Specification" to get URLs and settings that are required to access Web services available from Exchange servers.

Dependencies
------------

This library requires the following Gems:

* HTTPClient
* Nokogiri

The HTTPClient Gem in turn requires the rubyntlm Gem for Negotiate/NTLM authentication.

For unit testing the webmock Gem is also used.

How to Use
----------

  require 'autodiscover'

  credentials = Autodiscover::Credentials.new('<e-mail address>', '<password>')
  client = Autodiscover::Client.new
  services = client.get_services(credentials)
  ews_url = services.ews_url
  ttl = services.ttl

Options
-------

### Debugging

For debugging, we extend the use of the debug_dev option in the HTTPClient library.

  debug_file = File.open('<filename path>', 'w')
  credentials = Autodiscover::Credentials.new('<e-mail address>', '<password>')
  client = Autodiscover::Client.new(:debug_dev => debug_file)
  services = client.get_services(credentials)
  debug_file.close

### Connection Timeouts

To adjust the connection timeout values used when searching for Autodiscover server endpoints:

  client = Autodiscover::Client.new(:connect_timeout => 5)

The units are seconds.

Installation
------------

### Configuring a Rails App to use the latest GitHub master version

	gem 'autodiscover', :git => 'git://github.com/wimm/autodiscover.git'

### To install the latest development version from the GitHub master

	git clone http://github.com/wimm/autodiscover.git
	cd autodiscover
	gem build autodiscover.gemspec
	sudo gem install autodiscover-<version>.gem

Bugs and Issues
---------------

Limitations:

* Doesn't support querying the DNS for SRV Records
* Only returns the TTL and EWS_Url values from the EXPR Protocol response

Please submit additional bugs and issues here [http://github.com/wimm/autodiscover/issues](http://github.com/wimm/autodiscover/issues)

Copyright
---------

Copyright (c) 2010-2011 WIMM Labs, Inc. See MIT-LICENSE for details.
