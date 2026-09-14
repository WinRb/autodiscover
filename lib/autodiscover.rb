# frozen_string_literal: true

require 'autodiscover/version'
require 'nokogiri'
require 'nori'
require 'httpclient'
require 'logger' unless defined?(Logger)

# Ruby client for Microsoft's Autodiscover Service.
module Autodiscover
  @logger = Logger.new($stdout)
  @logger.level = Logger::INFO

  def self.logger
    @logger
  end

  def logger
    @logger ||= Autodiscover.logger
  end
end

require 'autodiscover/errors'
require 'autodiscover/client'
require 'autodiscover/pox_request'
require 'autodiscover/pox_response'
require 'autodiscover/server_version_parser'
