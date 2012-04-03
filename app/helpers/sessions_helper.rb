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
    signed_in? && (signed_in_as_moderator? || current_user.id == cardset.user_id)
  end
  def signed_in_as_owner?(cardset)
    signed_in? && (signed_in_as_moderator? || current_user.id == cardset.user_id)
  end
  def signed_in_as_moderator?
    signed_in? && current_user.id == 1
  end

  def require_any_login
    if !signed_in?
      interrupt_for_login :notice => "Please sign in to access this page."
    end
  end
  def require_login_as_admin(cardset)
    if !signed_in?
      interrupt_for_login :notice => "Please sign in. Only admins of #{cardset.name} are permitted to access that page."
    elsif !signed_in_as_admin?(cardset)
      redirect_to :back, :notice => "Only admins of #{cardset.name} are permitted to access that page."
    end
  end
  def require_login_as_moderator
    if !signed_in?
      interrupt_for_login :notice => "Only moderators are permitted to access that page."
    elsif !signed_in_as_moderator?
      redirect_to :back, :notice => "Only moderators are permitted to access that page."
    end
  end
  def require_permission_to(action, cardset)
    if !permission_to?(action, cardset)
      if !signed_in?
        interrupt_for_login :notice => cardset.permission_message(action) and return false
      else
        redirect_to :back, :notice => cardset.permission_message(action) and return false
      end
    else
      return true
    end
  end
  def require_permission_to_edit_comment(comment)
    if !permission_to_edit?(comment)
      if !signed_in?
        interrupt_for_login :notice => "Only the comment's author may edit it."
      else
        redirect_to :back, :notice => "Only the comment's author may edit it."
      end
    end
  end
  # Convenience methods
  def require_permission_to_view(cardset)
    require_permission_to(:view, cardset)
  end
  def require_permission_to_edit(cardset)
    require_permission_to(:edit, cardset)
  end
  def require_permission_to_admin(cardset)
    require_permission_to(:admin, cardset)
  end

  def permission_to?(action, cardset)
    # This needs to be in sessions_helper because the model doesn't have access to methods like signed_in?
    case action
      when :comment
        permitted_people = cardset.configuration.commentability
      when :view
        permitted_people = cardset.configuration.visibility
      when :edit
        permitted_people = cardset.configuration.editability
      when :admin
        permitted_people = cardset.configuration.adminability
      when :delete
        permitted_people = "justme"
      else
        raise "Bad input to permission_to?(#{action})"
    end
    case permitted_people.to_s
      when "anyone"
        out = true
      when "signedin"
        out = signed_in?
      when "admins"
        out = signed_in_as_admin?(cardset)
      when "justme"
        out = signed_in_as_owner?(cardset)
      when "selected"
        return cardset.configuration.permitted_users(action).include?(current_user.name)
      else
        raise "Unexpected value of configuration property in action #{action}: \"#{permitted_people}\""
    end
  end

  def permission_to_edit?(comment)
    signed_in_as_moderator? || (current_user && comment.user && current_user.id == comment.user.id)
  end
  def show_comment_admin_status?
    TODO
  end

  def set_last_edit(object)
    object.last_edit_by = current_user ? current_user.id : User.NON_SIGNED_IN_USER
    object.save!
  end

  def current_user=(user) # the setter for current_user
    @current_user = user
  end
  def current_user        # the getter for current_user
    @current_user ||= user_from_remember_token
  end


  def interrupt_for_login(noticehash)
    store_location
    redirect_to signin_path, noticehash
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
  
  #### Caching
  
  def expire_all_cardset_caches
    expire_fragment :controller => 'cardsets', :id => @cardset.id, :action => :visualspoiler
    expire_fragment :controller => 'cardsets', :id => @cardset.id, :action => :cardlist
    expire_fragment :controller => 'cardsets', :id => @cardset.id, :action => :show
  end
  
  #### Private

  private

    def user_from_remember_token
      User.authenticate_with_salt(*remember_token) # * operator - expand array to supply multiple input args
    end

    def remember_token
      cookies.signed[:remember_token] || [nil, nil]
    end
end
