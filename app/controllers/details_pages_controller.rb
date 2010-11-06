class DetailsPagesController < ApplicationController
  before_filter do # :except => [:index, :new, :create] do
    @cardset = Cardset.find(params[:cardset_id])
    require_permission_to_view
  end
  before_filter :only => [:new, :create, :edit, :update, :destroy] do
    require_login_as_admin(@cardset)
  end

  # GET /details_pages/1
  # GET /details_pages/1.xml
  def show
    @details_page = DetailsPage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @details_page }
    end
  end

  # GET /details_pages/new
  # GET /details_pages/new.xml
  def new
    @details_page = @cardset.details_pages.build  # DetailsPage.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @details_page }
    end
  end

  # GET /details_pages/1/edit
  def edit
    @details_page = DetailsPage.find(params[:id])
  end

  # POST /details_pages
  # POST /details_pages.xml
  def create
    @details_page = @cardset.details_pages.build(params[:details_page])

    respond_to do |format|
      if @details_page.save
        format.html { redirect_to([@cardset, @details_page], :notice => 'Details page was successfully created.') }
        format.xml  { render :xml => @details_page, :status => :created, :location => @details_page }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @details_page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /details_pages/1
  # PUT /details_pages/1.xml
  def update
    @details_page = DetailsPage.find(params[:id])

    respond_to do |format|
      if @details_page.update_attributes(params[:details_page])
        format.html { redirect_to([@cardset, @details_page], :notice => 'Details page was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @details_page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /details_pages/1
  # DELETE /details_pages/1.xml
  def destroy
    @details_page = DetailsPage.find(params[:id])
    @details_page.destroy

    respond_to do |format|
      format.html { redirect_to(@cardset) }
      format.xml  { head :ok }
    end
  end
end
