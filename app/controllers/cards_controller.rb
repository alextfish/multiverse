class CardsController < ApplicationController
  before_filter :find_cardset
  before_filter :only => [:new, :create, :edit, :update] do
    require_permission_to_edit(@cardset)
  end
  before_filter do
    @printable = params.has_key?(:printable)
  end
  before_filter :except => [:new, :create] do |controller|
    # Redirect to secondary
    @card = Card.find(params[:id])
    Rails.logger.info "Controller params are: " +controller.params.inspect
    if @card.secondary?
      if controller.params["action"] == "mockup" && @card.flip?
        # Mockups of flip secondaries we allow to render, inverted
        @card = @card.primary_card
        @extra_styles = "rotated"
      else
        redirect_to :action => controller.params["action"], :id => @card.parent_id
      end
    end
  end
  before_filter :only => [:update] do
    if !signed_in?
      ensure_not_spam
    end
  end
  before_filter :only => :destroy do
    require_permission_to(:delete, @cardset)
  end
  before_filter :only => :move do
    require_permission_to(:admin, @cardset)
  end
  before_filter :except => :mockup do
    require_permission_to_view(@cardset)
  end
  # For the embedded views, if authentication fails just return an appropriate blank
  before_filter :only => :mockup do
    if !permission_to?(:view, @cardset)
      redirect_to :card_back
    end
  end
  before_filter :only => :update do
    if params[:is_preview] == "true"
      # Manually call the edit function and then render edit instead
      edit()
      render :action => "edit"
    end
  end
  before_filter :only => :create do
    if params[:is_preview] == "true"
      # Render new without calling the new function 
      @card = Card.new(params[:card])
      @card.link = @card.new_linked_card
      render :action => "new"
    end
  end

  helper CardsHelper

  def find_cardset
    if !params[:cardset_id].nil?
      @cardset = Cardset.find(params[:cardset_id])
    elsif !params[:id].nil?
      @card = Card.find(params[:id])
      @cardset = @card.cardset
    elsif params[:card] && !params[:card][:cardset_id].nil?
      @cardset = Cardset.find(params[:card][:cardset_id])
    else
      redirect_to root_path, :notice => "Cards must be in a cardset"
    end
  end
  def ensure_not_spam
    edit_comment = params[:edit_comment]
    # Look for Markdown links or HTML links
    # We allow autocard links [[[]]] or ((())) - so call Markdown without first calling format_links
    formatted_comment_text = RDiscount.new(edit_comment).to_html.html_safe
    Rails.logger.info "Inspecting edit comment of #{edit_comment} - formats to #{formatted_comment_text}"
    if formatted_comment_text =~ /<a[^>]*href/i
      redirect_to spam_path
    end
  end

  # GET /cards/1
  # GET /cards/1.xml
  def show
    @card2 = @card.link
    @comment = Comment.new(:card => @card)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @card }
    end
  end

  # GET /cards/new
  def new
    @cardset = Cardset.find(params[:cardset_id])
    @card = Card.new(:cardset_id => params[:cardset_id])
    if params[:code] =~ Card.code_regexp
      @card.code = params[:code]
      @card.rarity, @card.frame = Card.interpret_code params[:code]
      Rails.logger.info "Detected valid code #{params[:code]}: using rarity #{@card.rarity} and frame #{@card.frame}"
    elsif params[:colour] && Card.frames.include?(params[:colour])
      @card.frame = params[:colour]
    else
      @card.frame = "Auto"
      @card.rarity = "common"
    end
    @card.link = @card.new_linked_card
  end
  
  def move
  end

  # GET /cards/1/edit
  def edit
    if params[:is_preview] == "true"
      Rails.logger.info "PREVIEW happening"
      @card.attributes = params[:card] # like update_attributes but no save
      if @card.attributes["frame"] == "Auto"
        @card.frame = @card.calculated_frame
      end
      Rails.logger.info @card.inspect
    end
    @render_frame = @card.frame
    if @card.calculated_frame == @card.frame
      @card.frame = "Auto"
      Rails.logger.info "Using Auto frame"
    else
      Rails.logger.info "Not using Auto frame as calculated_frame is '#{@card.calculated_frame}' but frame is '#{@card.frame}'..."
    end
    @card.link ||= @card.new_linked_card
  end

  def process_card
    if @card.attributes["frame"] == "Auto"
      @card.frame = @card.calculated_frame
      @card.save!
    end
  end

  # POST /cards
  def create
    @card = Card.new(params[:card])
    # TODO for multipart
    process_card
    set_last_edit @card

    if @card.save
      @cardset.log :kind=>:card_create, :user=>current_user, :object_id=>@card.id
      if @card.link.nil?
        # The creation failed validation because it was empty
        # Revert @card.multipart
        @card.multipart = Card.STANDALONE
        @card.save!
      else
        set_link_fields
      end
      redirect_to @card, :notice => "#{@card.printable_name} was successfully created." 
    else
      render :action => "new"
    end
  end

  # PUT /cards/1
  def update
    # TODO for multipart
    @card2 = @card.link
    old_multipart = @card.multipart?
    if @card.update_attributes(params[:card])
      new_multipart = @card.multipart?
      process_card
      set_last_edit @card
      @cardset.log :kind=>:card_edit, :user=>current_user, :object_id=>@card.id, :text=>params[:edit_comment]
      if old_multipart && !new_multipart
        # Delete the old partner
        Rails.logger.info "Delete partner"
        @card2.destroy
        @card.link = nil
        @card.save!
      elsif !old_multipart && new_multipart 
        # Creating a new partner should be done automatically via update_attributes
        if @card.link.nil?
          # The creation failed validation because it was empty
          # Revert @card.multipart
          @card.multipart = Card.STANDALONE
          @card.save!
        else
          set_link_fields
        end
      end

      redirect_to @card   #, :notice => 'Card was successfully updated.'
    else
      render :action => "edit"
    end
  end
  
  def process_move
    @cardset1 = @card.cardset
    @cardset2 = Cardset.find(params[:card][:cardset_id])
    require_permission_to(:admin, @cardset1) or return
    require_permission_to_edit(@cardset2) or return
    if @card.update_attributes(params[:card])
      process_card
      set_last_edit @card
      @cardset1.log :kind=>:card_move_out, :user=>current_user, :object_id=>@card.id, :text=>@cardset2.name
      @cardset2.log :kind=>:card_move_in, :user=>current_user, :object_id=>@card.id, :text=>@cardset1.name
      
      if (@card2 = @card.link)
        @card2.cardset = @card.cardset  # no logs needed for secondary cards
        @card2.save
      end

      redirect_to @card, :notice => "Card was moved from #{@cardset1.name} to #{@cardset2.name}."
    else
      render :action => "edit"
    end
  end
  
  def set_link_fields
    case @card.multipart
      when Card.FLIP1
        @card.link.multipart = Card.FLIP2
        @card.link.parent = @card
        @card.link.save! :validate => false 
      when Card.SPLIT1
        @card.link.multipart = Card.SPLIT2
        @card.link.parent = @card
        @card.link.save! :validate => false 
    end
  end
  
  # GET /cards/1/mockup - via Ajax
  def mockup
    @printable = true
    @embedded = true
    @card2 = @card.link 
  end

  # DELETE /cards/1
  def destroy
    @cardset = @card.cardset
    if (@card2 = @card.link)
      @card2.destroy
    end
    @card.destroy

    respond_to do |format|
      format.html do
        @cardset.log :kind=>:card_delete, :user=>current_user, :object_id=>@cardset.id
        redirect_to @cardset
      end
      # Horrible MVC violation, but I just can't get .js.erb files to render
      # Can only destroy cards via JS from the cardlist view
      format.js   do
        render :text => "$('card_row_#{params[:id]}').visualEffect('Fade', {'queue':'parallel'})" 
      end
    end
  end
end
