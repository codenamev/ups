# frozen_string_literal: true

class ApplicationMCPTool < ActionMCP::Tool
  abstract!

  # Wrap perform with standard error handling so individual tools
  # don't need to rescue ActiveRecord exceptions themselves.
  def perform
    execute_tool
  rescue ActiveRecord::RecordNotFound => e
    render text: "Not found: #{e.message}"
    report_error("Not found: #{e.message}")
  rescue ActiveRecord::RecordInvalid => e
    msg = "Validation failed: #{e.record.errors.full_messages.join(', ')}"
    render text: msg
    report_error(msg)
  end

  private

  # Subclasses implement this instead of perform.
  def execute_tool
    raise NotImplementedError, "#{self.class.name} must implement #execute_tool"
  end

  def account
    Current.account
  end
end
