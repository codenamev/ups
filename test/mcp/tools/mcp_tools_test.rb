# frozen_string_literal: true

require "test_helper"

class McpToolsTest < ActiveSupport::TestCase
  include ActionMCP::TestHelper

  setup do
    @account = accounts(:one)
    @user = users(:one)
    @status_page = status_pages(:one)
    @component = components(:one)

    # Set current context as the gateway would
    Current.user = @user
    Current.account = @account
    ActionMCP::Current.user = @user
  end

  teardown do
    Current.reset
    ActionMCP::Current.reset
  end

  # --- Tool Discovery ---

  test "all 8 tools are registered" do
    assert_mcp_tool_findable "list_status_pages"
    assert_mcp_tool_findable "get_status_page"
    assert_mcp_tool_findable "list_components"
    assert_mcp_tool_findable "update_component_status"
    assert_mcp_tool_findable "create_incident"
    assert_mcp_tool_findable "add_incident_update"
    assert_mcp_tool_findable "resolve_incident"
    assert_mcp_tool_findable "list_active_incidents"
  end

  # --- list_status_pages ---

  test "list_status_pages returns pages for account" do
    resp = execute_mcp_tool("list_status_pages")
    data = parse_tool_response(resp)
    assert data["status_pages"].any? { |p| p["slug"] == "api-services-status" }
  end

  # --- get_status_page ---

  test "get_status_page returns page with components" do
    resp = execute_mcp_tool("get_status_page", { slug: "api-services-status" })
    data = parse_tool_response(resp)
    assert_equal "api-services-status", data.dig("status_page", "slug")
    assert data.dig("status_page", "components").is_a?(Array)
  end

  # --- list_components ---

  test "list_components returns components for page" do
    resp = execute_mcp_tool("list_components", { page_id: @status_page.id })
    data = parse_tool_response(resp)
    assert data["components"].is_a?(Array)
  end

  # --- update_component_status ---

  test "update_component_status changes status" do
    resp = execute_mcp_tool("update_component_status", {
      component_id: @component.id,
      status: "degraded_performance"
    })
    data = parse_tool_response(resp)
    assert_equal "degraded_performance", data.dig("component", "new_status")
    assert_equal "degraded_performance", @component.reload.status
  end

  # --- create_incident ---

  test "create_incident creates a new incident" do
    resp = execute_mcp_tool("create_incident", {
      page_id: @status_page.id,
      title: "Database outage",
      impact: "critical"
    })
    data = parse_tool_response(resp)
    assert_equal "Database outage", data.dig("incident", "title")
    assert_equal "critical", data.dig("incident", "impact")
    assert_equal "investigating", data.dig("incident", "status")
  end

  # --- Full incident lifecycle ---

  test "resolve_incident resolves an incident" do
    incident = @status_page.incidents.create!(
      title: "Test incident",
      impact: "minor",
      status: "investigating",
      account: @account,
      user: @user,
      started_at: Time.current
    )

    resp = execute_mcp_tool("resolve_incident", {
      incident_id: incident.id,
      message: "All fixed"
    })
    resolve_data = parse_tool_response(resp)
    assert_equal "resolved", resolve_data.dig("incident", "status")
  end

  test "add_incident_update posts update to incident" do
    incident = @status_page.incidents.create!(
      title: "Test incident",
      impact: "minor",
      status: "investigating",
      account: @account,
      user: @user,
      started_at: Time.current
    )

    resp = execute_mcp_tool("add_incident_update", {
      incident_id: incident.id,
      message: "We identified the issue",
      status: "identified"
    })
    data = parse_tool_response(resp)
    assert_equal "identified", data.dig("incident_update", "status")
  end

  # --- list_active_incidents ---

  test "list_active_incidents returns only unresolved" do
    @status_page.incidents.create!(
      title: "Active incident",
      impact: "minor",
      status: "investigating",
      account: @account,
      user: @user,
      started_at: Time.current
    )

    resp = execute_mcp_tool("list_active_incidents", { page_id: @status_page.id })
    data = parse_tool_response(resp)
    assert data["active_incidents"].any? { |i| i["title"] == "Active incident" }
    data["active_incidents"].each do |i|
      assert_not_equal "resolved", i["status"]
    end
  end

  private

  def parse_tool_response(resp)
    text_content = resp.contents.find { |c| c.respond_to?(:text) }&.text
    JSON.parse(text_content)
  end
end
