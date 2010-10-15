require 'test_helper'

class StylesheetsControllerTest < ActionController::TestCase
  test "should get frames" do
    get :frames
    assert_response :success
  end

end
