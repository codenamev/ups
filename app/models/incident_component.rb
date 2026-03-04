class IncidentComponent < ApplicationRecord
  belongs_to :incident
  belongs_to :component
end
