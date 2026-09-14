# frozen_string_literal: true

# Errors raised by the Autodiscover client.
module Autodiscover
  # Base error for Autodiscover failures.
  class Error < ::StandardError; end

  # Raised when invalid arguments are given.
  class ArgumentError < Error; end

  # Raised when the server version cannot be determined.
  class VersionError < Error; end
end
