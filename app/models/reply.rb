class Reply < ApplicationRecord
  belongs_to :message, required: true, counter_cache: :reply_count
  has_many :messages, as: :messageable, dependent: :destroy
end