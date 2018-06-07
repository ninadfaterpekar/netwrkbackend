Obscenity.configure do |config|
  config.blacklist = "#{Rails.root}/config/initializers/blacklist.yml"
  config.replacement = :default
end
