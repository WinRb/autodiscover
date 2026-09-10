# frozen_string_literal: true

require File.expand_path('../lib/autodiscover.rb', __dir__)
require 'minitest/autorun'
require 'mocha/mini_test'

TEST_DIR = File.dirname(__FILE__)

# Helpers for the minitest specs.
class MiniTest
  # Spec helpers.
  class Spec
    def load_sample(name)
      File.read("#{TEST_DIR}/fixtures/#{name}")
    end
  end
end
