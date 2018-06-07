class Room < ApplicationRecord
  belongs_to :message, required: true
  has_many :messages, as: :messageable, dependent: :destroy
  has_many :rooms_users, dependent: :destroy
  has_many :users, through: :rooms_users
  delegate :owner, to: :message
end
