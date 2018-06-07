require_relative 'boot'

require 'rails/all'
require 'koala'
require 'twitter'
require 'obscenity/active_model'
require 'sidekiq/web'
require 'sidekiq/scheduler'
require 'sidekiq-scheduler/web'
require 'mandrill'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)


module BKServer
  class Application < Rails::Application



    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.autoload_paths << "#{Rails.root}/app/logic/authentication"
    config.autoload_paths << "#{Rails.root}/app/logic/messages"
    config.autoload_paths << "#{Rails.root}/app/logic/twilio"
    config.autoload_paths << "#{Rails.root}/app/logic/google"
    config.autoload_paths << "#{Rails.root}/app/logic/instagram"
    config.autoload_paths << "#{Rails.root}/app/logic/twitter"
    config.autoload_paths << "#{Rails.root}/app/logic/facebook"
    config.autoload_paths << "#{Rails.root}/app/logic/undercover"
    config.autoload_paths << "#{Rails.root}/app/logic/notifications"
    config.autoload_paths << "#{Rails.root}/app/logic/interfaces"
    config.autoload_paths << "#{Rails.root}/app/logic/autocasting"
    config.autoload_paths << "#{Rails.root}/app/queries"

    # config.to_prepare do
    #   Devise::SessionsController.skip_before_action :check_token
    # end

    #config.web_console.whitelisted_ips = '192.168.1.0/16'
    #config.web_console.whitelisted_ips = '192.168.1.77'

    config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource(
            '*',
            :headers => :any,
            :methods => [:get, :patch, :put, :delete, :post, :options])
      end
    end

    config.assets.version = '1.0'
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exist?(env_file)
    end
  end
end
