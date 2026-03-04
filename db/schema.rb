# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_03_062855) do
  create_table "account_users", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "role", default: "member"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["account_id", "user_id"], name: "index_account_users_on_account_id_and_user_id", unique: true
    t.index ["account_id"], name: "index_account_users_on_account_id"
    t.index ["user_id"], name: "index_account_users_on_user_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.boolean "onboarded", default: false, null: false
    t.string "plan", default: "free"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_accounts_on_created_at"
    t.index ["slug"], name: "index_accounts_on_slug", unique: true
  end

  create_table "action_mcp_session_messages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "direction", default: "client", null: false
    t.boolean "is_ping", default: false, null: false
    t.string "jsonrpc_id"
    t.json "message_json"
    t.string "message_type", null: false
    t.boolean "request_acknowledged", default: false, null: false
    t.boolean "request_cancelled", default: false, null: false
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_action_mcp_session_messages_on_session_id"
  end

  create_table "action_mcp_session_resources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "created_by_tool", default: false
    t.text "description"
    t.datetime "last_accessed_at"
    t.json "metadata"
    t.string "mime_type", null: false
    t.string "name"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.string "uri", null: false
    t.index ["session_id"], name: "index_action_mcp_session_resources_on_session_id"
  end

  create_table "action_mcp_session_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_notification_at"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.string "uri", null: false
    t.index ["session_id"], name: "index_action_mcp_session_subscriptions_on_session_id"
  end

  create_table "action_mcp_session_tasks", id: :string, force: :cascade do |t|
    t.json "continuation_state", default: {}
    t.datetime "created_at", null: false
    t.datetime "last_step_at"
    t.datetime "last_updated_at", null: false
    t.integer "poll_interval"
    t.string "progress_message"
    t.integer "progress_percent"
    t.string "request_method"
    t.string "request_name"
    t.json "request_params"
    t.json "result_payload"
    t.string "session_id", null: false
    t.string "status", default: "working", null: false
    t.string "status_message"
    t.integer "ttl"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_action_mcp_session_tasks_on_created_at"
    t.index ["session_id", "status"], name: "index_action_mcp_session_tasks_on_session_id_and_status"
    t.index ["session_id"], name: "index_action_mcp_session_tasks_on_session_id"
    t.index ["status"], name: "index_action_mcp_session_tasks_on_status"
  end

  create_table "action_mcp_sessions", id: :string, force: :cascade do |t|
    t.json "client_capabilities"
    t.json "client_info"
    t.json "consents", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.boolean "initialized", default: false, null: false
    t.integer "messages_count", default: 0, null: false
    t.json "prompt_registry", default: []
    t.string "protocol_version"
    t.json "resource_registry", default: []
    t.string "role", default: "server", null: false
    t.json "server_capabilities"
    t.json "server_info"
    t.string "status", default: "pre_initialize", null: false
    t.json "tool_registry", default: []
    t.datetime "updated_at", null: false
  end

  create_table "analytics_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type"
    t.json "metadata"
    t.datetime "occurred_at"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_analytics_events_on_user_id"
  end

  create_table "api_requests", force: :cascade do |t|
    t.integer "api_token_id", null: false
    t.datetime "created_at", null: false
    t.string "request_path"
    t.integer "response_status"
    t.datetime "updated_at", null: false
    t.index ["api_token_id", "created_at"], name: "index_api_requests_on_api_token_id_and_created_at"
    t.index ["api_token_id"], name: "index_api_requests_on_api_token_id"
    t.index ["created_at"], name: "index_api_requests_on_created_at"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.string "token_digest", null: false
    t.string "token_prefix", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["account_id"], name: "index_api_tokens_on_account_id"
    t.index ["last_used_at"], name: "index_api_tokens_on_last_used_at"
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["token_prefix"], name: "index_api_tokens_on_token_prefix"
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "brandings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "custom_domain"
    t.string "favicon_url"
    t.string "logo_url"
    t.string "primary_color"
    t.integer "status_page_id", null: false
    t.datetime "updated_at", null: false
    t.index ["status_page_id"], name: "index_brandings_on_status_page_id"
  end

  create_table "components", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", null: false
    t.integer "status", default: 0, null: false
    t.integer "status_page_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true
    t.index ["account_id"], name: "index_components_on_account_id"
    t.index ["status"], name: "index_components_on_status"
    t.index ["status_page_id", "position"], name: "index_components_on_status_page_id_and_position", unique: true
    t.index ["status_page_id"], name: "index_components_on_status_page_id"
  end

  create_table "idempotency_keys", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.text "response_body"
    t.integer "response_status", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "key"], name: "index_idempotency_keys_on_account_id_and_key", unique: true
    t.index ["account_id"], name: "index_idempotency_keys_on_account_id"
    t.index ["expires_at"], name: "index_idempotency_keys_on_expires_at"
  end

  create_table "incident_components", force: :cascade do |t|
    t.integer "component_id", null: false
    t.datetime "created_at", null: false
    t.integer "incident_id", null: false
    t.datetime "updated_at", null: false
    t.index ["component_id"], name: "index_incident_components_on_component_id"
    t.index ["incident_id"], name: "index_incident_components_on_incident_id"
  end

  create_table "incident_events", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.text "data"
    t.string "event_type", null: false
    t.integer "incident_id", null: false
    t.string "new_status"
    t.datetime "occurred_at", null: false
    t.string "previous_status"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_type"], name: "index_incident_events_on_event_type"
    t.index ["incident_id", "occurred_at"], name: "index_incident_events_on_incident_id_and_occurred_at"
    t.index ["incident_id"], name: "index_incident_events_on_incident_id"
    t.index ["user_id"], name: "index_incident_events_on_user_id"
  end

  create_table "incident_updates", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "incident_id", null: false
    t.integer "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["incident_id"], name: "index_incident_updates_on_incident_id"
    t.index ["user_id"], name: "index_incident_updates_on_user_id"
  end

  create_table "incidents", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "impact", default: 0, null: false
    t.datetime "resolved_at"
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.integer "status_page_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["account_id"], name: "index_incidents_on_account_id"
    t.index ["started_at"], name: "index_incidents_on_started_at"
    t.index ["status_page_id", "created_at"], name: "index_incidents_on_status_page_id_and_created_at"
    t.index ["status_page_id", "status"], name: "index_incidents_on_status_page_id_and_status"
    t.index ["status_page_id"], name: "index_incidents_on_status_page_id"
    t.index ["user_id"], name: "index_incidents_on_user_id"
  end

  create_table "monitor_summaries", force: :cascade do |t|
    t.decimal "avg_response_ms"
    t.integer "checks_count"
    t.datetime "created_at", null: false
    t.decimal "p95_response_ms"
    t.decimal "p99_response_ms"
    t.datetime "period_start"
    t.string "period_type"
    t.integer "status_monitor_id", null: false
    t.integer "successful_count"
    t.datetime "updated_at", null: false
    t.decimal "uptime_percentage"
    t.index ["status_monitor_id"], name: "index_monitor_summaries_on_status_monitor_id"
  end

  create_table "monitoring_probes", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "enabled", default: true, null: false
    t.integer "interval_minutes", default: 5, null: false
    t.string "name", null: false
    t.string "probe_type", default: "http", null: false
    t.json "settings", default: {}
    t.integer "timeout_seconds", default: 30, null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["account_id", "enabled"], name: "index_monitoring_probes_on_account_id_and_enabled"
    t.index ["account_id", "name"], name: "index_monitoring_probes_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_monitoring_probes_on_account_id"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.integer "component_id"
    t.boolean "component_status_change", default: true
    t.datetime "created_at", null: false
    t.boolean "incident_created", default: true
    t.boolean "incident_resolved", default: true
    t.boolean "incident_updated", default: true
    t.boolean "severity_critical", default: true
    t.boolean "severity_maintenance", default: true
    t.boolean "severity_major", default: true
    t.boolean "severity_minor", default: true
    t.integer "subscriber_id", null: false
    t.datetime "updated_at", null: false
    t.index ["component_id"], name: "index_notification_preferences_on_component_id"
    t.index ["subscriber_id", "component_id"], name: "index_notification_preferences_on_subscriber_and_component", unique: true
    t.index ["subscriber_id"], name: "index_notification_preferences_on_subscriber_id"
  end

  create_table "page_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "custom_css"
    t.boolean "maintenance_mode"
    t.integer "status_page_id", null: false
    t.string "theme"
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.index ["status_page_id"], name: "index_page_settings_on_status_page_id"
  end

  create_table "status_monitors", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "check_type", null: false
    t.integer "component_id", null: false
    t.datetime "created_at", null: false
    t.integer "expected_status_code", default: 200
    t.integer "interval_seconds", default: 300, null: false
    t.datetime "last_checked_at"
    t.string "name", null: false
    t.integer "status", default: 2, null: false
    t.integer "status_page_id", null: false
    t.integer "timeout_seconds", default: 30, null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["account_id"], name: "index_status_monitors_on_account_id"
    t.index ["component_id"], name: "index_status_monitors_on_component_id"
    t.index ["last_checked_at"], name: "index_status_monitors_on_last_checked_at"
    t.index ["status_page_id", "status"], name: "index_status_monitors_on_status_page_id_and_status"
    t.index ["status_page_id"], name: "index_status_monitors_on_status_page_id"
  end

  create_table "status_pages", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "custom_domain"
    t.text "description"
    t.string "name", null: false
    t.boolean "published", default: true
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "slug"], name: "index_status_pages_on_account_id_and_slug", unique: true
    t.index ["account_id"], name: "index_status_pages_on_account_id"
    t.index ["created_at"], name: "index_status_pages_on_created_at"
  end

  create_table "status_updates", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "component_id", null: false
    t.datetime "created_at", null: false
    t.integer "estimated_duration"
    t.text "message", null: false
    t.datetime "scheduled_for", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["account_id", "status"], name: "index_status_updates_on_account_id_and_status"
    t.index ["account_id"], name: "index_status_updates_on_account_id"
    t.index ["component_id", "scheduled_for"], name: "index_status_updates_on_component_id_and_scheduled_for"
    t.index ["component_id"], name: "index_status_updates_on_component_id"
    t.index ["scheduled_for"], name: "index_status_updates_on_scheduled_for"
    t.index ["user_id"], name: "index_status_updates_on_user_id"
  end

  create_table "subscribers", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "confirmation_token"
    t.boolean "confirmed", default: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.integer "delivery_failures_count", default: 0
    t.string "email"
    t.integer "emails_sent_count", default: 0
    t.datetime "last_delivery_failure_at"
    t.datetime "last_email_sent_at"
    t.integer "status_page_id", null: false
    t.string "unsubscribe_token"
    t.datetime "unsubscribed_at"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_subscribers_on_account_id"
    t.index ["status_page_id", "email"], name: "index_subscribers_on_status_page_id_and_email", unique: true
    t.index ["status_page_id"], name: "index_subscribers_on_status_page_id"
    t.index ["unsubscribe_token"], name: "index_subscribers_on_unsubscribe_token", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.string "plan"
    t.string "status"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_subscriptions_on_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "current_plan"
    t.string "email", null: false
    t.datetime "last_sign_in_at"
    t.string "name"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "subscription_status"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.text "event_data", null: false
    t.string "event_type", null: false
    t.string "idempotency_key", null: false
    t.datetime "last_retry_at"
    t.text "response_body"
    t.integer "response_status"
    t.integer "retries", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "webhook_id", null: false
    t.index ["idempotency_key"], name: "index_webhook_deliveries_on_idempotency_key", unique: true
    t.index ["status", "created_at"], name: "index_webhook_deliveries_on_status_and_created_at"
    t.index ["webhook_id", "event_type"], name: "index_webhook_deliveries_on_webhook_id_and_event_type"
    t.index ["webhook_id"], name: "index_webhook_deliveries_on_webhook_id"
  end

  create_table "webhooks", force: :cascade do |t|
    t.integer "account_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "events", null: false
    t.string "name", limit: 255, null: false
    t.string "secret_token", null: false
    t.integer "status_page_id", null: false
    t.datetime "updated_at", null: false
    t.string "url", limit: 2048, null: false
    t.index ["account_id"], name: "index_webhooks_on_account_id"
    t.index ["status_page_id", "active"], name: "index_webhooks_on_status_page_id_and_active"
    t.index ["status_page_id"], name: "index_webhooks_on_status_page_id"
    t.index ["url"], name: "index_webhooks_on_url"
  end

  add_foreign_key "account_users", "accounts"
  add_foreign_key "account_users", "users"
  add_foreign_key "action_mcp_session_messages", "action_mcp_sessions", column: "session_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "action_mcp_session_resources", "action_mcp_sessions", column: "session_id", on_delete: :cascade
  add_foreign_key "action_mcp_session_subscriptions", "action_mcp_sessions", column: "session_id", on_delete: :cascade
  add_foreign_key "action_mcp_session_tasks", "action_mcp_sessions", column: "session_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "analytics_events", "users"
  add_foreign_key "api_requests", "api_tokens"
  add_foreign_key "api_tokens", "accounts"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "brandings", "status_pages"
  add_foreign_key "components", "accounts"
  add_foreign_key "components", "status_pages"
  add_foreign_key "idempotency_keys", "accounts"
  add_foreign_key "incident_components", "components"
  add_foreign_key "incident_components", "incidents"
  add_foreign_key "incident_events", "incidents"
  add_foreign_key "incident_events", "users"
  add_foreign_key "incident_updates", "incidents"
  add_foreign_key "incident_updates", "users"
  add_foreign_key "incidents", "accounts"
  add_foreign_key "incidents", "status_pages"
  add_foreign_key "incidents", "users"
  add_foreign_key "monitor_summaries", "status_monitors"
  add_foreign_key "monitoring_probes", "accounts"
  add_foreign_key "notification_preferences", "components"
  add_foreign_key "notification_preferences", "subscribers"
  add_foreign_key "page_settings", "status_pages"
  add_foreign_key "status_monitors", "accounts"
  add_foreign_key "status_monitors", "components"
  add_foreign_key "status_monitors", "status_pages"
  add_foreign_key "status_pages", "accounts"
  add_foreign_key "status_updates", "accounts"
  add_foreign_key "status_updates", "components"
  add_foreign_key "status_updates", "users"
  add_foreign_key "subscribers", "accounts"
  add_foreign_key "subscribers", "status_pages"
  add_foreign_key "subscriptions", "accounts"
  add_foreign_key "webhook_deliveries", "webhooks"
  add_foreign_key "webhooks", "accounts"
  add_foreign_key "webhooks", "status_pages"
end
