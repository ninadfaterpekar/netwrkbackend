class AddSocialToMessage < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :social, :string
  end
end
