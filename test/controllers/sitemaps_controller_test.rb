require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "should get sitemap as XML" do
    get "/sitemap.xml"
    assert_response :success
  end

  test "should include root URL" do
    get "/sitemap.xml"
    assert_includes response.body, root_url
  end

  test "should include status page URLs" do
    page = status_pages(:one)
    get "/sitemap.xml"
    assert_includes response.body, page.slug
  end

  test "should respond with XML content type" do
    get "/sitemap.xml"
    assert_match %r{application/xml}, response.content_type
  end
end
