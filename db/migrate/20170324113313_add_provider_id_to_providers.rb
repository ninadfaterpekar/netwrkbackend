class AddProviderIdToProviders < ActiveRecord::Migration[5.0]
  def change
    add_column :providers, :provider_id, :string
  end
end
