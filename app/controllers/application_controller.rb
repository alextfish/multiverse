class ApplicationController < ActionController::Base
  protect_from_forgery
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format.json? }
  include SessionsHelper

  before_filter :redirect_to_domain if Rails.env.production?
  
  def nocache_param
    if params.has_key?(:nocache)
      expire_all_cardset_caches
    end
  end
  
  def ensure_captcha_matches
    unless params[:captcha_card]
      redirect_to spam_path and return
    end
    if !Captcha.check_answer(params)
      flash[:error] = "Captcha failed. Please try the captcha again."
      redirect_to :back
    end
  end
  
  private

    # Redirect to the appropriate domain i.e. example.com
    def redirect_to_domain
      domain_to_redirect_to = 'www.magicmultiverse.net'
      domain_exceptions = ['www.magicmultiverse.net', 'magicmultiverse.net']
      should_redirect = !(domain_exceptions.include? request.host)
      new_url = "#{request.protocol}#{domain_to_redirect_to}#{request.fullpath}"
      redirect_to new_url, status: :moved_permanently if should_redirect
    end

end
