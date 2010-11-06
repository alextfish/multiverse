class ConfigurationsController < ApplicationController
  before_filter do # :except => [:index, :new, :create] do
    @cardset = Cardset.find(params[:cardset_id])
  end
  before_filter :only => [:new, :create, :edit, :update, :destroy] do
    require_login_as_admin(@cardset)
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
  # POST /configurations.xml
  def create
    @configuration = @cardset.configuration.build(params[:configuration])

    respond_to do |format|
      if @configuration.save
        format.html { redirect_to(@configuration, :notice => 'Configuration was successfully created.') }
        format.xml  { render :xml => @configuration, :status => :created, :location => @configuration }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @configuration.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /configurations/1
  # PUT /configurations/1.xml
  def update
    @configuration = Configuration.find(params[:id])

    respond_to do |format|
      if @configuration.update_attributes(params[:configuration])
        format.html { redirect_to(@configuration, :notice => 'Configuration was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @configuration.errors, :status => :unprocessable_entity }
      end
    end
  end
end
