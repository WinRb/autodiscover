# frozen_string_literal: true

# Enables debug logging for the Autodiscover client.
module Autodiscover
  Logging.logger['Autodiscover'].level = :debug
  Logging.logger['Autodiscover'].appenders = Logging.appenders.stdout
end
