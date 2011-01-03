class CardsetsController < ApplicationController
  before_filter :except => [:index, :new, :create] do
    @cardset = Cardset.find(params[:id])
    require_permission_to_view(@cardset)
  end
  before_filter :only => [:new, :create] do
    require_any_login
  end
  before_filter :only => [:edit, :update, :destroy, :todo] do
    require_permission_to_admin(@cardset)
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
      format.text  { render }  
      format.csv  { render }  
    end
  end

  # GET /cardsets/1/visualspoiler
  def visualspoiler
  end

  # GET /cardsets/1/recent
  def recent
  end

  # GET /cardsets/1/todo
  def todo
  end

  # GET /cardsets/1/import
  def import
  end

  # GET /cardsets/1/export
  def export
    respond_to do |format|
      format.html # export.html.erb
      format.xml  { render :xml => @cardset }
    end
  end

  def booster 
    begin
      @booster, err_message, data = @cardset.make_booster()
      if @booster.nil?
        flash[:error] = err_message
        redirect_to :back #, :error => err_message
      else
        @m10_collation = data[0]
        render
      end
      # I just can't get "rescue Exceptions::BoosterError => e" to work, it gives "uninit constant" errors
    end
  end

  # POST /cardsets/1/import_data
  def import_data
    Rails.logger.info "User #{current_user} importing data"
    success, message, log_text, changed_cards = @cardset.import_data(params, current_user)
    if success
      changed_cards.each do |card|
        set_last_edit card 
      end
      @cardset.log :kind=>:cardset_import, :user=>current_user, :object_id=>@cardset.id, :text=>log_text
      redirect_to @cardset, :notice => message 
    else
      flash.now[:error] = message
      render :import
    end
  end

  # GET /cardsets/new
  def new
    @cardset = Cardset.new
    @cardset.user_id = current_user.id
    @cardset.build_configuration
    @cardset.configuration.set_default_values!
  end

  # GET /cardsets/1/edit
  def edit
  end

  # POST /cardsets
  # POST /cardsets.xml
  def create
    @cardset = Cardset.new(params[:cardset])
    @cardset.user_id = current_user.id

    configuration = @cardset.build_configuration(params[:configuration])
    ok = @cardset.save
    ok &= configuration.save

    if ok
      set_last_edit @cardset 
      @cardset.log :kind=>:cardset_create, :user=>current_user, :object_id=>@cardset.id
      redirect_to @cardset, :notice => 'Cardset was successfully created.' 
    else
      render :action => "new"
    end
  end

  # PUT /cardsets/1
  def update
    ok = @cardset.update_attributes(params[:cardset])
    ok &= @cardset.configuration.update_attributes(params[:configuration])
    if ok
      set_last_edit @cardset 
      @cardset.log :kind=>:cardset_options, :user=>current_user, :object_id=>@cardset.id
      redirect_to @cardset, :notice => 'Cardset was successfully updated.' 
    else
      render :action => "edit"
    end
  end

  # DELETE /cardsets/1
  def destroy
    @cardset.destroy

    redirect_to(cardsets_url)
  end
end
