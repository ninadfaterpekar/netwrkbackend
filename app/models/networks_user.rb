class NetworksUser < ApplicationRecord
  belongs_to :user
  belongs_to :network, counter_cache: :users_count
  validates :network_id, uniqueness: { scope: :user_id }

  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_network, ->(network_id) { where(network_id: network_id) }
  scope :invitation_sent_is, ->(bool) { where(invitation_sent: bool) }
  scope :connected_in_this_month, -> { where(['connected_at > ?', 1.month.ago]) }

  before_create :refresh_last_entrance_at

  def refresh_last_entrance_at
    return if last_entrance_at && last_entrance_at.today?
    update_attributes(last_entrance_at: Date.today)
  end
end
