class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  
  def nocache_param
    if params.has_key?(:nocache)
      expire_all_cardset_caches
    end
  end
end
