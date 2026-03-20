require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  minimum_coverage 70
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/db/"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
    end

    parallelize_teardown do |worker|
      SimpleCov.result
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user)
    token = user.generate_token_for(:magic_link)
    get verify_magic_link_url(token: token)
  end

  def api_auth_header(token = "Bearer ups_test_one_abcdef1234567890")
    { "Authorization" => token }
  end
end
