require 'test_helper'

class WaybillTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "validate waybill" do
    assert Entity.new(:tag => "Storekeeper").save, "Entity not saved"
    assert Entity.new(:tag => "Organization").save, "Entity not saved"
    assert Place.new(:tag => "Moscow").save, "Entity not saved"

    assert Waybill.new.invalid?, "Empty waybill is valid"
    assert Waybill.new(:document_id => "12345").invalid?,
      "Wrong waybill"
    assert Waybill.new(:document_id => "12345",
                       :owner => Entity.find_by_tag("Storekeeper")).invalid?,
      "Wrong waybill"
    assert Waybill.new(:document_id => "12345",
                       :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow")).invalid?,
      "Wrong waybill"
    assert Waybill.new(:document_id => "12345",
                       :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization")).invalid?,
      "Wrong waybill"
    wb = Waybill.new(:document_id => "12345",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization"),
      :created => DateTime.civil(2011, 5, 11, 12, 0, 0))
    assert wb.invalid?, "invalid waybill"
    wb.add_resource("Test resource", "th", -1)
    assert wb.invalid?, "invalid waybill"

    wb = Waybill.new(:document_id => "12345",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization"),
      :created => DateTime.civil(2011, 5, 11, 12, 0, 0))
    assert wb.invalid?, "invalid waybill"
    wb.add_resource("Test resource", "th", 10)
    assert wb.valid?, "valid waybill"
    wb.add_resource("Test resource2", "th", -1)
    assert wb.invalid?, "invalid waybill"

    wb = Waybill.new(:document_id => "12345",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization"),
      :created => DateTime.civil(2011, 5, 11, 12, 0, 0))
    assert wb.invalid?, "invalid waybill"
    wb.add_resource("Test resource", "th", 10)
    assert wb.valid?, "valid waybill"
    assert wb.save, "Waybill not saved"
  end

  test "validate VATIN" do
    wb = Waybill.new(:document_id => "12345",
              :created => DateTime.now,
              :owner => entities(:sergey),
              :from => entities(:abstract),
              :place => places(:orsha))
    wb.add_resource "roof", "m2", 500
    assert wb.valid?, "Waybill is not valid"

    wb.vatin = "1234"
    assert wb.invalid?, "Waybill short vatin number"

    wb.vatin = "1234567890123"
    assert wb.invalid?, "Waybill long vatin number"

    wb.vatin = "7830002293"
    assert wb.valid?, "Waybill valid vatin number"

    wb.vatin = "7830002295"
    assert wb.invalid?, "Waybill invalid vatin number"

    wb.vatin = "500100732259"
    assert wb.valid?, "Waybill valid vatin number"

    wb.vatin = "500100732269"
    assert wb.invalid?, "Waybill invalid vatin number"

    wb.vatin = "500100732253"
    assert wb.invalid?, "Waybill invalid vatin number"

    wb.vatin = "1234d678901a"
    assert wb.invalid?, "Waybill invalid vatin number"
  end

  test "VATIN must be unique" do
    wb = Waybill.new(:document_id => "12345",
                     :created => DateTime.now, :owner => entities(:sergey),
              :from => entities(:abstract),
              :place => places(:orsha))
    wb.add_resource "roof", "m2", 500
    assert wb.valid?, "Waybill is not valid"
    wb.vatin = "500100732259"
    assert wb.save, "Waybill is not saved"

    wb = Waybill.new(:document_id => "123456",
                     :created => DateTime.now, :owner => entities(:abstract),
              :from => entities(:sergey),
              :place => places(:orsha),
              :vatin => "500100732259")
    wb.add_resource "roof", "m2", 500
    assert wb.invalid?, "Waybill vatin is not unique"
  end

  test "assign entity as text" do
    assert Entity.new(:tag => "Storekeeper").save, "Entity not saved"
    assert Entity.new(:tag => "Organization").save, "Entity not saved"
    assert Place.new(:tag => "Moscow").save, "Entity not saved"

    wb = Waybill.new(:document_id => "12345",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :created => DateTime.civil(2011, 5, 11, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    wb.from = Entity.find_by_tag "Organization"
    assert wb.save, "Waybill not saved"

    assert Entity.new(:tag => "Some entity 2").save, "entity is not saved"
    wb = Waybill.new(:document_id => "123456",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :created => DateTime.civil(2011, 5, 11, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    wb.from = "Some entity 2"
    assert_equal Entity.find_by_tag("Some entity 2"), wb.from, "Wrong waybill from"
    assert wb.save, "Waybill is not saved"

    assert Entity.new(:tag => "Some entity 3").save, "entity is not saved"
    wb = Waybill.new(:document_id => "1234567",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :created => DateTime.civil(2011, 5, 11, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    wb.from = "Some ENTITY 3"
    assert_equal Entity.find_by_tag("Some entity 3"), wb.from, "Wrong waybill entity"
    assert wb.save, "Waybill is not saved"

    wb = Waybill.new(:document_id => "12345678",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :created => DateTime.civil(2011, 5, 11, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    wb.from = "Some entity 4"
    assert wb.from.instance_of?(Entity), "Wrong entity type"
    assert wb.save, "Waybill is not saved"
    assert_equal Entity.find_by_tag("Some entity 4"), wb.from, "Wrong waybill entity"
  end

  test "waybill entries" do
    assert Entity.new(:tag => "Storekeeper").save, "Entity not saved"
    assert Entity.new(:tag => "Organization").save, "Entity not saved"
    assert Place.new(:tag => "Moscow").save, "Entity not saved"
    
    product_length = Product.all.count

    wb = Waybill.new(:document_id => "12345",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization"),
      :created => DateTime.civil(2011, 5, 11, 12, 0, 0))
    wb.add_resource "roof", "m2", 500

    assert_equal 1, wb.resources.length, "Wrong waybill resources length"
    assert wb.resources[0].instance_of?(WaybillEntry), "Wrong waybill resource"
    assert wb.resources[0].product.instance_of?(Product), "Wrong wybill resource product"
    assert_equal 500, wb.resources[0].amount, "Wrong waybill resource amount"
    assert wb.resources[0].product.new_record?, "Wrong waybill product"
    assert_equal "roof", wb.resources[0].product.resource.tag, "Wrong waybill product resource"
    assert_equal "m2", wb.resources[0].product.unit, "Wrong waybill product unit"
    wb.add_resource "dalle", "m2", 100

    assert_equal 2, wb.resources.length, "Wrong waybill resources length"
    assert wb.resources[1].instance_of?(WaybillEntry), "Wrong waybill resource"
    assert wb.resources[1].product.instance_of?(Product), "Wrong wybill resource product"
    assert_equal 100, wb.resources[1].amount, "Wrong waybill resource amount"
    assert wb.resources[1].product.new_record?, "Wrong waybill product"
    assert_equal "dalle", wb.resources[1].product.resource.tag, "Wrong waybill product resource"
    assert_equal "m2", wb.resources[1].product.unit, "Wrong waybill product unit"
    
    assert wb.save, "Waybill is not saved"
    product_length += 2
    assert_equal product_length, Product.all.count, "Product is not saved"
  end

  test "deals is created" do
    assert Entity.new(:tag => "Storekeeper").save, "Entity not saved"
    assert Entity.new(:tag => "Organization").save, "Entity not saved"
    assert Place.new(:tag => "Moscow").save, "Entity not saved"
    
    deals_count = Deal.all.count

    wb = Waybill.new(:document_id => "12345",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization"),
      :created => DateTime.civil(2011, 5, 1, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    assert wb.save, "Waybill not saved"

    deals_count += 3
    assert_equal deals_count, Deal.all.count, "Deal is not created"
    d = Deal.find(wb.deal.id)
    assert !d.nil?, "Deal not found"
    assert_equal Entity.find_by_tag("Storekeeper"), d.entity, "Entity is not valid"
    assert_equal true, d.isOffBalance, "IsOffbalance is invalid"

    d = Deal.find_all_by_give_and_take_and_entity(Asset.find_by_tag("roof"),
      Asset.find_by_tag("roof"), Entity.find_by_tag("Organization")).first
    assert !d.nil?, "Deal not found"
    assert_equal true, d.isOffBalance, "IsOffbalance is invalid"

    d = Deal.find_all_by_give_and_take_and_entity(Asset.find_by_tag("roof"),
      Asset.find_by_tag("roof"), Entity.find_by_tag("Storekeeper")).first
    assert !d.nil?, "Deal not found"
    assert_equal true, d.isOffBalance, "IsOffbalance is invalid"

    wb = Waybill.new(:document_id => "123456",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization"),
      :created => DateTime.civil(2011, 5, 2, 12, 0, 0))
    wb.add_resource "roof", "m2", 100
    wb.add_resource "hammer", "th", 500
    assert wb.save, "Waybill not saved"

    deals_count += 3
    assert_equal deals_count, Deal.all.count, "Deal is not created"
    d = Deal.find(wb.deal.id)
    assert !d.nil?, "Deal not found"

    d = Deal.find_all_by_give_and_take_and_entity(Asset.find_by_tag("hammer"),
      Asset.find_by_tag("hammer"), Entity.find_by_tag("Organization")).first
    assert !d.nil?, "Deal not found"
    assert_equal true, d.isOffBalance, "IsOffbalance is invalid"

    d = Deal.find_all_by_give_and_take_and_entity(Asset.find_by_tag("hammer"),
      Asset.find_by_tag("hammer"), Entity.find_by_tag("Storekeeper")).first
    assert !d.nil?, "Deal not found"
    assert_equal true, d.isOffBalance, "IsOffbalance is invalid"

    assert Entity.new(:tag => "Organization 2").save, "Entity not saved"

    wb = Waybill.new(:document_id => "1234567",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization 2"),
      :created => DateTime.civil(2011, 5, 3, 12, 0, 0))
    wb.add_resource "hammer", "th", 200
    assert wb.save, "Waybill not saved"

    deals_count += 2
    assert_equal deals_count, Deal.all.count, "Deal is not created"
    d = Deal.find(wb.deal.id)
    assert !d.nil?, "Deal not found"

    d = Deal.find_all_by_give_and_take_and_entity(Asset.find_by_tag("hammer"),
      Asset.find_by_tag("hammer"), Entity.find_by_tag("Organization 2")).first
    assert !d.nil?, "Deal not found"
    assert_equal true, d.isOffBalance, "IsOffbalance is invalid"

    wb = Waybill.new(:document_id => "12345678",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization"),
      :created => DateTime.civil(2011, 5, 4, 12, 0, 0))
    wb.add_resource "hammer", "th", 50
    assert wb.save, "Waybill not saved"

    deals_count += 1
    assert_equal deals_count, Deal.all.count, "Deal is not created"
    d = Deal.find(wb.deal.id)
    assert !d.nil?, "Deal not found"
  end

  test "rules is created" do
    assert Entity.new(:tag => "Storekeeper").save, "Entity not saved"
    assert Entity.new(:tag => "Organization").save, "Entity not saved"
    assert Place.new(:tag => "Moscow").save, "Entity not saved"

    wb = Waybill.new(:document_id => "12345",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization"),
      :created => DateTime.civil(2011, 5, 1, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    assert wb.save, "Waybill not saved"

    assert_equal 1, wb.deal.rules.count, "Wrong deal rules count"
    ownerDeal = wb.resources[0].storehouse_deal wb.owner
    fromDeal = wb.resources[0].storehouse_deal wb.from
    rule = wb.deal.rules[0]
    assert_equal 500, rule.rate, "Wrong rule rate"
    assert_equal fromDeal, rule.from, "Wrong rule from"
    assert_equal ownerDeal, rule.to, "Wrong rule to"

    wb = Waybill.new(:document_id => "123456",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization"),
      :created => DateTime.civil(2011, 5, 2, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    wb.add_resource "hammer", "th", 5
    assert wb.save, "Waybill not saved"

    assert_equal 2, wb.deal.rules.count, "Wrong deal rules count"
    ownerDeal = wb.resources[0].storehouse_deal wb.owner
    fromDeal = wb.resources[0].storehouse_deal wb.from
    rule = wb.deal.rules[0]
    assert_equal 500, rule.rate, "Wrong rule rate"
    assert_equal fromDeal, rule.from, "Wrong rule from"
    assert_equal ownerDeal, rule.to, "Wrong rule to"
    ownerDeal = wb.resources[1].storehouse_deal wb.owner
    fromDeal = wb.resources[1].storehouse_deal wb.from
    rule = wb.deal.rules[1]
    assert_equal 5, rule.rate, "Wrong rule rate"
    assert_equal fromDeal, rule.from, "Wrong rule from"
    assert_equal ownerDeal, rule.to, "Wrong rule to"
  end

  test "entries is loaded" do
    assert Entity.new(:tag => "Storekeeper").save, "Entity not saved"
    assert Entity.new(:tag => "Organization").save, "Entity not saved"
    assert Place.new(:tag => "Moscow").save, "Entity not saved"

    wb = Waybill.new(:document_id => "12345",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization"),
      :created => DateTime.civil(2011, 5, 2, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    wb.add_resource "hammer", "th", 5
    assert wb.save, "Waybill not saved"

    assert_equal 1, Waybill.all.count, "Wrong waybills count"
    wb = Waybill.first
    assert !wb.nil?, "Waybill is nil"
    assert_equal 2, wb.resources.length, "Wrong waybill resources count"
    wb.resources.each do |item|
      if Asset.find_by_tag("roof") == item.product.resource
        assert_equal "m2", item.product.unit, "Wrong product unit"
        assert_equal 500, item.amount, "Wrong resource amount"
      elsif Asset.find_by_tag("hammer") == item.product.resource
        assert_equal "th", item.product.unit, "Wrong product unit"
        assert_equal 5, item.amount, "Wrong resource amount"
      else
        assert false, "Unknown resource type"
      end
    end
  end

  test "save fact for waybill entries" do
    assert Entity.new(:tag => "Storekeeper").save, "Entity not saved"
    assert Entity.new(:tag => "Organization").save, "Entity not saved"
    assert Place.new(:tag => "Moscow").save, "Entity not saved"

    wb = Waybill.new(:document_id => "12345",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization"),
      :created => DateTime.civil(2011, 5, 2, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    assert wb.save, "Waybill not saved"

    deal_owner = Deal.find_all_by_give_and_take_and_entity(Asset.find_by_tag("roof"),
      Asset.find_by_tag("roof"), Entity.find_by_tag("Storekeeper")).first
    state_owner = deal_owner.state
    assert !state_owner.nil?, "Owner state is nil"
    assert_equal "passive", state_owner.side, "Owner state side is invalid"
    assert_equal 500, state_owner.amount, "Owner state amount is invalid"
    dt_now = DateTime.now
    assert_equal DateTime.civil(dt_now.year, dt_now.month, dt_now.day, 12, 0, 0),
                 state_owner.start, "Owner state date is invalid"

    dOrganization = Deal.find_all_by_give_and_take_and_entity(Asset.find_by_tag("roof"),
      Asset.find_by_tag("roof"), Entity.find_by_tag("Organization")).first;
    sOrganization = dOrganization.state
    assert !sOrganization.nil?, "Organization state is nil"
    assert_equal "active", sOrganization.side, "Organization state side is invalid"
    assert_equal 500, sOrganization.amount, "Organization state amount is invalid"
    dt_now = DateTime.now
    assert_equal DateTime.civil(dt_now.year, dt_now.month, dt_now.day, 12, 0, 0),
                 sOrganization.start, "Organization state date is invalid"

    wb = Waybill.new(:document_id => "123456",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => Entity.find_by_tag("Organization"),
      :created => DateTime.civil(2011, 5, 3, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    wb.add_resource "hammer", "th", 5
    assert wb.save, "Waybill not saved"

    dOwner = Deal.find_all_by_give_and_take_and_entity(Asset.find_by_tag("roof"),
      Asset.find_by_tag("roof"), Entity.find_by_tag("Storekeeper")).first;
    sOwner = dOwner.state
    assert !sOwner.nil?, "Owner state is nil"
    assert_equal "passive", sOwner.side, "Owner state side is invalid"
    assert_equal 1000, sOwner.amount, "Owner state amount is invalid"
    dt_now = DateTime.now
    assert_equal DateTime.civil(dt_now.year, dt_now.month, dt_now.day, 12, 0, 0),
                 sOwner.start, "Owner state date is invalid"

    dOrganization = Deal.find_all_by_give_and_take_and_entity(Asset.find_by_tag("roof"),
      Asset.find_by_tag("roof"), Entity.find_by_tag("Organization")).first;
    sOrganization = dOrganization.state
    assert !sOrganization.nil?, "Organization state is nil"
    assert_equal "active", sOrganization.side, "Organization state side is invalid"
    assert_equal 1000, sOrganization.amount, "Organization state amount is invalid"
    dt_now = DateTime.now
    assert_equal DateTime.civil(dt_now.year, dt_now.month, dt_now.day, 12, 0, 0),
                 sOrganization.start, "Organization state date is invalid"

    dOwner = Deal.find_all_by_give_and_take_and_entity(Asset.find_by_tag("hammer"),
      Asset.find_by_tag("hammer"), Entity.find_by_tag("Storekeeper")).first;
    sOwner = dOwner.state
    assert !sOwner.nil?, "Owner state is nil"
    assert_equal "passive", sOwner.side, "Owner state side is invalid"
    assert_equal 5, sOwner.amount, "Owner state amount is invalid"
    dt_now = DateTime.now
    assert_equal DateTime.civil(dt_now.year, dt_now.month, dt_now.day, 12, 0, 0),
                 sOwner.start, "Owner state date is invalid"

    dOrganization = Deal.find_all_by_give_and_take_and_entity(Asset.find_by_tag("hammer"),
      Asset.find_by_tag("hammer"), Entity.find_by_tag("Organization")).first;
    sOrganization = dOrganization.state
    assert !sOrganization.nil?, "Organization state is nil"
    assert_equal "active", sOrganization.side, "Organization state side is invalid"
    assert_equal 5, sOrganization.amount, "Organization state amount is invalid"
    dt_now = DateTime.now
    assert_equal DateTime.civil(dt_now.year, dt_now.month, dt_now.day, 12, 0, 0),
                 sOrganization.start, "Organization state date is invalid"
  end

  test "show waybills by owner and place" do
    assert Entity.new(:tag => "Storekeeper").save, "Entity not saved"
    assert Place.new(:tag => "Moscow").save, "Entity not saved"
    assert Entity.new(:tag => "Storekeeper 2").save, "Entity not saved"
    assert Place.new(:tag => "Minsk").save, "Entity not saved"

    assert_equal 0, Waybill.by_storekeeper.length,
      "Wrong waybills count"
    assert_equal 0, Waybill.by_storekeeper(
      Entity.find_by_tag("Storekeeper"),
      Place.find_by_tag("Moscow")).length,
      "Wrong waybills count"
    assert_equal 0, Waybill.by_storekeeper(
      Entity.find_by_tag("Storekeeper 2"),
      Place.find_by_tag("Minsk")).length,
      "Wrong waybills count"

    wb = Waybill.new(:document_id => "12345",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => "Organization",
      :created => DateTime.civil(2011, 4, 4, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    assert wb.save, "Waybill not saved"

    assert_equal 1, Waybill.by_storekeeper.length,
      "Wrong waybills count"
    assert_equal 1, Waybill.by_storekeeper(
      Entity.find_by_tag("Storekeeper"),
      Place.find_by_tag("Moscow")).length,
      "Wrong waybills count"
    assert_equal 0, Waybill.by_storekeeper(
      Entity.find_by_tag("Storekeeper 2"),
      Place.find_by_tag("Minsk")).length,
      "Wrong waybills count"

    wb = Waybill.new(:document_id => "123456",
                     :owner => Entity.find_by_tag("Storekeeper 2"),
      :place => Place.find_by_tag("Minsk"),
      :from => "Organization",
      :created => DateTime.civil(2011, 4, 4, 12, 0, 0))
    wb.add_resource "roof", "m2", 300
    assert wb.save, "Waybill not saved"

    assert_equal 2, Waybill.by_storekeeper.length,
      "Wrong waybills count"
    assert_equal 1, Waybill.by_storekeeper(
      Entity.find_by_tag("Storekeeper"),
      Place.find_by_tag("Moscow")).length,
      "Wrong waybills count"
    assert_equal 1, Waybill.by_storekeeper(
      Entity.find_by_tag("Storekeeper 2"),
      Place.find_by_tag("Minsk")).length,
      "Wrong waybills count"
  end

  test "create waybill with two identical resources" do
    assert Entity.new(:tag => "Storekeeper").save, "Entity not saved"
    assert Place.new(:tag => "Moscow").save, "Entity not saved"

    wb = Waybill.new(:document_id => "12345",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => "Organization",
      :created => DateTime.civil(2011, 4, 4, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    wb.add_resource "roof", "m2", 500
    assert wb.invalid?, "Waybill is valid"
  end

  test "check has in the warehouse" do
    assert Entity.new(:tag => "Storekeeper").save, "Entity not saved"
    assert Place.new(:tag => "Moscow").save, "Entity not saved"

    wb0 = Waybill.new(:document_id => "123345",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => "Organization",
      :created => DateTime.civil(2011, 4, 3, 12, 0, 0))
    wb0.add_resource "roof", "m2", 500
    assert wb0.save, "Waybill is not saved"

    wb = Waybill.new(:document_id => "12345",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => "Organization",
      :created => DateTime.civil(2011, 4, 4, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    assert wb.save, "Waybill is not saved"

    wb1 = Waybill.new(:document_id => "123456",
                     :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :from => "Organization 2",
      :created => DateTime.civil(2011, 4, 5, 12, 0, 0))
    wb1.add_resource "shovel", "th", 50
    assert wb1.save, "Waybill is not saved"

    waybills = Waybill.with_warehouse_state :sidx => "created", :sord => "ASC"
    assert_equal 3, waybills.length, "Wrong waybills length"
    assert_equal wb0.id, waybills[0].waybill.id, "Wrong waybill id"
    assert waybills[0].has_in_the_warehouse, "Wrong waybill not in the warehouse"
    assert_equal wb.id, waybills[1].waybill.id, "Wrong waybill id"
    assert waybills[1].has_in_the_warehouse, "Wrong waybill not in the warehouse"
    assert_equal wb1.id, waybills[2].waybill.id, "Wrong waybill id"
    assert waybills[2].has_in_the_warehouse, "Wrong waybill not in the warehouse"

    sr = StorehouseRelease.new(:created => DateTime.civil(2011, 4, 6, 12, 0, 0),
      :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :to => "Test entity to")
    sr.add_resource Product.find_by_resource_tag("roof"), 130
    assert sr.save, "StorehouseRelease is not saved"

    sr1 = StorehouseRelease.new(:created => DateTime.civil(2011, 4, 7, 12, 0, 0),
      :owner => Entity.find_by_tag("Storekeeper"),
      :place => Place.find_by_tag("Moscow"),
      :to => "Test entity to")
    sr1.add_resource Product.find_by_resource_tag("roof"), 370
    assert sr1.save, "StorehouseRelease is not saved"

    waybills = Waybill.with_warehouse_state :sidx => "created", :sord => "ASC"
    assert_equal 3, waybills.length, "Wrong waybills length"
    assert_equal wb0.id, waybills[0].waybill.id, "Wrong waybill id"
    assert !waybills[0].has_in_the_warehouse, "Wrong waybill in the warehouse"
    assert_equal wb.id, waybills[1].waybill.id, "Wrong waybill id"
    assert waybills[1].has_in_the_warehouse, "Wrong waybill not in the warehouse"
    assert_equal wb1.id, waybills[2].waybill.id, "Wrong waybill id"
    assert waybills[2].has_in_the_warehouse, "Wrong waybill not in the warehouse"

    assert wb0.disable("haha"), "Cann't disable waybill'"
    waybills = Waybill.with_warehouse_state :sidx => "created", :sord => "ASC"
    assert_equal 2, waybills.length, "Wrong waybills length"
    assert_equal wb.id, waybills[0].waybill.id, "Wrong waybill id"
    assert !waybills[0].has_in_the_warehouse, "Wrong waybill not in the warehouse"
    assert_equal wb1.id, waybills[1].waybill.id, "Wrong waybill id"
    assert waybills[1].has_in_the_warehouse, "Wrong waybill not in the warehouse"

    assert sr.apply, "Release is not applied"
    waybills = Waybill.with_warehouse_state :sidx => "created", :sord => "ASC"
    assert_equal 2, waybills.length, "Wrong waybills length"
    assert_equal wb.id, waybills[0].waybill.id, "Wrong waybill id"
    assert !waybills[0].has_in_the_warehouse, "Wrong waybill not in the warehouse"
    assert_equal wb1.id, waybills[1].waybill.id, "Wrong waybill id"
    assert waybills[1].has_in_the_warehouse, "Wrong waybill not in the warehouse"

    assert sr1.cancel, "Release is not applied"
    waybills = Waybill.with_warehouse_state :sidx => "created", :sord => "ASC"
    assert_equal 2, waybills.length, "Wrong waybills length"
    assert_equal wb.id, waybills[0].waybill.id, "Wrong waybill id"
    assert waybills[0].has_in_the_warehouse, "Wrong waybill not in the warehouse"
    assert_equal wb1.id, waybills[1].waybill.id, "Wrong waybill id"
    assert waybills[1].has_in_the_warehouse, "Wrong waybill not in the warehouse"
  end

  test "destroy wrong waybill" do
    storekeeper = Entity.new(:tag => "Storekeeper")
    assert storekeeper.save, "Entity not saved"
    warehouse = Place.new(:tag => "Moscow")
    assert warehouse.save, "Place not saved"

    wb = Waybill.new(:document_id => "12345",
      :owner => storekeeper,
      :place => warehouse,
      :from => "Organization",
      :created => DateTime.civil(2011, 4, 4, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    assert wb.save, "Waybill is not saved"

    wb = Waybill.new(:document_id => "12345",
      :owner => storekeeper,
      :place => warehouse,
      :from => "Organization",
      :created => DateTime.civil(2011, 4, 4, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    assert wb.save, "Waybill is not saved"

    wb1 = Waybill.new(:document_id => "12345",
      :owner => storekeeper,
      :place => warehouse,
      :from => "Organization",
      :created => DateTime.civil(2011, 4, 4, 12, 0, 0))
    wb1.add_resource "roof", "m2", 500
    assert wb1.save, "Waybill is not saved"

    assert_equal 1, wb.resources.length, "Wrong resources count"
    deal = wb.resources[0].storehouse_deal storekeeper
    assert_not_nil deal, "Warehouse deal is nil"
    assert !deal.new_record?, "Deal is new"
    st = deal.state
    assert_equal 1500, st.amount, "Wrong deal amount"

    assert wb.disable("dublicate waybill"), "Waybill is not disabled"
    assert !wb.disable("daad"), "Waybill is disabled"
    wbd = Waybill.find(wb.id)
    assert_equal "dublicate waybill", wbd.comment, "Wrong waybill comment"
    assert_not_nil wbd.disable_deal, "Wrong disable deal"

    assert_equal 1, wb.resources.length, "Wrong resources count"
    deal = wb.resources[0].storehouse_deal storekeeper
    assert_not_nil deal, "Warehouse deal is nil"
    assert !deal.new_record?, "Deal is new"
    st = deal.state
    assert_equal 1000, st.amount, "Wrong deal amount"

    assert !wb1.disable(nil), "Waybill is disabled"
    assert !wb1.disable(''), "Waybill is disabled"
  end

  test "check not disabled waybills" do
    storekeeper = Entity.new(:tag => "Storekeeper")
    assert storekeeper.save, "Entity not saved"
    warehouse = Place.new(:tag => "Moscow")
    assert warehouse.save, "Place not saved"

    wb = Waybill.new(:document_id => "12345",
      :owner => storekeeper,
      :place => warehouse,
      :from => "Organization",
      :created => DateTime.civil(2011, 4, 4, 12, 0, 0))
    wb.add_resource "roof", "m2", 500
    assert wb.save, "Waybill is not saved"

    wb1 = Waybill.new(:document_id => "12345",
      :owner => storekeeper,
      :place => warehouse,
      :from => "Organization",
      :created => DateTime.civil(2011, 4, 4, 12, 0, 0))
    wb1.add_resource "roof", "m2", 500
    assert wb1.save, "Waybill is not saved"

    wb2 = Waybill.new(:document_id => "12345",
      :owner => storekeeper,
      :place => warehouse,
      :from => "Organization",
      :created => DateTime.civil(2011, 4, 4, 12, 0, 0))
    wb2.add_resource "roof", "m2", 500
    assert wb2.save, "Waybill is not saved"

    assert wb.disable("dublicate waybill"), "Waybill is not disabled"

    assert_equal 1, Waybill.disabled.count, "Wrong disabled count"
    assert_equal wb.id, Waybill.disabled.first.id, "Wrong disabled id"
    assert_equal 2, Waybill.not_disabled.count, "Wrong not disabled count"
    Waybill.not_disabled.each do |item|
      assert false, "Wrong item id" if item.id != wb1.id and item.id != wb2.id
    end
  end

  test "get waybills for storehouse" do
    p = Place.new(:tag => "Storehouse")
    assert p.save, "Place not saved"
    wb1 = Waybill.new(:owner => entities(:sergey),
      :document_id => "12345",
      :place => p,
      :from => "Storehouse organization",
      :created => DateTime.civil(2011, 4, 4, 12, 0, 0))
    wb1.add_resource "roof", "m2", 200
    assert wb1.save, "Waybill is not saved"

    wb2 = Waybill.new(:owner => entities(:sergey),
      :document_id => "123456",
      :place => p,
      :from => "Storehouse organization",
      :created => DateTime.civil(2011, 4, 5, 12, 0, 0))
    wb2.add_resource "roof", "m2", 200
    wb2.add_resource "shovel", "th", 100
    assert wb2.save, "Waybill is not saved"

    wb3 = Waybill.new(:owner => entities(:sergey),
      :document_id => "1234567",
      :place => p,
      :from => "Storehouse organization",
      :created => DateTime.civil(2011, 4, 6, 12, 0, 0))
    wb3.add_resource "shovel", "th", 50
    assert wb3.save, "Waybill is not saved"

    sh = Storehouse.all(:entity => entities(:sergey), :place => p)
    assert_equal 2, sh.length, "Wrong storehouse length"
    sh_waybills = Waybill.in_warehouse
    assert_equal 3, sh_waybills.length, "Wrong waybills count"
    sh_waybills.each do |item|
      assert item.instance_of?(Waybill), "Unknown instance"
      assert !item.warehouse_resources.nil?, "Wrong resources"
      if item.id == wb1.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 200, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb2.id
        assert_equal 2, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 200, sw.amount, "Wrong resource amount"
          elsif sw.product.resource.tag == "shovel"
            assert_equal 100, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb3.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "shovel"
            assert_equal 50, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      else
        assert false, "Unknown waybill"
      end
    end

    sr = StorehouseRelease.new(:created => DateTime.civil(2011, 4, 4, 12, 0, 0),
      :owner => entities(:sergey),
      :place => p,
      :to => "Taskmaster")
    sr.add_resource Product.find_by_resource_tag("roof"), 100
    assert sr.save, "StorehouseRelease not saved"

    sh = Storehouse.all(:entity => entities(:sergey), :place => p)
    assert_equal 2, sh.length, "Wrong storehouse length"
    sh_waybills = Waybill.in_warehouse
    assert_equal 3, sh_waybills.length, "Wrong waybills count"
    sh_waybills.each do |item|
      assert item.instance_of?(Waybill), "Unknown instance"
      assert !item.warehouse_resources.nil?, "Wrong resources"
      if item.id == wb1.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 100, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb2.id
        assert_equal 2, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 200, sw.amount, "Wrong resource amount"
          elsif sw.product.resource.tag == "shovel"
            assert_equal 100, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb3.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "shovel"
            assert_equal 50, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      else
        assert false, "Unknown waybill"
      end
    end

    assert sr.apply, "Release is not applied"

    sh = Storehouse.all(:entity => entities(:sergey), :place => p)
    assert_equal 2, sh.length, "Wrong storehouse length"
    sh_waybills = Waybill.in_warehouse
    assert_equal 3, sh_waybills.length, "Wrong waybills count"
    sh_waybills.each do |item|
      assert item.instance_of?(Waybill), "Unknown instance"
      assert !item.warehouse_resources.nil?, "Wrong resources"
      if item.id == wb1.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 100, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb2.id
        assert_equal 2, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 200, sw.amount, "Wrong resource amount"
          elsif sw.product.resource.tag == "shovel"
            assert_equal 100, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb3.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "shovel"
            assert_equal 50, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      else
        assert false, "Unknown waybill"
      end
    end

    sr = StorehouseRelease.new(:created => DateTime.civil(2011, 4, 5, 12, 0, 0),
      :owner => entities(:sergey),
      :place => p,
      :to => "Taskmaster")
    sr.add_resource Product.find_by_resource_tag("roof"), 102
    assert sr.save, "StorehouseRelease not saved"

    sh = Storehouse.all(:entity => entities(:sergey), :place => p)
    assert_equal 2, sh.length, "Wrong storehouse length"
    sh_waybills = Waybill.in_warehouse
    assert_equal 2, sh_waybills.length, "Wrong waybills count"
    sh_waybills.each do |item|
      assert item.instance_of?(Waybill), "Unknown instance"
      assert !item.warehouse_resources.nil?, "Wrong resources"
      if item.id == wb2.id
        assert_equal 2, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 198, sw.amount, "Wrong resource amount"
          elsif sw.product.resource.tag == "shovel"
            assert_equal 100, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb3.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "shovel"
            assert_equal 50, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      else
        assert false, "Unknown waybill"
      end
    end

    assert sr.cancel, "Release is not canceled"

    sh = Storehouse.all(:entity => entities(:sergey), :place => p)
    assert_equal 2, sh.length, "Wrong storehouse length"
    sh_waybills = Waybill.in_warehouse
    assert_equal 3, sh_waybills.length, "Wrong waybills count"
    sh_waybills.each do |item|
      assert item.instance_of?(Waybill), "Unknown instance"
      assert !item.warehouse_resources.nil?, "Wrong resources"
      if item.id == wb1.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 100, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb2.id
        assert_equal 2, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 200, sw.amount, "Wrong resource amount"
          elsif sw.product.resource.tag == "shovel"
            assert_equal 100, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb3.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "shovel"
            assert_equal 50, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      else
        assert false, "Unknown waybill"
      end
    end

    sr = StorehouseRelease.new(:created => DateTime.civil(2011, 4, 8, 12, 0, 0),
      :owner => entities(:sergey),
      :place => p,
      :to => "Taskmaster")
    sr.add_resource Product.find_by_resource_tag("roof"), 102
    assert sr.save, "StorehouseRelease not saved"

    sr = StorehouseRelease.new(:created => DateTime.civil(2011, 4, 9, 12, 0, 0),
      :owner => entities(:sergey),
      :place => p,
      :to => "Taskmaster")
    sr.add_resource Product.find_by_resource_tag("shovel"), 102
    assert sr.save, "StorehouseRelease not saved"

    sh = Storehouse.all(:entity => entities(:sergey), :place => p)
    assert_equal 2, sh.length, "Wrong storehouse length"
    sh_waybills = Waybill.in_warehouse
    assert_equal 2, sh_waybills.length, "Wrong waybills count"
    sh_waybills.each do |item|
      assert item.instance_of?(Waybill), "Unknown instance"
      assert !item.warehouse_resources.nil?, "Wrong resources"
      if item.id == wb2.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 198, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb3.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "shovel"
            assert_equal 48, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      else
        assert false, "Unknown waybill"
      end
    end

    e = Entity.new(:tag => "Storekeeper 2")
    assert e.save, "Entity is not saved"
    p1 = Place.new :tag => "Storehouse 2"
    assert p1.save, "Place is not saved"

    wb4 = Waybill.new(:owner => e,
      :document_id => "123456789",
      :place => p1,
      :from => "Storehouse organization",
      :created => DateTime.civil(2011, 4, 8, 12, 0, 0))
    wb4.add_resource "roof", "m2", 130
    assert wb4.save, "Waybill is not saved"

    sh = Storehouse.all :entity => entities(:sergey), :place => p
    assert_equal 2, sh.length, "Wrong storehouse length"
    sh_waybills = Waybill.in_warehouse :entity => entities(:sergey), :place => p
    assert_equal 2, sh_waybills.length, "Wrong waybills count"
    sh_waybills.each do |item|
      assert item.instance_of?(Waybill), "Unknown instance"
      assert !item.warehouse_resources.nil?, "Wrong resources"
      if item.id == wb2.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 198, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb3.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "shovel"
            assert_equal 48, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      else
        assert false, "Unknown waybill"
      end
    end

    sh = Storehouse.all :entity => e, :place => p1
    assert_equal 1, sh.length, "Wrong storehouse length"
    sh_waybills = Waybill.in_warehouse :entity => e, :place => p1
    assert_equal 1, sh_waybills.length, "Wrong waybills count"
    sh_waybills.each do |item|
      assert item.instance_of?(Waybill), "Unknown instance"
      assert !item.warehouse_resources.nil?, "Wrong resources"
      if item.id == wb4.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 130, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      else
        assert false, "Unknown waybill"
      end
    end

    sh_waybills = Waybill.in_warehouse
    assert_equal 3, sh_waybills.length, "Wrong waybills count"
    sh_waybills.each do |item|
      assert item.instance_of?(Waybill), "Unknown instance"
      assert !item.warehouse_resources.nil?, "Wrong resources"
      if item.id == wb2.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 198, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb3.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "shovel"
            assert_equal 48, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb4.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 130, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      else
        assert false, "Unknown waybill"
      end
    end

    sr = StorehouseRelease.new(:created => DateTime.civil(2011, 4, 9, 12, 0, 0),
      :owner => e,
      :place => p1,
      :to => "Taskmaster")
    sr.add_resource Product.find_by_resource_tag("roof"), 102
    assert sr.save, "StorehouseRelease not saved"

    sh_waybills = Waybill.in_warehouse
    assert_equal 3, sh_waybills.length, "Wrong waybills count"
    sh_waybills.each do |item|
      assert item.instance_of?(Waybill), "Unknown instance"
      assert !item.warehouse_resources.nil?, "Wrong resources"
      if item.id == wb2.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 198, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb3.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "shovel"
            assert_equal 48, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb4.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "roof"
            assert_equal 28, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      else
        assert false, "Unknown waybill"
      end
    end
  end

  test "group storehouses entry by resource and check waybills" do
    storekeeper = Entity.new(:tag => "Storekeeper")
    assert storekeeper.save, "Entity not saved"
    warehouse = Place.new(:tag => "Some warehouse")
    assert warehouse.save, "Entity not saved"

    wb1 = Waybill.new(:owner => storekeeper,
      :document_id => "12834",
      :place => warehouse,
      :from => "Organization Store",
      :created => DateTime.civil(2011, 4, 2, 12, 0, 0))
    wb1.add_resource assets(:sonyvaio).tag, "th", 100
    assert wb1.save, "Waybill is not saved"

    wb2 = Waybill.new(:owner => storekeeper,
      :document_id => "12345",
      :place => warehouse,
      :from => "Organization Store 2",
      :created => DateTime.civil(2011, 4, 2, 12, 0, 0))
    wb2.add_resource "sony VAI O", "th", 150
    assert wb2.save, "Waybill is not saved"

    a = asset_reals(:notebooksv)
    a.assets << Asset.find_by_tag("sony VAI O")
    a.assets << assets(:sonyvaio)

    wb3 = Waybill.new(:owner => storekeeper,
      :document_id => "123456",
      :place => warehouse,
      :from => "Organization Store 3",
      :created => DateTime.civil(2011, 4, 5, 12, 0, 0))
    wb3.add_resource "sony 3D", "th", 50
    assert wb3.save, "Waybill is not saved"

    sh = Storehouse.all :entity => storekeeper, :place => warehouse
    assert_equal 2, sh.length, "Wrong entries count"
    wbs = Waybill.in_warehouse :entity => storekeeper, :place => warehouse
    assert_equal 3, wbs.length, "Wrong waybills count"
    wbs.each do |item|
      assert item.instance_of?(Waybill), "Unknown instance"
      assert !item.warehouse_resources.nil?, "Wrong resources"
      if item.id == wb1.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.real_tag == asset_reals(:notebooksv).tag
            assert_equal 100, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb2.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.real_tag == asset_reals(:notebooksv).tag
            assert_equal 150, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb3.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "sony 3D"
            assert_equal 50, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      else
        assert false, "Unknown waybill"
      end
    end

    sr = StorehouseRelease.new(:created => DateTime.civil(2011, 4, 9, 12, 0, 0),
      :owner => storekeeper,
      :place => warehouse,
      :to => "Taskmaster")
    sr.add_resource Product.find_by_resource_tag("sony VAI O"), 102
    assert sr.save, "StorehouseRelease not saved"

    wbs = Waybill.in_warehouse :entity => storekeeper, :place => warehouse
    assert_equal 2, wbs.length, "Wrong waybills count"
    wbs.each do |item|
      assert item.instance_of?(Waybill), "Unknown instance"
      assert !item.warehouse_resources.nil?, "Wrong resources"
      if item.id == wb2.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.real_tag == asset_reals(:notebooksv).tag
            assert_equal 148, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      elsif item.id == wb3.id
        assert_equal 1, item.warehouse_resources.length, "Wrong resources count"
        item.warehouse_resources.each do |sw|
          if sw.product.resource.tag == "sony 3D"
            assert_equal 50, sw.amount, "Wrong resource amount"
          else
            assert false, "Wrong resource"
          end
        end
      else
        assert false, "Unknown waybill"
      end
    end
  end
end
