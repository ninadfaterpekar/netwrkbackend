class AddCommunityIdentityIdToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :community_identity_id, :integer
    add_index :users, :community_identity_id
  end
end
