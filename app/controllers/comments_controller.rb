class CommentsController < ApplicationController
  before_filter :define_card

  def define_card
    @card = Card.find_by_id(params[:card_id])
  end

  # POST /comments
  # POST /comments.xml
  def create
    @comment = Comment.new(params[:comment])
    #@comment.datetime = DateTime.now

    if @comment.save
      redirect_to(@comment.card)
    else
      flash[:notice] = "Error creating comment: #{@comment.errors}"
      redirect_to(@comment.card)
    end
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    @comment = Comment.find(params[:id])

    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        format.html { redirect_to(@comment.card) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to(@comment.card) }
      format.xml  { head :ok }
    end
  end
end
