class Network < ApplicationRecord
  # has_and_belongs_to_many :users
  has_many :networks_users, dependent: :destroy
  has_many :users, through: :networks_users, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :messages, as: :messageable, dependent: :destroy
  belongs_to :city

  validates_uniqueness_of :post_code

  attr_accessor :current_user

  def accessed(user = current_user)
    NetworksUser.by_user(user.id)
                .by_network(id)
                .invitation_sent_is(true).first.present?
  end

  def google_place_id=(google_place_id)
    result = Google::PlaceApi.new(google_place_id).perform
    self.city_id = result.id
  end
end
