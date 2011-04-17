class CommentsController < ApplicationController
  before_filter :define_card_or_cardset
  before_filter :only => [:show, :new, :create, :index] do
    require_permission_to_view(@cardset)
  end
  before_filter :only => [:create] do
    if !signed_in?
      ensure_not_spam
    end
  end
  before_filter :only => [:edit, :destroy] do
    require_permission_to_edit_comment(@comment)
  end
  before_filter :only => :update do
    if params[:comment][:body]
      Rails.logger.info "Requiring permission to edit comment"
      require_permission_to_edit_comment(@comment)
    else # changing status of a comment
      Rails.logger.info "Requiring permission to edit card"
      require_permission_to_edit(@cardset)
    end
  end

  def ensure_not_spam
    body_text = params[:comment][:body]
    # Look for Markdown links or HTML links
    # We allow autocard links [[[]]] or ((())) - so call Markdown without first calling format_links
    formatted_comment_text = RDiscount.new(body_text).to_html.html_safe
    Rails.logger.info "Inspecting comment with body #{body_text} - formats to #{formatted_comment_text}"
    if formatted_comment_text =~ /<a[^>]*href/i
      redirect_to spam_path
    end
  end

  def define_card_or_cardset
    # Define @comment if available
    if params[:id]
      @comment = Comment.find_by_id(params[:id])
    end
    # Define @card if available
    if params[:card_id]
      @card = Card.find_by_id(params[:card_id])
    elsif params[:comment] && params[:comment][:card_id]
      @card = Card.find_by_id(params[:comment][:card_id])
    elsif @comment && @comment.card
      @card = @comment.card
    end
    # Define @cardset if available
    if params[:cardset_id]
      @cardset = Cardset.find_by_id(params[:cardset_id])
    elsif params[:comment] && params[:comment][:cardset_id]
      @cardset = Cardset.find_by_id(params[:comment][:cardset_id])
    elsif @card
      @cardset = @card.cardset
    elsif @comment && @comment.cardset
      @cardset = @comment.cardset
    end
  end
  
  def parent_view(comment)
    if comment.cardset
      cardset_comments_path(comment.cardset)
    else
      comment.card
    end
  end

  # NEW: only exists for cardset comments
  def new
    @comment = @cardset.comments.build
  end

  # INDEX: only exists for cardset comments
  # Includes a form to create new comment, 
  def index
    @comment = @cardset.comments.build
  end

  # POST /comments
  # Doubles up for creation of card comments and cardset comments
  def create
    if !permission_to?(:comment, @cardset)
      redirect_to :back, :error => @cardset.permission_message(:comment)
    else
      @comment = Comment.new(params[:comment])
      @comment.set_default_status!

      ok = @comment.save
      if ok
        log_kind = ( @comment.card ? :comment_card : :comment_cardset )
        @cardset.log :kind=>log_kind, :user=>current_user, :object_id=>@comment.id
      else
        flash[:error] = "Error creating comment: #{@comment.errors}"
      end
      redirect_to parent_view(@comment)
    end
  end

  # PUT /comments/1
  def update
    @comment = Comment.find(params[:id])
    @comment.update_attributes(params[:comment])
    if params[:comment][:body]
      # Log the comment itself's ID for comment editing
      @cardset.log :kind=>:comment_edit, :user=>current_user, :object_id=>@comment.id
      # set_last_edit(@comment) - comments don't have an editor stored right now
    end

    respond_to do |format|
      format.html { redirect_to parent_view(@comment) }
      format.js  { render :text => "update_comment_status(#{params[:id]}, #{params[:comment][:status]})" } # this works!
                 # { render }
                 # { render :layout => false }
    end
  end

  # DELETE /comments/1
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    @cardset.log :kind=>:comment_delete, :user=>current_user, :object_id=>@comment.parent.id

    redirect_to parent_view(@comment)
  end
end
