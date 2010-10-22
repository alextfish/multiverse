class CardsetsController < ApplicationController
  before_filter :except => [:index, :new, :create] do
    @cardset = Cardset.find(params[:id])
  end
  before_filter :only => [:new, :create] do
    :require_login
  end
  before_filter :only => [:edit, :update, :destroy] do
    require_login_as_admin(@cardset)
  end

  # GET /cardsets
  # GET /cardsets.xml
  def index
    @cardsets = Cardset.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cardsets }
    end
  end

  # GET /cardsets/1
  # GET /cardsets/1.xml
  def show
    @cardset = Cardset.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cardset }
    end
  end

  # GET /cardsets/1/cardlist
  # GET /cardsets/1/cardlist.xml
  def cardlist
    @cardset = Cardset.find(params[:id])

    respond_to do |format|
      format.html # cardlist.html.erb
      format.xml  { render :xml => @cardset.cards }   # ??
    end
  end

  # GET /cardsets/1/visualspoiler
  def visualspoiler
    @cardset = Cardset.find(params[:id])
  end

  # GET /cardsets/1/import
  def import
    @cardset = Cardset.find(params[:id])
    # import.html.erb
  end

  # GET /cardsets/1/export
  def export
    @cardset = Cardset.find(params[:id])
    respond_to do |format|
      format.html # export.html.erb
      format.xml  { render :xml => @cardset }
    end
  end

  # POST /cardsets/1/import_data
  def import_data
    @cardset = Cardset.find(params[:id])
    success, message = @cardset.import_data(params)
    if success
      redirect_to(@cardset, :notice => message)
    else
      flash.now[:error] = message
      render :action => "import"
    end
  end

  # GET /cardsets/new
  # GET /cardsets/new.xml
  def new
    @cardset = Cardset.new
    #@cardset.user_id = current_user.id

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cardset }
    end
  end

  # GET /cardsets/1/edit
  def edit
    @cardset = Cardset.find(params[:id])
  end

  # POST /cardsets
  # POST /cardsets.xml
  def create
    @cardset = Cardset.new(params[:cardset])
    @cardset.user_id = current_user.id

    respond_to do |format|
      if @cardset.save
        format.html { redirect_to(@cardset, :notice => 'Cardset was successfully created.') }
        format.xml  { render :xml => @cardset, :status => :created, :location => @cardset }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cardset.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cardsets/1
  # PUT /cardsets/1.xml
  def update
    @cardset = Cardset.find(params[:id])

    respond_to do |format|
      if @cardset.update_attributes(params[:cardset])
        format.html { redirect_to(@cardset, :notice => 'Cardset was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cardset.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cardsets/1
  # DELETE /cardsets/1.xml
  def destroy
    @cardset = Cardset.find(params[:id])
    @cardset.destroy

    respond_to do |format|
      format.html { redirect_to(cardsets_url) }
      format.xml  { head :ok }
    end
  end
end
