source 'https://rubygems.org'

# Cedar, Ruby 2, Rails 4
# Or not Ruby 2: "Ruby 2.0.0, specially the 64bits version, are relatively new on the Windows area and not all the packages have been updated to be compatible with it. To use this version you will require some knowledge about compilers and solving dependency issues, which might be too complicated if you just want to play with the language."
ruby '1.9.3' # '1.9.2'
# gem 'activesupport', '~> 4.0.4' # higher needs ruby 1.9.3
gem 'rails', '>=4.0.0'
gem 'webrick', '1.3.1'

gem 'prototype-rails', '>=4.0.0'
#gem 'prototype-rails' # depends on rails 3.2

gem 'json', '~>1.7.7' # avoid security vulnerability in json-1.7.6

group :production do
  gem 'pg'
#  gem 'unicorn'
#  gem 'mysql'
#  gem "mysql2", "~> 0.3.11"
end

platforms :ruby do # linux
  gem 'unicorn'
end

platforms :mswin do
  # gems specific to windows
  gem 'thin'
end
gem 'tzinfo-data'

#platforms :mri_18, :mingw_18 do
#  group :production do
#    gem "mysql"
#  end
#end
#
#platforms :mri_19, :mingw_19 do
#  group :production do
#    gem "mysql2", "~> 0.3.11"
#  end
#end

group :development, :test do
  # gem 'sqlite3'
  gem 'sqlite3-ruby', :require => 'sqlite3'
  # gem 'sqlite3-ruby', '1.2.5', :require => 'sqlite3'
end

  gem 'sass-rails',   '~> 4.0.0' # '~> 3.2.3'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.3.0'
  #gem 'execjs'

gem 'jquery-rails'

gem 'will_paginate' #, '3.0.pre4'
gem 'rdiscount'   #, '~> 1.6'
gem 'newrelic_rpm'
gem 'win32console', :platforms => :mingw
gem 'dalli'
gem 'memcachier'
gem 'quiet_assets', :group => :development
# gem "doc_raptor"

group :development do
  # gem 'annotate-models', '1.0.4' - seems to have disappeared!
  # gem 'utf8-cleaner' - just don't type pound signs in source code...
end

# Rails 4 migration assistance
gem 'protected_attributes'
gem 'rails-observers'
gem 'actionpack-page_caching'
gem 'actionpack-action_caching'
