class UsersController < ApplicationController
  before_filter :correct_user, :only => [:edit, :update, :destroy]
  before_filter :admin_user,   :only => :destroy
  before_filter :not_signed_in,:only => [:new, :create]

  # GET /users
  # GET /users.xml
  def index
    @title = "All users"
    @users = User.paginate(:page => params[:page], :per_page => 50 )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])
    @title = @user.name

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    # @user defined by the correct_user check
    @title = "Edit profile"
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])

    if @user.save
      sign_in @user
      flash[:success] = "Welcome to Multiverse. You're now signed in and can create cardsets!"
      redirect_to @user
    else
      @title = "Sign up"
      render 'new'
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    # @user defined by the current_user check

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to(@user, :notice => 'User was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    flash[:success] = "User destroyed."

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end

  private

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_path) unless @user == current_user
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end

    def not_signed_in
      redirect_to(root_path) if signed_in?
    end

end
