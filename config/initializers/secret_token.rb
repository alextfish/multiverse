require File.join(Rails.root,'lib','openshift_secret_generator.rb')

# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

# Set token based on intialize_secret function (defined in initializers/secret_generator.rb)
Multiverse::Application.config.secret_token = initialize_secret(
  :token,
  '879fc7cafaf43cca2b748d33ba6ea4721e1ccb0160b901b00c783361f30f1f85f64394c523ce5821cd75f171b5830e2a6d8687f7004870e71d8639bea1f72148'
)