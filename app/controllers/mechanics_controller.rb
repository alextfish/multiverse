class MechanicsController < ApplicationController

  before_filter do # :except => [:index, :new, :create] do
    @cardset = Cardset.find(params[:cardset_id])
    require_permission_to_view @cardset
  end
  before_filter :only => [:new, :create, :edit, :update, :destroy] do
    require_permission_to_admin @cardset
  end
  after_filter :only => [:create, :update, :destroy] do
    expire_all_cardset_caches
  end


  # GET /mechanics/new
  def new
    @mechanic = @cardset.mechanics.build  
  end

  # GET /mechanics/1/edit
  def edit
    @mechanic = Mechanic.find(params[:id])
    @mechanic.reminder = @mechanic.displayed_reminder
  end

  # POST /mechanics
  def create
    @mechanic = @cardset.mechanics.build(params[:mechanic])

    if @mechanic.save
      @cardset.log :kind=>:mechanic_create, :user=>current_user, :object_id=>@mechanic.id
      redirect_to cardset_mechanics_path(@cardset)
    else
      render :action => "new"
    end
  end
  
  # PUT /mechanics/1
  def update
    @mechanic = Mechanic.find(params[:id])

    if @mechanic.update_attributes(params[:mechanic])
      @cardset.log :kind=>:mechanic_edit, :user=>current_user, :object_id=>@mechanic.id
      redirect_to cardset_mechanics_path(@cardset)
    else
      render :action => "edit"
    end
  end

  # DELETE /mechanics/1
  def destroy
    @mechanic = Mechanic.find(params[:id])
    @mechanic.destroy
    @cardset.log :kind=>:mechanic_delete, :user=>current_user, :object_id=>@cardset.id

    redirect_to cardset_mechanics_path(@cardset)
  end
end
