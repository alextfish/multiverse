class ConfigurationsController < ApplicationController
  before_filter do # :except => [:index, :new, :create] do
    @cardset = Cardset.find(params[:cardset_id])
  end
  before_filter :only => [:new, :create, :edit, :update, :destroy] do
    require_permission_to_admin @cardset
  end

  # GET /configurations/1
  def show
    @configuration = Configuration.find(params[:id])
  end

  # GET /configurations/new
  def new
    @configuration = Configuration.new
  end

  # GET /configurations/1/edit
  def edit
    @configuration = Configuration.find(params[:id])
  end

  # POST /configurations
  def create
    @configuration = @cardset.configuration.build(params[:configuration])

    if @configuration.save
      redirect_to @configuration, :notice => 'Configuration was successfully created.'
    else
      render :action => "new"
    end
  end

  # PUT /configurations/1
  def update
    @configuration = Configuration.find(params[:id])

    if @configuration.update_attributes(params[:configuration])
      set_last_edit @configuration 
      @cardset.log :kind=>:cardset_options, :user=>current_user, :object_id=>@cardset.id
      redirect_to @configuration, :notice => 'Configuration was successfully updated.'
    else
      render :action => "edit"
    end
  end
end
