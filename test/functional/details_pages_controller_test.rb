require 'test_helper'

class DetailsPagesControllerTest < ActionController::TestCase
  setup do
    @details_page = details_pages(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:details_pages)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create details_page" do
    assert_difference('DetailsPage.count') do
      post :create, :details_page => @details_page.attributes
    end

    assert_redirected_to details_page_path(assigns(:details_page))
  end

  test "should show details_page" do
    get :show, :id => @details_page.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @details_page.to_param
    assert_response :success
  end

  test "should update details_page" do
    put :update, :id => @details_page.to_param, :details_page => @details_page.attributes
    assert_redirected_to details_page_path(assigns(:details_page))
  end

  test "should destroy details_page" do
    assert_difference('DetailsPage.count', -1) do
      delete :destroy, :id => @details_page.to_param
    end

    assert_redirected_to details_pages_path
  end
end
