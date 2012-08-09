source 'http://mirror1.prod.rhcloud.com/mirror/ruby/'
source 'http://rubygems.org'

gem 'rails', '3.0.0' # '3.2.6'
group :production do
  gem 'mysql2'
end

group :development, :test do
  # gem 'sqlite3'
  gem 'sqlite3-ruby', :require => 'sqlite3'
  # gem 'sqlite3-ruby', '1.2.5', :require => 'sqlite3'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  # gem 'sass-rails',   '~> 3.2.3'
  # gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

# gem 'jquery-rails'

# gem 'prototype-rails' # depends on rails 3.2
gem 'will_paginate', '3.0.pre4'
gem 'rdiscount'
gem 'newrelic_rpm'
gem 'win32console', :platforms => :mingw
gem 'dalli'
# gem "doc_raptor"

# This version needs to be hardcoded for OpenShift compatability
gem 'thor', '= 0.14.6'

# This needs to be installed so we can run Rails console on OpenShift directly
gem 'minitest'

group :development do
  # gem 'annotate-models', '1.0.4' - seems to have disappeared!
end

## OpenScript options:

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'
