class Reply < ApplicationRecord
  belongs_to :message, required: true
  has_many :messages, as: :messageable, dependent: :destroy
end