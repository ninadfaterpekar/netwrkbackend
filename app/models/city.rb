class City < ApplicationRecord
  has_many :networks

  attr_accessor :current_user

  def city # for json
    name
  end

  def network_list(user = current_user)
    pc = []
    user.networks.where(city_id: id).each do |network|
      pc << network
    end
    pc
  end
end
