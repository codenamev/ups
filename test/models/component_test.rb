require "test_helper"

class ComponentTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:one)
    @status_page = status_pages(:one)
    @component = components(:one)
  end

  test "should be valid" do
    assert @component.valid?
  end

  test "should require name" do
    @component.name = nil
    assert_not @component.valid?
    assert_includes @component.errors[:name], "can't be blank"
  end
end
