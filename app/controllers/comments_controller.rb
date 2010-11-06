class CommentsController < ApplicationController
  before_filter :define_card_or_cardset

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

  def redirect_to_comment_parent
    # Redirect to the card if this was a card comment, or the cardset if it was a cardset comment
    if !@comment.card.nil?
      redirect_to(@comment.card)
    elsif !@comment.cardset.nil?
      redirect_to(@comment.cardset)
    else
      redirect_to(root_path, :error => "Unexpected type of comment")
    end
  end

  # NEW: only exists for cardset comments
  def new
    @comment = @cardset.comments.build
  end

  # POST /comments
  # Doubles up for creation of card comments and cardset comments
  def create
    if !permission_to_comment(@cardset)
      redirect_to where_you_were, :notice => @cardset.comment_permission_message
    else
      @comment = Comment.new(params[:comment])
      @comment.set_default_status!

      ok = @comment.save
      if !ok
        flash[:notice] = "Error creating comment: #{@comment.errors}"
      end
      redirect_to_comment_parent
    end
  end

  # PUT /comments/1
  def update
    @comment = Comment.find(params[:id])
    @comment.update_attributes(params[:comment])

    respond_to do |format|
      format.html { redirect_to_comment_parent }
      format.js { render :layout => false }
    end
  end

  # DELETE /comments/1
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy

    redirect_to_comment_parent
  end
end
