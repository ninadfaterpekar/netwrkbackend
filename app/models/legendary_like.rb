class LegendaryLike < ApplicationRecord
  POINTS = 15

  belongs_to :legendary_users, foreign_key: 'user_id', class_name: 'User'
  belongs_to :message, foreign_key: 'message_id',
                                  class_name: 'Message',
                                  counter_cache: :legendary_count
  validates :user_id, uniqueness: { scope: :message_id }

  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_message, ->(message_id) { where(message_id: message_id) }
end
