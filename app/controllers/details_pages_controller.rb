class DetailsPagesController < ApplicationController
  before_filter do # :except => [:index, :new, :create] do
    @cardset = Cardset.find(params[:cardset_id])
    require_permission_to_view(@cardset)
  end
  before_filter :only => [:new, :create, :edit, :update, :destroy] do
    require_permission_to_admin(@cardset)
  end
  after_filter :only => [:create, :update, :destroy] do
    expire_cardset_recentchanges_line_cache
  end
  
  def expire_if_skeleton
    if @details_page.title == "Skeleton"
      expire_skeleton_cache
    end
  end

  # GET /details_pages/1
  # GET /details_pages/1.xml
  def show
    @printable = params.has_key?(:printable)
    @details_page = DetailsPage.find(params[:id])
    if @details_page.title == "Skeleton"
      redirect_to skeleton_cardset_path(@cardset)
    else
      # render
    end
  end

  # GET /details_pages/new
  def new
    @details_page = @cardset.details_pages.build  # DetailsPage.new
  end

  # GET /details_pages/1/edit
  def edit
    @details_page = DetailsPage.find(params[:id])
  end

  # POST /details_pages
  def create
    @details_page = @cardset.details_pages.build(dp_create_params)

    if @details_page.save
      set_last_edit @details_page
      expire_if_skeleton
      @cardset.log :kind=>:details_page_create, :user=>current_user, :object_id=>@details_page.id
      redirect_to([@cardset, @details_page], :notice => 'Details page was successfully created.')
    else
      render :action => "new"
    end
  end

  # PUT /details_pages/1
  # PUT /details_pages/1.js
  def update
    @details_page = DetailsPage.find(params[:id])
    dp_params = dp_update_params

    if dp_params[:order]
      # Do something completely different for reorderings
      @details_page.set_order(dp_params[:order])
      respond_to do |format|
        format.js { }
        format.html { redirect_to([@cardset, @details_page]) }
      end

    else
      # Normal update
      if @details_page.update_attributes(dp_params)
        set_last_edit @details_page
        expire_if_skeleton
        @cardset.log :kind=>:details_page_edit, :user=>current_user, :object_id=>@details_page.id
        redirect_to([@cardset, @details_page], :notice => 'Details page was successfully updated.')
      else
        render :action => "edit"
      end
    end
  end

  # DELETE /details_pages/1
  def destroy
    @details_page = DetailsPage.find(params[:id])
    @details_page.destroy
    @cardset.log :kind=>:details_page_delete, :user=>current_user, :object_id=>@cardset.id

    redirect_to(@cardset)
  end
  
  private
    # Rails 4 definition of accessible params
    def dp_create_params
      params.require(:details_page).permit(:title, :body, :order, :last_edit_by, :cardset_id)
    end
    # Don't allow cardset moves via update action
    def dp_update_params
      params.require(:details_page).delete_if {|key, value| key == "cardset_id" }.permit(:title, :body, :order, :last_edit_by)
    end
end
