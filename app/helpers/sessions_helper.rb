module SessionsHelper
  def sign_in(user)
    cookies.permanent.signed[:remember_token] = [user.id, user.salt]
    current_user = user
  end
  def sign_out
    cookies.delete(:remember_token)
    self.current_user = nil
  end

  def signed_in?
    !current_user.nil?
  end
  def signed_in_as_admin?(cardset)
    current_user && current_user.id == cardset.user_id
  end

  def require_permission_to_view
    if !permission_to_view(@cardset)
      redirect_to signin_path, :notice => @cardset.visibility_permission_message
    end
  end

  def permission_to_view(cardset)
    case cardset.configuration.visibility
      when "anyone"
        return true
      when "signedin"
        return signed_in?
      when "admins"
        return signed_in_as_admin?(cardset)
      when "selected"
        return signed_in_as_admin?(cardset) || cardset.configuration.view_permitted_users.include?(current_user.name)
    end
  end
  def permission_to_comment(cardset)
    case cardset.configuration.commentability
      when "anyone"
        return true
      when "signedin"
        return signed_in?
      when "admins"
        return signed_in_as_admin?(cardset)
      when "selected"
        return signed_in_as_admin?(cardset) || cardset.configuration.comment_permitted_users.include?(current_user.name)
    end
  end

  def current_user=(user) # the setter for current_user
    @current_user = user
  end
  def current_user        # the getter for current_user
    @current_user ||= user_from_remember_token
  end

  def require_login
    request_login unless signed_in?
  end
  def require_login_as_admin(cardset)
    if !signed_in?
      request_login
    elsif !signed_in_as_admin?(cardset)
      redirect_to(cardset, :notice => "Only admins of #{cardset.name} are permitted to access that page")
    end
  end

  def request_login
    store_location
    redirect_to signin_path, :notice => "Please sign in to access this page."
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    clear_return_to
  end

  def clear_return_to
    session[:return_to] = nil
  end

  private

    def user_from_remember_token
      User.authenticate_with_salt(*remember_token) # * operator - expand array to supply multiple input args
    end

    def remember_token
      cookies.signed[:remember_token] || [nil, nil]
    end
end
