require "test_helper"

class ApiRequestTest < ActiveSupport::TestCase
  setup do
    @api_request = api_requests(:one)
  end

  # -- Associations --

  test "belongs to api_token" do
    assert_respond_to @api_request, :api_token
    assert_instance_of ApiToken, @api_request.api_token
  end

  test "has one account through api_token" do
    assert_respond_to @api_request, :account
    assert_instance_of Account, @api_request.account
    assert_equal @api_request.api_token.account, @api_request.account
  end

  # -- Validations: request_path --

  test "is valid with a request_path present" do
    assert @api_request.valid?
  end

  test "is invalid without a request_path" do
    @api_request.request_path = nil
    assert_not @api_request.valid?
    assert_includes @api_request.errors[:request_path], "can't be blank"
  end

  test "is invalid with a blank request_path" do
    @api_request.request_path = ""
    assert_not @api_request.valid?
  end

  # -- Validations: response_status --

  test "is valid with status 200" do
    @api_request.response_status = 200
    assert @api_request.valid?
  end

  test "is valid with status 100 (minimum boundary)" do
    @api_request.response_status = 100
    assert @api_request.valid?
  end

  test "is valid with status 599 (maximum boundary)" do
    @api_request.response_status = 599
    assert @api_request.valid?
  end

  test "is invalid with status 99 (below minimum)" do
    @api_request.response_status = 99
    assert_not @api_request.valid?
    assert @api_request.errors[:response_status].any?
  end

  test "is invalid with status 600 (above maximum)" do
    @api_request.response_status = 600
    assert_not @api_request.valid?
    assert @api_request.errors[:response_status].any?
  end

  test "is invalid with a nil response_status" do
    @api_request.response_status = nil
    assert_not @api_request.valid?
  end

  test "is invalid with a non-numeric response_status" do
    @api_request.response_status = "abc"
    assert_not @api_request.valid?
  end

  # -- Scopes: successful --

  test "successful scope returns requests with status 200-299" do
    successful = ApiRequest.successful
    successful.each do |req|
      assert_includes 200..299, req.response_status
    end
  end

  test "successful scope includes 200 status" do
    @api_request.update!(response_status: 200)
    assert_includes ApiRequest.successful, @api_request
  end

  test "successful scope includes 299 status" do
    @api_request.update!(response_status: 299)
    assert_includes ApiRequest.successful, @api_request
  end

  test "successful scope excludes 300 status" do
    @api_request.update!(response_status: 300)
    assert_not_includes ApiRequest.successful, @api_request
  end

  # -- Scopes: failed --

  test "failed scope returns requests outside 200-299" do
    failed = ApiRequest.failed
    failed.each do |req|
      assert_not_includes 200..299, req.response_status
    end
  end

  test "failed scope includes 404 status" do
    @api_request.update!(response_status: 404)
    assert_includes ApiRequest.failed, @api_request
  end

  test "failed scope includes 500 status" do
    @api_request.update!(response_status: 500)
    assert_includes ApiRequest.failed, @api_request
  end

  test "failed scope excludes 200 status" do
    @api_request.update!(response_status: 200)
    assert_not_includes ApiRequest.failed, @api_request
  end

  # -- Scopes: this_month --

  test "this_month scope includes records from current month" do
    assert_includes ApiRequest.this_month, @api_request
  end

  test "this_month scope excludes records from previous months" do
    @api_request.update_column(:created_at, 2.months.ago)
    assert_not_includes ApiRequest.this_month, @api_request
  end

  # -- Fixture sanity --

  test "fixtures are valid" do
    assert api_requests(:one).valid?
    assert api_requests(:two).valid?
  end
end
