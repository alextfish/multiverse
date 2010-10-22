require 'test_helper'

class OldCardsControllerTest < ActionController::TestCase
  setup do
    @old_card = old_cards(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:old_cards)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create old_card" do
    assert_difference('OldCard.count') do
      post :create, :old_card => @old_card.attributes
    end

    assert_redirected_to old_card_path(assigns(:old_card))
  end

  test "should show old_card" do
    get :show, :id => @old_card.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @old_card.to_param
    assert_response :success
  end

  test "should update old_card" do
    put :update, :id => @old_card.to_param, :old_card => @old_card.attributes
    assert_redirected_to old_card_path(assigns(:old_card))
  end

  test "should destroy old_card" do
    assert_difference('OldCard.count', -1) do
      delete :destroy, :id => @old_card.to_param
    end

    assert_redirected_to old_cards_path
  end
end
