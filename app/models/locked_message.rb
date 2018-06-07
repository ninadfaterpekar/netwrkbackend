class LockedMessage < ApplicationRecord
  belongs_to :locked_users, foreign_key: 'user_id', class_name: 'User'
  belongs_to :messages_locked, foreign_key: 'message_id', class_name: 'Message'
end
