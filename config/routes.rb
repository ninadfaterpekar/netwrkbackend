Rails.application.routes.draw do
  mount Ckeditor::Engine => '/ckeditor'
  devise_for :admins
  mount ActionCable.server => '/cable'

  root 'home#index'
  resources :messages
  resources :home, only: [:index], path: '' do
    collection do
      get 'privacy'
      get 'terms_of_use'
      get 'clear_messages'
      get 'terms_of_use'
      get 'loader'
      post 'create_subscriber'
    end
  end

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  authenticate :admin do
    mount Sidekiq::Web => '/sidekiq'
  end

  devise_for :users
  namespace :api do
    namespace :v1 do
      resources :rooms, only: [] do
        post :users, to: 'rooms#add_user'
        get :network, to: 'rooms#get_network'
      end

      resources :reports, only: %i[] do
        collection do
          post :user
          post :message
        end
      end

      resources :blacklist, controller: 'blacklists', only: %i[index create] do
      end

      resources :registrations, only: %i[create update] do
        collection do
          get 'check_login'
        end
      end

      resources :providers, only: %i[create]
      resources :networks, only: %i[index create] do
        collection do
          get 'list'
        end
      end
      resources :messages do
        member do
          get 'room/messages', to: 'messages#messages_from_room'
          get 'room/users', to: 'messages#users_from_room'
          get 'reply/messages', to: 'messages#replies_on_message'
        end
        collection do
          post 'lock'
          post 'unlock'
          post 'delete'
          post 'sms_sharing'
          post 'share'
          get 'legendary_list'
          get 'profile_messages'
          get 'nearby_profile_messages'
          get 'profile_communities'
          get 'block'
          post 'social_feed'
          post 'delete_for_all'
          post 'update_message_points'
          put 'update_message_avatar'
          get 'nearby'
          get 'nearby_search'
          post 'send_notifications', to: 'messages#send_notifications'
          get 'non_custom_lines', to: 'messages#get_non_custom_lines'
          post 'conversation_update'
          get 'map_feed'
        end
      end
      resources :networks_users, only: %i[index create]
      resources :members, only: [:create]
      resource :profiles, only: %i[destroy]
      resources :profiles, only: %i[show] do
        collection do
          get 'user_by_provider'
          post 'connect_social'
          post 'change_points_count'
          get 'disabled_hero'
          get 'social_net_status'
          patch 'accept_terms_of_use'
        end
      end
      resources :sessions, only: %i[create destroy] do
        collection do
          get 'check'
          post 'oauth_login'
          post 'verification'
        end
      end
      resources :user_likes, only: [:create]
      resources :user_followed, only: [:create]
      resources :legendary_likes, only: %i[create index]
      resources :invitations, only: [:create]
      resources :contacts, only: [:create]
      get '/sms', to: 'invitations#sms'
    end
  end
end
