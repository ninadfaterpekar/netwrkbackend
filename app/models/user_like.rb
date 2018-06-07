# Likes implementation
class UserLike < ApplicationRecord
  POINTS = 5
  belongs_to :liked_messages, foreign_key: 'message_id',
                              class_name: 'Message',
                              counter_cache: :likes_count

  belongs_to :liked_users, foreign_key: 'user_id', class_name: 'User'

  validates :user_id, uniqueness: { scope: :message_id }

  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_message, ->(message_id) { where(message_id: message_id) }
end
