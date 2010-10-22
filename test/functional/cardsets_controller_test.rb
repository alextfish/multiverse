require 'test_helper'

class CardsetsControllerTest < ActionController::TestCase
  setup do
    @cardset = cardsets(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:cardsets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create cardset" do
    assert_difference('Cardset.count') do
      post :create, :cardset => @cardset.attributes
    end

    assert_redirected_to cardset_path(assigns(:cardset))
  end

  test "should show cardset" do
    get :show, :id => @cardset.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @cardset.to_param
    assert_response :success
  end

  test "should update cardset" do
    put :update, :id => @cardset.to_param, :cardset => @cardset.attributes
    assert_redirected_to cardset_path(assigns(:cardset))
  end

  test "should destroy cardset" do
    assert_difference('Cardset.count', -1) do
      delete :destroy, :id => @cardset.to_param
    end

    assert_redirected_to cardsets_path
  end
end
