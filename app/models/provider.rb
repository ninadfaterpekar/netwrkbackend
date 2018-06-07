class Provider < ApplicationRecord
  belongs_to :user

  scope :by_name, ->(name) { where(name: name) }

  def provider_name=(name)
    self.name = name
  end
end
