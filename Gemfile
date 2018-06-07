source 'http://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.1'
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
#gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri

  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger', '>= 0.1.1'

  # Remove the following if your app does not use Rails
  gem 'capistrano-rails'

  # Remove the following if your server does not use RVM
  gem 'capistrano-rvm'
  gem 'capistrano-sidekiq'
  gem 'bullet'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'listen', '~> 3.0.5'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Added on development #
gem 'aws-sdk'
gem 'capistrano-rails-console', require: false
gem 'ckeditor'
gem 'devise'
gem 'geocoder'

gem 'fcm'
gem 'houston'

gem 'mandrill-api'
gem 'mandrill_mailer'
gem 'gibbon'

gem 'instagram', git: 'git://github.com/Instagram/instagram-ruby-gem.git'
gem 'koala'

gem 'newrelic_rpm'
gem 'obscenity'
gem 'paperclip'
gem 'phonelib'
gem 'rails_admin'

gem 'sidekiq'
gem 'sidekiq-scheduler'

gem 'twilio-ruby'
gem 'twitter'
gem 'twitter-bootstrap-rails'
gem 'valid_email', require: 'valid_email/validate_email'

gem 'mutations'
gem 'oj'

gem 'active_model_serializers', '~> 0.10.0'

gem 'rack-cors', :require => 'rack/cors'
gem 'bcrypt', '3.1.11', platforms: [:ruby, :x64_mingw]