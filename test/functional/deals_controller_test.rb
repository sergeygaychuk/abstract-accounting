require 'test_helper'

class DealsControllerTest < ActionController::TestCase
  test "should get index deal" do
    get :index
    assert_response :success
    assert_not_nil assigns(:deals)
  end

  test "should get new deal" do
    xml_http_request :get, :new
    assert_response :success
  end

  test "should create deal" do
    assert_difference('Deal.count') do
       xml_http_request :post, :create,
                        :deal => { :tag => 'purchase tester',
                                   :rate => 30,
                                   :entity_id => entities(:zinc).id,
                                   :give_id => money(:eur).id,
                                   :give_type => "Money",
                                   :take_id => assets(:steel).id,
                                   :take_type => "Asset" }
    end
    assert_equal 1, Deal.where(:tag =>'purchase tester').count,
      'Deal \'purchase tester\' not saved'
  end

end