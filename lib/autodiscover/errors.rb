module Autodiscover
  class Error < ::StandardError; end

  class ArgumentError < Error; end
  class VersionError < Error; end
end
