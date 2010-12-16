class MechanicsController < ApplicationController

  before_filter do # :except => [:index, :new, :create] do
    @cardset = Cardset.find(params[:cardset_id])
    require_permission_to_view(@cardset)
  end
  before_filter :only => [:new, :create, :edit, :update, :destroy] do
    require_permission_to_admin(@cardset)
  end


  # GET /mechanics/new
  def new
    @mechanic = @cardset.mechanics.build  
  end

  # GET /mechanics/1/edit
  def edit
    @mechanic = Mechanic.find(params[:id])
  end

  # POST /mechanics
  def create
    @mechanic = @cardset.mechanics.build(params[:mechanic])

    if @mechanic.save
      redirect_to cardset_mechanics_path(@cardset)
    else
      render :action => "new"
    end
  end
  
  # PUT /mechanics/1
  def update
    @mechanic = Mechanic.find(params[:id])

    if @mechanic.update_attributes(params[:mechanic])
      redirect_to cardset_mechanics_path(@cardset)
    else
      render :action => "edit"
    end
  end

  # DELETE /mechanics/1
  def destroy
    @mechanic = Mechanic.find(params[:id])
    @mechanic.destroy

    redirect_to cardset_mechanics_path(@cardset)
  end
end
