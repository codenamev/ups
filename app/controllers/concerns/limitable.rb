module Limitable
  extend ActiveSupport::Concern

  included do
    # In the community edition, all resources are unlimited.
    # The ups-pro engine overrides this to enforce plan limits.
  end

  def check_plan_limits(resource_type)
    true
  end
end
