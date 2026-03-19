require "test_helper"

module Public
  class StatusPagesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @account = accounts(:one)
      @status_page = status_pages(:one)
      @component = components(:one)
      @incident = incidents(:one)
    end

    test "should show public status page" do
      get public_status_page_url(@status_page.slug)
      assert_response :success
      assert_includes response.body, @status_page.name
    end

    test "should show public status page with components" do
      @component.update!(visible: true)

      get public_status_page_url(@status_page.slug)
      assert_response :success
      assert_includes response.body, @component.name
      assert_includes response.body, @component.status.humanize
    end

    test "should hide invisible components" do
      @component.update!(visible: false)

      get public_status_page_url(@status_page.slug)
      assert_response :success
      assert_not_includes response.body, @component.name
    end

    test "should show recent incidents" do
      @incident.update!(status_page: @status_page)

      get public_status_page_url(@status_page.slug)
      assert_response :success
      assert_includes response.body, @incident.title
    end

    test "should calculate overall status as operational when all components operational" do
      @component.update!(status: "operational", visible: true)

      get public_status_page_url(@status_page.slug)
      assert_response :success
      assert_includes response.body, "All Systems Operational"
    end

    test "should calculate overall status as major outage when any component has major outage" do
      component1 = Component.create!(
        name: "Component 1",
        status: "operational",
        visible: true,
        status_page: @status_page,
        account: @account
      )

      component2 = Component.create!(
        name: "Component 2",
        status: "major_outage",
        visible: true,
        status_page: @status_page,
        account: @account
      )

      get public_status_page_url(@status_page.slug)
      assert_response :success
      assert_includes response.body, "Major System Outage"
    end

    test "should calculate overall status as partial outage when any component has partial outage" do
      @component.update!(status: "partial_outage", visible: true)

      get public_status_page_url(@status_page.slug)
      assert_response :success
      assert_includes response.body, "Partial System Outage"
    end

    test "should calculate overall status as degraded performance when any component degraded" do
      @component.update!(status: "degraded_performance", visible: true)

      get public_status_page_url(@status_page.slug)
      assert_response :success
      assert_includes response.body, "Degraded Performance"
    end

    test "should calculate overall status as maintenance when any component in maintenance" do
      @component.update!(status: "maintenance", visible: true)

      get public_status_page_url(@status_page.slug)
      assert_response :success
      assert_includes response.body, "Under Maintenance"
    end

    test "should return json response" do
      @component.update!(visible: true)
      @incident.update!(status_page: @status_page)

      get public_status_page_url(@status_page.slug), headers: { "Accept" => "application/json" }
      assert_response :success
      assert_equal "application/json", response.media_type

      json = JSON.parse(response.body)
      assert_equal @status_page.name, json["page"]["name"]
      assert_equal @status_page.slug, json["page"]["slug"]
      assert_includes json["components"].map { |c| c["name"] }, @component.name
      assert_includes json["recent_incidents"].map { |i| i["title"] }, @incident.title
    end

    test "should return 404 for non-existent status page" do
      get public_status_page_url("non-existent-slug")
      assert_response :not_found
    end

    test "should use public layout" do
      get public_status_page_url(@status_page.slug)
      assert_response :success
      assert_includes response.body, "Powered by"  # "ups.dev" branding in footer
      assert_includes response.body, "Last updated"
    end

    test "should limit recent incidents to 10" do
      # Create 15 incidents
      15.times do |i|
        Incident.create!(
          title: "Incident #{i}",
          status: "investigating",
          impact: "minor",
          status_page: @status_page,
          account: @account,
          user: users(:one),
          started_at: i.hours.ago,
          created_at: i.hours.ago
        )
      end

      get public_status_page_url(@status_page.slug)
      assert_response :success

      # Should only show 10 most recent
      incidents_in_response = response.body.scan(/Incident \d+/).uniq
      assert_operator incidents_in_response.length, :<=, 10
    end

    test "should auto refresh every 60 seconds" do
      get public_status_page_url(@status_page.slug)
      assert_response :success
      assert_includes response.body, 'content="60"'
    end
  end
end
