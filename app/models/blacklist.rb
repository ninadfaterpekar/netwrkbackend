class Blacklist < ApplicationRecord
  belongs_to :user,   foreign_key: :user_id, class_name: 'User'
  belongs_to :target, foreign_key: :target_id, class_name: 'User'

  scope :list_by_user, ->(user_id) { where(user_id: user_id) }
end
