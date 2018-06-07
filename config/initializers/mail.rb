MandrillMailer.configure do |config|
  config.api_key = ENV['MANDRILL_API_KEY_DEVEL'] if Rails.env == 'development'
  config.api_key = ENV['MANDRILL_API_KEY_PROD'] if Rails.env == 'production'
  config.deliver_later_queue_name = :default
end
