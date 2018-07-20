class FollowedMessage < ApplicationRecord
  belongs_to :followed_messages, foreign_key: 'message_id',
             class_name: 'Message'

  belongs_to :followed_users, foreign_key: 'user_id', class_name: 'User'

  validates :user_id, uniqueness: { scope: :message_id }

  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_message, ->(message_id) { where(message_id: message_id) }
end
