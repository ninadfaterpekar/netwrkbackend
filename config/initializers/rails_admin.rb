require Rails.root.join('lib', 'rails_admin', 'email_distribution.rb')
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::EmailDistribution)

RailsAdmin.config do |config|
  ### Popular gems integration
  config.authenticate_with do
    warden.authenticate! scope: :admin
  end
  config.current_user_method(&:current_admin)

  ## == Cancan ==
  # config.authorize_with :cancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar true

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new do
      except [ApplicationSetting]
    end
    export
    bulk_delete
    show
    edit do
      except [Report, Provider, Network]
    end
    delete do
      except [ApplicationSetting]
    end
    show_in_app
    email_distribution do
      only [User]
    end
  end

  config.excluded_models = [
    Contact, Post, Ckeditor::Asset, Ckeditor::AttachmentFile, Ckeditor::Picture,
    City
  ]
  config.main_app_name = %w[Netwrk Admin]

  config.model 'ApplicationSetting' do
    navigation_icon 'fa fa-cogs'
    label 'Settings'
    weight 1

    edit do
      field :email_welcome do
        label 'Welcome Email (Name Of Template Email)'
      end
      field :email_connect_to_network do
        label 'Connect To Area (Name of Template Email)'
      end
      field :email_legendary_mail do
        label 'Legendary Email (Name of Template Email)'
      end
      field :email_invitation_to_area do
        label 'Invitation to grow an area (Name of Template Email)'
      end
      field :home_page, :ck_editor
    end

    show do
      field :email_welcome do
        label 'Welcome Email (Name Of Template Email)'
      end
      field :email_connect_to_network do
        label 'Connect To Area (Name of Template Email)'
      end
      field :email_legendary_mail do
        label 'Legendary Email (Name of Template Email)'
      end
      field :email_invitation_to_area do
        label 'Invitation to grow an area (Name of Template Email)'
      end
      field :home_page
    end

    list do
      field :email_welcome do
        label 'Welcome Email (Name Of Template Email)'
      end
      field :email_connect_to_network do
        label 'Connect To Area (Name of Template Email)'
      end
      field :email_legendary_mail do
        label 'Legendary Email (Name of Template Email)'
      end
      field :email_invitation_to_area do
        label 'Invitation to grow an area (Name of Template Email)'
      end
      field :home_page
    end
  end

  config.model 'Admin' do
    navigation_icon 'fa fa-star'
    weight 2

    list do
      field :email
      field :sign_in_count
      field :last_sign_in_at
    end

    edit do
      field :email
      field :password
      field :password_confirmation
    end
  end

  config.model 'Report' do
    navigation_icon 'fa fa-flag'
    weight 3

    list do
      field :user_id
      field :reportable
      field :reasons
      field :created_at
      field :updated_at
    end
    show do
      field :user_id
      field :reportable
      field :reasons
      field :created_at
      field :updated_at
    end
  end

  config.model 'User' do
    navigation_icon 'icon-user'
    weight 4
  end

  config.model 'Provider' do
    navigation_icon 'icon-user'
    weight 5

    list do
      field :user
      field :token
      field :name
    end

    show do
      field :user
      field :token
      field :name
    end
  end

  config.model 'Blacklist' do
    navigation_icon 'fa fa-list-alt'
    weight 6

    list do
      field :user
      field :target
    end
  end

  config.model 'Subscriber' do
    navigation_icon 'fa fa-pencil'
    weight 7
  end

  config.model 'Network' do
    navigation_label 'Networks'
    weight 8
  end

  config.model 'NetworksUser' do
    navigation_label 'Networks'
    weight 9
  end

  config.model 'Message' do
    navigation_label 'Messages'
    weight 10
  end

  config.model 'DeletedMessage' do
    navigation_label 'Messages'
    weight 11
  end

  config.model 'LockedMessage' do
    navigation_label 'Messages'
    weight 12
  end

  config.model 'Image' do
    navigation_label 'Messages'
    weight 13
  end

  config.model 'Video' do
    navigation_label 'Messages'
    weight 14
  end

  config.model 'UserLike' do
    navigation_label 'Likes'
    weight 15
  end

  config.model 'LegendaryLike' do
    navigation_label 'Likes'
    weight 16
  end
end
