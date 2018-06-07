class AddInvitationSentToNetworkUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :networks_users, :invitation_sent, :boolean, default: false
  end
end
