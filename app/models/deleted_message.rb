class DeletedMessage < ApplicationRecord
  belongs_to :user
  belongs_to :messages_deleted, foreign_key: 'message_id', class_name: 'Message'
  validates :user_id, uniqueness: { scope: :message_id }
end
