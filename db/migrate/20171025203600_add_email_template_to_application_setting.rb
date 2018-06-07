class AddEmailTemplateToApplicationSetting < ActiveRecord::Migration[5.0]
  def change
    add_column :application_settings, :email_invitation_to_area, :string
  end
end
