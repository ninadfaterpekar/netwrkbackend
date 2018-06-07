Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  config.action_cable.url = 'ws://192.168.1.77:3000/cable'
  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=172800'
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # config.action_controller.asset_host = "http://192.168.1.13:3000"
  config.action_cable.allowed_request_origins = [/http:\/\/*/, /https:\/\/*/]
  config.action_cable.disable_request_forgery_protection = true
  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: 'smtp.mandrillapp.com',
    port: 587,
    user_name: 'Kf',
    password: '-4wMBwYM9O4bxQVUS_n2nw',
    domain:   'netwrk.com',
  }

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  config.paperclip_defaults = {
    storage: :s3,
    s3_region: 'us-west-2',
    s3_host_name: 's3-us-west-2.amazonaws.com',
    bucket: 'netwrk-assets',
    s3_credentials: "#{Rails.root}/config/aws.yml"
  }

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker


end
