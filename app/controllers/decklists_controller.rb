class DecklistsController < ApplicationController
  before_filter do # :except => [:index, :new, :create] do
    if params[:cardset_id]
      @cardset = Cardset.find(params[:cardset_id])
    end
    if params[:id]
      @decklist = Decklist.find(params[:id])
    end
  end
  before_filter :only => [:edit, :update, :destroy] do
    require_permission_to_edit(@decklist)
  end
  #before_filter :only => [:new, :create, :edit, :update, :destroy] do
  #  require_permission_to_admin @cardset
  #end

  # GET /decklists/new
  def new
    @decklist = Decklist.new
  end

  # GET /decklists/1
  def show
  end

  # GET /decklists/1/edit
  def edit
  end

  # POST /decklists
  def create
    params[:decklist][:status] = Decklist::DEFAULT_STATUS
    if @cardset
      @decklist = @cardset.decklists.build(params[:decklist])
    else
      @decklist = current_user.decklists.build(params[:decklist])
    end

    if @decklist.save
      current_user.set_active_decklist(@decklist)
      redirect_to @decklist
    else
      render :action => "new"
    end
  end

  # PUT /decklists/1
  def update
    if @decklist.update_attributes(params[:decklist])
      #set_last_edit @decklist 
      #@cardset.log :kind=>:decklist_edit, :user=>current_user, :object_id=>@decklist.id
      redirect_to @decklist
    else
      render :action => "edit"
    end
  end
  def add_lands
    this_basic = Card.basic_land.select {|basic| basic.name == params[:basic]}.first
    if this_basic.present?
      @decklist.add_wizards_card(this_basic.name, 4, Decklist.basic_land_section)
      respond_to do |format|
        format.html { redirect_to @decklist }
        format.js
      end
    end
  end
  
  # All card_adding/card_removing/etc methods should call @decklist.reset_stats
  def add_card
    decklist.deck_cards.create(card_id: params[:card_id])
  end

  # DELETE /decklists/1
  def destroy
    @decklist.destroy
    #@cardset.log :kind=>:decklist_delete, :user=>current_user, :object_id=>@decklist.id

    redirect_to(@cardset || current_user)
  end
end
