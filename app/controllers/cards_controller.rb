class CardsController < ApplicationController
  before_filter :except => [:show] do
    if !params[:cardset_id].nil?
      @cardset = Cardset.find(params[:cardset_id])
    elsif !params[:id].nil?
      @card = Card.find(params[:id])
      @cardset = Cardset.find(@card.cardset_id)
    elsif !params[:card][:cardset_id].nil?
      @cardset = Cardset.find(params[:card][:cardset_id])
    else
      raise "Couldn't find cardset id"
    end
    require_login_as_admin(@cardset)
  end
  before_filter :only => [:show] do
    @card = Card.find(params[:id])
    @cardset = Cardset.find(@card.cardset_id)
  end

  before_filter :require_permission_to_view
  helper CardsHelper

  # GET /cards/1
  # GET /cards/1.xml
  def show
    @card = Card.find(params[:id])
    @comment = Comment.new(:card => @card)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @card }
    end
  end

  # GET /cards/new
  # GET /cards/new.xml
  def new
    @card = Card.new(:cardset_id => params[:cardset_id])
    unless @cardset && @cardset.new_record?
      @cardset = Cardset.find(params[:cardset_id])
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @card }
    end
  end

  # GET /cards/1/edit
  def edit
    @card = Card.find(params[:id])
    @render_frame = @card.frame
    Rails.logger.info "render_frame is #{@render_frame}, calculated frame is #{@card.calculated_frame}"
    if @card.calculated_frame == @card.frame
      @card.frame = "Auto"
    end
  end

  def process_card
    if @card.frame == "Auto"
      @card.frame = @card.calculated_frame
    end
  end

  # POST /cards
  # POST /cards.xml
  def create
    @card = Card.new(params[:card])
    process_card

    respond_to do |format|
      if @card.save
        format.html { redirect_to(@card, :notice => 'Card was successfully created.') }
        format.xml  { render :xml => @card, :status => :created, :location => @card }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @card.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cards/1
  # PUT /cards/1.xml
  def update
    @card = Card.find(params[:id])

    respond_to do |format|
      if @card.update_attributes(params[:card])
        process_card
        @card.save!
        format.html { redirect_to(@card, :notice => 'Card was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @card.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cards/1
  # DELETE /cards/1.xml
  def destroy
    @card = Card.find(params[:id])
    @cardset = @card.cardset
    @card.destroy

    respond_to do |format|
      format.html { redirect_to(@cardset) }
      # Horrible MVC violation, but I just can't get .js.erb files to render
      format.js   { render :text => "$('card_row_#{params[:id]}').visualEffect('Fade', {'queue':'parallel'})" }
    end
  end
end
