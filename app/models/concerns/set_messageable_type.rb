module SetMessageableType
  extend ActiveSupport::Concern

  def network_id=(network_id)
    self.messageable_id = network_id
    self.messageable_type = :Network
  end

  def room_id=(network_id)
    self.messageable_id = network_id
    self.messageable_type = :Room
  end
end
