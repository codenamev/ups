module Limitable
  extend ActiveSupport::Concern

  private

  # In the community edition, all resources are unlimited.
  # The ups-pro engine overrides this to enforce plan limits.
  def check_plan_limits(resource_type)
    true
  end
end
