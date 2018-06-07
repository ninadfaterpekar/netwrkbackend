class AddTermsOfUseToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :terms_of_use_accepted, :boolean, default: false
  end
end
