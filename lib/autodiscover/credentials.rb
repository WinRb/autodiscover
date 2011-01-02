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

module Autodiscover
  # A Credentials object is used to determine the autodiscover service
  # endpoint and to authenticate to it.
  class Credentials
    # E-mail address for the user.
    attr_reader :email

    # Password for the account.
    attr_reader :password

    # SMTP domain determined by the e-mail address.
    attr_reader :smtp_domain  #:nodoc:

    def initialize(address, password)
      self.email = address
      @password = password
    end

    def email=(address)  #:nodoc:
      raise ArgumentError, "No email address specified" unless address
      @smtp_domain = address[/^.+@(.*)$/, 1]
      unless @smtp_domain =~ /.+\..+/
        raise ArgumentError, "Invalid email address: #{address}"
      end
      @email = address
    end
  end
end