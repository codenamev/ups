require "test_helper"

class NotificationPreferenceTest < ActiveSupport::TestCase
  setup do
    @subscriber = subscribers(:one)
    @component = components(:one)
    @other_component = components(:two)
    # Clear any existing preferences
    NotificationPreference.where(subscriber: @subscriber).destroy_all
  end

  test "should create notification preference with defaults" do
    preference = NotificationPreference.create!(subscriber: @subscriber)

    assert preference.incident_created
    assert preference.incident_updated
    assert preference.incident_resolved
    assert preference.component_status_change
    assert preference.severity_minor
    assert preference.severity_major
    assert preference.severity_critical
    assert preference.severity_maintenance
  end

  test "should allow component-specific preferences" do
    preference = NotificationPreference.create!(
      subscriber: @subscriber,
      component: @component,
      incident_created: false
    )

    assert_equal @component, preference.component
    assert_not preference.incident_created
  end

  test "should enforce uniqueness of subscriber and component combination" do
    NotificationPreference.create!(subscriber: @subscriber, component: @component)

    assert_raises ActiveRecord::RecordInvalid do
      NotificationPreference.create!(subscriber: @subscriber, component: @component)
    end
  end

  test "should scope global preferences" do
    global_pref = NotificationPreference.create!(subscriber: @subscriber)
    component_pref = NotificationPreference.create!(subscriber: @subscriber, component: @component)

    assert_includes NotificationPreference.global, global_pref
    assert_not_includes NotificationPreference.global, component_pref
  end

  test "should scope component specific preferences" do
    global_pref = NotificationPreference.create!(subscriber: @subscriber)
    component_pref = NotificationPreference.create!(subscriber: @subscriber, component: @component)

    assert_includes NotificationPreference.component_specific, component_pref
    assert_not_includes NotificationPreference.component_specific, global_pref
  end
end
