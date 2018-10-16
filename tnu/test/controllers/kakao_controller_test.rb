require 'test_helper'

class KakaoControllerTest < ActionDispatch::IntegrationTest
  test "should get keyboard" do
    get kakao_keyboard_url
    assert_response :success
  end

  test "should get message" do
    get kakao_message_url
    assert_response :success
  end

end
