# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Waybill do
  before(:all) do
    create(:chart)
  end

  it 'should have next behaviour' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb.save
    should validate_presence_of :document_id
    should validate_presence_of :distributor
    should validate_presence_of :distributor_place
    should validate_presence_of :created
    should validate_presence_of :storekeeper
    should validate_presence_of :storekeeper_place
    should validate_uniqueness_of :document_id
    should have_many(Waybill.versions_association_name)
    should have_many :comments
  end

  it 'should create items' do
    wb = build(:waybill)
    wb.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    lambda { wb.save } .should change(Asset, :count).by(2)
    Asset.all
    wb.items.count.should eq(2)
    wb.items[0].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'pcs').first)
    wb.items[0].amount.should eq(1200)
    wb.items[0].price.should eq(1.0)
    wb.items[1].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'kg').first)
    wb.items[1].amount.should eq(10)
    wb.items[1].price.should eq(150.0)

    asset = create(:asset)
    wb.add_item(tag: asset.tag, mu: asset.mu, amount: 100, price: 12.0)
    lambda { wb.save } .should_not change(Asset, :count)
    wb.items.count.should eq(3)
    wb.items[2].resource.should eq(asset)
    wb.items[2].amount.should eq(100)
    wb.items[2].price.should eq(12.0)

    wb = Waybill.find(wb)
    wb.items.count.should eq(2)
    wb.items[0].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'pcs').first)
    wb.items[0].amount.should eq(1200)
    wb.items[0].price.should eq(1.0)
    wb.items[1].resource.should eq(Asset.find_all_by_tag_and_mu('nails', 'kg').first)
    wb.items[1].amount.should eq(10)
    wb.items[1].price.should eq(150.0)
  end

  it 'should create deals' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    lambda { wb.save } .should change(Deal, :count).by(3)

    deal = Deal.find(wb.deal)
    deal.tag.should eq(I18n.t('activerecord.attributes.waybill.deal.tag',
                              id: wb.document_id))
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    roof_deal_tag = I18n.t("activerecord.attributes.waybill.deal.resource.tag",
                  id: wb.document_id,
                  index: 1)
    deal = wb.items.first.warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor)
    deal.should_not be_nil
    deal.tag.should eq(roof_deal_tag)
    deal.rate.should eq(1 / wb.items.first.price)
    deal.isOffBalance.should be_false

    deal = wb.items.first.warehouse_deal(nil, wb.storekeeper_place, wb.storekeeper)
    deal.tag.should eq(roof_deal_tag)
    deal.should_not be_nil
    deal.rate.should eq(1.0)
    deal.isOffBalance.should be_false

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 500, price: 100.0)
    lambda { wb.save } .should change(Deal, :count).by(3)

    deal = Deal.find(wb.deal)
    deal.tag.should eq(I18n.t('activerecord.attributes.waybill.deal.tag',
                              id: wb.document_id))
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb.items.each_with_index do |i, idx|
      deal_tag = I18n.t("activerecord.attributes.waybill.deal.resource.tag",
                        id: wb.document_id,
                        index: idx + 1)
      deal = i.warehouse_deal(Chart.first.currency, wb.distributor_place, wb.distributor)
      deal.tag.should eq(wb.items[idx].resource.tag == 'roof' ? roof_deal_tag : deal_tag)
      deal.should_not be_nil
      deal.rate.should eq(1 / i.price)
      deal.isOffBalance.should be_false

      deal = i.warehouse_deal(nil, wb.storekeeper_place, wb.storekeeper)
      deal.tag.should eq(wb.items[idx].resource.tag == 'roof' ? roof_deal_tag : deal_tag)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    end

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 50, price: 100.0)
    lambda { wb.save } .should change(Deal, :count).by(1)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb = build(:waybill, storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 200, price: 100.0)
    lambda { wb.save } .should change(Deal, :count).by(2)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    deal = wb.items.first.warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor)
    deal.should_not be_nil
    deal.rate.should eq(1 / wb.items.first.price)
    deal.isOffBalance.should be_false

    deal = wb.items.first.warehouse_deal(nil, wb.storekeeper_place, wb.storekeeper)
    deal.should_not be_nil
    deal.rate.should eq(1.0)
    deal.isOffBalance.should be_false

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 70, price: 12.0)
    lambda { wb.save } .should change(Deal, :count).by(3)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb.items.each do |i|
      deal = i.warehouse_deal(Chart.first.currency, wb.distributor_place, wb.distributor)
      deal.should_not be_nil
      deal.rate.should eq(1 / i.price)
      deal.isOffBalance.should be_false

      deal = i.warehouse_deal(nil, wb.storekeeper_place, wb.storekeeper)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    end

    wb = build(:waybill, distributor: wb.distributor,
                         distributor_place: wb.distributor_place,
                         storekeeper: wb.storekeeper)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    lambda { wb.save } .should change(Deal, :count).by(2)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb.items.each do |i|
      deal = i.warehouse_deal(Chart.first.currency, wb.distributor_place, wb.distributor)
      deal.should_not be_nil
      deal.rate.should eq(1 / i.price)
      deal.isOffBalance.should be_false

      deal = i.warehouse_deal(nil, wb.storekeeper_place, wb.storekeeper)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    end

    wb = build(:waybill)
    wb.add_item(tag: 'roofer', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'roofer', mu: 'm2', amount: 120.34, price: 10.0)
    wb.add_item(tag: 'roofer', mu: 'm2', amount: 128.4, price: 10.0)
    lambda { wb.save } .should change(Deal, :count).by(3)

    deal = Deal.find(wb.deal)
    deal.entity.should eq(wb.storekeeper)
    deal.isOffBalance.should be_true

    wb.items.each do |i|
      deal = i.warehouse_deal(Chart.first.currency, wb.distributor_place, wb.distributor)
      deal.should_not be_nil
      deal.rate.should eq(1 / i.price)
      deal.isOffBalance.should be_false

      deal = i.warehouse_deal(nil, wb.storekeeper_place, wb.storekeeper)
      deal.should_not be_nil
      deal.rate.should eq(1.0)
      deal.isOffBalance.should be_false
    end
  end

  it 'should create rules' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    lambda { wb.save } .should change(Rule, :count).by(1)

    rule = wb.deal.rules.first
    rule.rate.should eq(500)
    wb.items.first.warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).should eq(rule.from)
    wb.items.first.warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).should eq(rule.to)

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 500, price: 100.0)
    lambda { wb.save } .should change(Rule, :count).by(2)

    rule = wb.deal.rules[0]
    rule.rate.should eq(100)
    wb.items[0].warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).should eq(rule.from)
    wb.items[0].warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).should eq(rule.to)

    rule = wb.deal.rules[1]
    rule.rate.should eq(500)
    wb.items[1].warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).should eq(rule.from)
    wb.items[1].warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).should eq(rule.to)

    wb = build(:waybill)
    wb.add_item(tag: 'roofer', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'roofer', mu: 'm2', amount: 120.34, price: 10.0)
    wb.add_item(tag: 'roofer', mu: 'm2', amount: 128.4, price: 10.0)
    lambda { wb.save } .should change(Rule, :count).by(3)

    wb.deal.rules.each_with_index do |rule, idx|
      rule.rate.should eq(wb.items[idx].amount)
      wb.items[idx].warehouse_deal(Chart.first.currency, wb.distributor_place,
                                   wb.distributor).should eq(rule.from)
      wb.items[idx].warehouse_deal(nil, wb.storekeeper_place,
                                   wb.storekeeper).should eq(rule.to)
    end
  end

  it 'should change state' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.state.should eq(Waybill::UNKNOWN)

    wb.cancel.should be_false

    wb.save!
    wb.state.should eq(Waybill::INWORK)

    wb = Waybill.find(wb)
    wb.cancel.should be_true
    wb.state.should eq(Waybill::CANCELED)

    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.save!
    wb.apply.should be_true
    wb.state.should eq(Waybill::APPLIED)
  end

  it 'should create fact after apply' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.save.should be_true
    wb.apply.should be_true

    state = wb.items.first.warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).state
    state.side.should eq("passive")
    state.amount.should eq(500 * 10.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.items.first.warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).state
    state.side.should eq("active")
    state.amount.should eq(500.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 500, price: 100.0)
    wb.save.should be_true
    wb.apply.should be_true

    state = wb.items[0].warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).state
    state.side.should eq("passive")
    state.amount.should eq(5000 + 100 * 10.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.items[0].warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).state
    state.side.should eq("active")
    state.amount.should eq(500 + 100)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.items[1].warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).state
    state.side.should eq("passive")
    state.amount.should eq(500 * 100)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.items[1].warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).state
    state.side.should eq("active")
    state.amount.should eq(500.0)
    state.start.should eq(DateTime.current.change(hour: 12))
  end

  it 'should create txn after apply' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.save.should be_true
    wb.apply.should be_true

    balance = wb.items.first.warehouse_deal(Chart.first.currency,
                                          wb.distributor_place, wb.distributor).balance
    balance.side.should eq("passive")
    balance.amount.should eq(500 * 10.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.items.first.warehouse_deal(nil, wb.storekeeper_place,
                                          wb.storekeeper).balance
    balance.side.should eq("active")
    balance.amount.should eq(500.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    wb = build(:waybill, distributor: wb.distributor,
                       distributor_place: wb.distributor_place,
                       storekeeper: wb.storekeeper,
                       storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 500, price: 100.0)
    wb.save.should be_true
    wb.apply.should be_true

    balance = wb.items[0].warehouse_deal(Chart.first.currency,
                                       wb.distributor_place, wb.distributor).balance
    balance.side.should eq("passive")
    balance.amount.should eq(5000 + 100 * 10.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.items[0].warehouse_deal(nil, wb.storekeeper_place,
                                       wb.storekeeper).balance
    balance.side.should eq("active")
    balance.amount.should eq((500 + 100))
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.items[1].warehouse_deal(Chart.first.currency,
                                       wb.distributor_place, wb.distributor).balance
    balance.side.should eq("passive")
    balance.amount.should eq(500 * 100)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.items[1].warehouse_deal(nil, wb.storekeeper_place,
                                       wb.storekeeper).balance
    balance.side.should eq("active")
    balance.amount.should eq(500)
    balance.start.should eq(DateTime.current.change(hour: 12))
  end

  it 'should create fact after disable' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.save.should be_true
    wb.apply.should be_true

    state = wb.items.first.warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).state
    state.side.should eq("passive")
    state.amount.should eq(500 * 10.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.items.first.warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).state
    state.side.should eq("active")
    state.amount.should eq(500.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    wb_old = wb
    wb = build(:waybill, distributor: wb.distributor,
                                 distributor_place: wb.distributor_place,
                                 storekeeper: wb.storekeeper,
                                 storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 500, price: 100.0)
    wb.save.should be_true
    wb.apply.should be_true

    state = wb.items[0].warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).state
    state.side.should eq("passive")
    state.amount.should eq(5000 + 100 * 10.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.items[0].warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).state
    state.side.should eq("active")
    state.amount.should eq(500 + 100)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.items[1].warehouse_deal(Chart.first.currency,
      wb.distributor_place, wb.distributor).state
    state.side.should eq("passive")
    state.amount.should eq(500 * 100)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb.items[1].warehouse_deal(nil, wb.storekeeper_place,
      wb.storekeeper).state
    state.side.should eq("active")
    state.amount.should eq(500.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    wb.cancel.should be_true
    wb.state.should eq(Statable::REVERSED)

    state = wb_old.items.first.warehouse_deal(Chart.first.currency,
                                              wb_old.distributor_place,
                                              wb_old.distributor).state
    state.side.should eq("passive")
    state.amount.should eq(500 * 10.0)
    state.start.should eq(DateTime.current.change(hour: 12))

    state = wb_old.items.first.warehouse_deal(nil, wb_old.storekeeper_place,
                                              wb_old.storekeeper).state
    state.side.should eq("active")
    state.amount.should eq(500.0)
    state.start.should eq(DateTime.current.change(hour: 12))
  end

  it 'should create txn after disable' do
    wb = build(:waybill)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 500, price: 10.0)
    wb.save.should be_true
    wb.apply.should be_true

    balance = wb.items.first.warehouse_deal(Chart.first.currency,
                                          wb.distributor_place, wb.distributor).balance
    balance.side.should eq("passive")
    balance.amount.should eq(500 * 10.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.items.first.warehouse_deal(nil, wb.storekeeper_place,
                                          wb.storekeeper).balance
    balance.side.should eq("active")
    balance.amount.should eq(500.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    wb_old = wb
    wb = build(:waybill, distributor: wb.distributor,
                       distributor_place: wb.distributor_place,
                       storekeeper: wb.storekeeper,
                       storekeeper_place: wb.storekeeper_place)
    wb.add_item(tag: 'roof', mu: 'm2', amount: 100, price: 10.0)
    wb.add_item(tag: 'hammer', mu: 'th', amount: 500, price: 100.0)
    wb.save.should be_true
    wb.apply.should be_true

    balance = wb.items[0].warehouse_deal(Chart.first.currency,
                                       wb.distributor_place, wb.distributor).balance
    balance.side.should eq("passive")
    balance.amount.should eq(5000 + 100 * 10.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.items[0].warehouse_deal(nil, wb.storekeeper_place,
                                       wb.storekeeper).balance
    balance.side.should eq("active")
    balance.amount.should eq((500 + 100))
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.items[1].warehouse_deal(Chart.first.currency,
                                       wb.distributor_place, wb.distributor).balance
    balance.side.should eq("passive")
    balance.amount.should eq(500 * 100)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb.items[1].warehouse_deal(nil, wb.storekeeper_place,
                                       wb.storekeeper).balance
    balance.side.should eq("active")
    balance.amount.should eq(500)
    balance.start.should eq(DateTime.current.change(hour: 12))

    wb.cancel.should be_true
    wb.state.should eq(Statable::REVERSED)

    balance = wb_old.items.first.warehouse_deal(Chart.first.currency,
                                                wb_old.distributor_place,
                                                wb_old.distributor).balance
    balance.side.should eq("passive")
    balance.amount.should eq(500 * 10.0)
    balance.start.should eq(DateTime.current.change(hour: 12))

    balance = wb_old.items.first.warehouse_deal(nil, wb_old.storekeeper_place,
                                                wb_old.storekeeper).balance
    balance.side.should eq("active")
    balance.amount.should eq(500.0)
    balance.start.should eq(DateTime.current.change(hour: 12))
  end

  it 'should show in warehouse' do
    moscow = create(:place, tag: 'Moscow')
    minsk = create(:place, tag: 'Minsk')
    ivanov = create(:entity, tag: 'Ivanov')
    petrov = create(:entity, tag: 'Petrov')

    wb1 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb1.add_item(tag: 'nails', mu: 'pcs', amount: 700, price: 1.0)
    wb1.save!
    wb1.apply.should be_true
    wb2 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb2.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb2.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    wb2.add_item(tag: 'roof', mu: 'rm', amount: 50, price: 100.0)
    wb2.save!
    wb2.apply.should be_true
    wb3 = build(:waybill, storekeeper: petrov,
                                  storekeeper_place: minsk)
    wb3.add_item(tag: 'roof', mu: 'rm', amount: 500, price: 120.0)
    wb3.add_item(tag: 'nails', mu: 'kg', amount: 300, price: 150.0)
    wb3.save!
    wb3.apply.should be_true

    Waybill.in_warehouse.include?(wb1).should be_true
    Waybill.in_warehouse.include?(wb2).should be_true
    Waybill.in_warehouse.include?(wb3).should be_true

    ds_moscow = build(:allocation, storekeeper: ivanov,
                                   storekeeper_place: moscow)
    ds_moscow.add_item(tag: 'nails', mu: 'pcs', amount: 10)
    ds_moscow.add_item(tag: 'roof', mu: 'rm', amount: 4)
    ds_moscow.save!
    ds_minsk = build(:allocation, storekeeper: petrov,
                                  storekeeper_place: minsk)
    ds_minsk.add_item(tag: 'roof', mu: 'rm', amount: 400)
    ds_minsk.add_item(tag: 'nails', mu: 'kg', amount: 200)
    ds_minsk.save!

    Waybill.in_warehouse.include?(wb1).should be_true
    Waybill.in_warehouse.include?(wb2).should be_true
    Waybill.in_warehouse.include?(wb3).should be_true

    wbs = Waybill.in_warehouse(without_waybills: [ wb1.id ])
    wbs.include?(wb1).should be_false
    wbs.include?(wb2).should be_true
    wbs.include?(wb3).should be_true

    wbs = Waybill.in_warehouse(without_waybills: [ wb1.id, wb3.id ])
    wbs.include?(wb1).should be_false
    wbs.include?(wb2).should be_true
    wbs.include?(wb3).should be_false

    ds_moscow = build(:allocation, storekeeper: ivanov,
                                   storekeeper_place: moscow)
    ds_moscow.add_item(tag: 'roof', mu: 'rm', amount: 146)
    ds_moscow.add_item(tag: 'nails', mu: 'pcs', amount: 1890)
    ds_moscow.save!

    Waybill.in_warehouse.include?(wb1).should be_false
    Waybill.in_warehouse.include?(wb2).should be_true
    Waybill.in_warehouse.include?(wb3).should be_true

    wbs = Waybill.in_warehouse(where:
                                { storekeeper_id: { equal: petrov.id },
                                  storekeeper_place_id: { equal: minsk.id }})
    wbs.include?(wb1).should be_false
    wbs.include?(wb2).should be_false
    wbs.include?(wb3).should be_true

    ds_minsk = build(:allocation, storekeeper: petrov,
                                  storekeeper_place: minsk)
    ds_minsk.add_item(tag: 'roof', mu: 'rm', amount: 100)
    ds_minsk.add_item(tag: 'nails', mu: 'kg', amount: 100)
    ds_minsk.save!

    wbs = Waybill.in_warehouse(where:
                                { storekeeper_id: { equal: petrov.id },
                                  storekeeper_place_id: { equal: minsk.id }})
    wbs.include?(wb1).should be_false
    wbs.include?(wb2).should be_false
    wbs.include?(wb3).should be_false

    Waybill.in_warehouse.include?(wb1).should be_false
    Waybill.in_warehouse.include?(wb2).should be_true
    Waybill.in_warehouse.include?(wb3).should be_false

    wb4 = build(:waybill, storekeeper: ivanov,
                          storekeeper_place: moscow)
    wb4.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb4.add_item(tag: 'nails', mu: 'pcs', amount: 700, price: 1.0)
    wb4.save!

    Waybill.in_warehouse.include?(wb1).should be_false
    Waybill.in_warehouse.include?(wb2).should be_true
    Waybill.in_warehouse.include?(wb3).should be_false
    Waybill.in_warehouse.include?(wb4).should be_false
  end

  it "should filter by storekeeper" do
    moscow = create(:place)
    minsk = create(:place)
    ivanov = create(:entity)
    petrov = create(:entity)

    wb1 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb1.add_item(tag: 'nails', mu: 'pcs', amount: 700, price: 1.0)
    wb1.save!

    wb2 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb2.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb2.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    wb2.add_item(tag: 'roof', mu: 'rm', amount: 50, price: 100.0)
    wb2.save!

    wb3 = build(:waybill, storekeeper: petrov,
                                  storekeeper_place: minsk)
    wb3.add_item(tag: 'roof', mu: 'rm', amount: 500, price: 120.0)
    wb3.add_item(tag: 'nails', mu: 'kg', amount: 300, price: 150.0)
    wb3.save!

    Waybill.by_storekeeper(ivanov).should =~ [wb1, wb2]
    Waybill.by_storekeeper(petrov).should =~ [wb3]
    Waybill.by_storekeeper(create(:entity)).all.should be_empty
  end

  it "should filter by storekeeper place" do
    moscow = create(:place)
    minsk = create(:place)
    ivanov = create(:entity)
    petrov = create(:entity)

    wb1 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 100, price: 120.0)
    wb1.add_item(tag: 'nails', mu: 'pcs', amount: 700, price: 1.0)
    wb1.save!

    wb2 = build(:waybill, storekeeper: ivanov,
                                  storekeeper_place: moscow)
    wb2.add_item(tag: 'nails', mu: 'pcs', amount: 1200, price: 1.0)
    wb2.add_item(tag: 'nails', mu: 'kg', amount: 10, price: 150.0)
    wb2.add_item(tag: 'roof', mu: 'rm', amount: 50, price: 100.0)
    wb2.save!

    wb3 = build(:waybill, storekeeper: petrov,
                                  storekeeper_place: minsk)
    wb3.add_item(tag: 'roof', mu: 'rm', amount: 500, price: 120.0)
    wb3.add_item(tag: 'nails', mu: 'kg', amount: 300, price: 150.0)
    wb3.save!

    Waybill.by_storekeeper_place(moscow).should =~ [wb1, wb2]
    Waybill.by_storekeeper_place(minsk).should =~ [wb3]
    Waybill.by_storekeeper_place(create(:place)).all.should be_empty
  end

  it 'should sort waybills' do
    moscow = create(:place, tag: 'Moscow1')
    kiev = create(:place, tag: 'Kiev1')
    amsterdam = create(:place, tag: 'Amsterdam1')
    ivanov = create(:entity, tag: 'Ivanov1')
    petrov = create(:entity, tag: 'Petrov1')
    antonov = create(:entity, tag: 'Antonov1')

    wb1 = build(:waybill, created: Date.new(2011,11,11), document_id: 1,
                distributor: petrov, storekeeper: antonov,
                storekeeper_place: moscow)
    wb1.add_item(tag: 'roof', mu: 'rm', amount: 1, price: 120.0)
    wb1.save!
    wb1.apply

    wb2 = build(:waybill, created: Date.new(2011,11,12), document_id: 3,
                distributor: antonov, storekeeper: ivanov,
                storekeeper_place: kiev)
    wb2.add_item(tag: 'roof', mu: 'rm', amount: 1, price: 120.0)
    wb2.save!

    wb3 = build(:waybill, created: Date.new(2011,11,13), document_id: 2,
                distributor: ivanov, storekeeper: petrov,
                storekeeper_place: amsterdam)
    wb3.add_item(tag: 'roof', mu: 'rm', amount: 1, price: 120.0)
    wb3.save!
    wb3.apply

    wbs = Waybill.order_by(field: 'created', type: 'acs').all
    wbs_test = Waybill.order('created').all
    wbs.should eq(wbs_test)
    wbs = Waybill.order_by(field: 'created', type: 'desc').all
    wbs_test = Waybill.order('created DESC').all
    wbs.should eq(wbs_test)

    wbs = Waybill.order_by(field: 'document_id', type: 'acs').all
    wbs_test = Waybill.order('document_id').all
    wbs.should eq(wbs_test)
    wbs = Waybill.order_by(field: 'document_id', type: 'desc').all
    wbs_test = Waybill.order('document_id DESC').all
    wbs.should eq(wbs_test)

    wbs = Waybill.order_by(field: 'distributor', type: 'acs').all
    wbs_test = Waybill.joins{deal.rules.from.entity(LegalEntity)}.
        group('waybills.id').order('legal_entities.name').all
    wbs.should eq(wbs_test)
    wbs = Waybill.order_by(field: 'distributor', type: 'desc').all
    wbs_test = Waybill.joins{deal.rules.from.entity(LegalEntity)}.
        group('waybills.id').order('legal_entities.name DESC').all
    wbs.should eq(wbs_test)

    wbs = Waybill.order_by(field: 'storekeeper', type: 'acs').all
    wbs_test = Waybill.joins{deal.entity(Entity)}.order('entities.tag').all
    wbs.should eq(wbs_test)
    wbs = Waybill.order_by(field: 'storekeeper', type: 'desc').all
    wbs_test = Waybill.joins{deal.entity(Entity)}.order('entities.tag DESC').all
    wbs.should eq(wbs_test)

    wbs = Waybill.order_by(field: 'storekeeper_place', type: 'acs').all
    wbs_test = Waybill.joins{deal.take.place}.order('places.tag').all
    wbs.should eq(wbs_test)
    wbs = Waybill.order_by(field: 'storekeeper_place', type: 'desc').all
    wbs_test = Waybill.joins{deal.take.place}.order('places.tag DESC').all
    wbs.should eq(wbs_test)

    wbs = Waybill.order_by(field: 'state', type: 'acs').all
    wbs_test = Waybill.order('state').all
    wbs.should eq(wbs_test)
    wbs = Waybill.order_by(field: 'state', type: 'desc').all
    wbs_test = Waybill.order('state DESC').all
    wbs.should eq(wbs_test)
  end
end

describe ItemsValidator do
  it 'should not validate' do
    wb = build(:waybill)
    wb.add_item(tag: '', mu: 'm2', amount: 1, price: 10.0)
    wb.should be_invalid
    wb.items.clear
    wb.add_item(tag: 'roof', mu: 'm2', amount: 0, price: 10.0)
    wb.should be_invalid
    wb.items.clear
    wb.add_item(tag: 'roof', mu: 'm2', amount: 1, price: 0)
    wb.should be_invalid
  end
end
