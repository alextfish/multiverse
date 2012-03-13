# Load the rails application
require File.expand_path('../application', __FILE__)

# NewRelic app tracking
require 'newrelic_rpm'

# Initialize the rails application
Multiverse::Application.initialize!
