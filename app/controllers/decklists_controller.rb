class DecklistsController < ApplicationController
  before_filter do # :except => [:index, :new, :create] do
    if params[:cardset_id]
      @cardset = Cardset.find(params[:cardset_id])
    end
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
    @decklist = Decklist.find(params[:id])
  end

  # GET /decklists/1/edit
  def edit
    @decklist = Decklist.find(params[:id])
  end

  # POST /decklists
  def create
    @decklist = @cardset.decklist.build(params[:decklist])

    if @decklist.save
      redirect_to @decklist
    else
      render :action => "new"
    end
  end

  # PUT /decklists/1
  def update
    @decklist = Decklist.find(params[:id])

    if @decklist.update_attributes(params[:decklist])
      set_last_edit @decklist 
      @cardset.log :kind=>:cardset_options, :user=>current_user, :object_id=>@cardset.id
      redirect_to @decklist
    else
      render :action => "edit"
    end
  end
end
