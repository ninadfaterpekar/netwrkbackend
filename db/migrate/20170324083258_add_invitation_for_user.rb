class AddInvitationForUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :invitation_sent, :boolean, default: false
  end
end
