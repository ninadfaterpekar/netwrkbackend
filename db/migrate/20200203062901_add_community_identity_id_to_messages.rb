class AddCommunityIdentityIdToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :community_identity_id, :integer
    add_index :messages, :community_identity_id
  end
end
