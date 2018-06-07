class Report < ApplicationRecord
  AMOUNT_TO_REMOVE = 3
  belongs_to :reportable, polymorphic: true

  scope :by_ids, ->(ids) { where(id: ids) }
  scope :by_type, ->(type) { where(reportable_type: type) }
end
