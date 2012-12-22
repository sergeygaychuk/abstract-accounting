# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "spec_helper"

describe Warehouse::DealItem do
  it "should contains members" do
    Warehouse::DealItem.new.members.should =~ [:tag, :mu, :amount, :price]
  end

  describe "#resource" do
    it "should return nil if mu or tag is not assigned" do
      Warehouse::DealItem.new("TAG").resource.should be_nil
      Warehouse::DealItem.new(nil, "mu").resource.should be_nil
    end

    it "should find resource by tag and mu" do
      asset = create(:asset, tag: "SOME tag", mu: "MU")
      item = Warehouse::DealItem.new(asset.tag, asset.mu)
      item.resource.should_not be_new_record
      item.resource.should eq(asset)
    end

    it "should initialize resource with tag and mu if not found" do
      tag = "New tag"
      mu = "New mu"
      item = Warehouse::DealItem.new(tag, mu)
      item.resource.should be_new_record
      item.resource.tag.should eq(tag)
      item.resource.mu.should eq(mu)
    end

    it "should assign resource and return it" do
      asset = create(:asset)
      item = Warehouse::DealItem.new(asset.tag, asset.mu)
      item.resource = asset
      item.resource.object_id.should eq(asset.object_id)
      item.resource.should eq(asset)
    end

    it "should find resource if it is saved after item was initialized" do
      asset = build(:asset)
      item = Warehouse::DealItem.new(asset.tag, asset.mu)
      item.resource.should be_new_record
      asset.save.should be_true
      item.resource.should_not be_new_record
      item.resource.should eq(asset)
    end
  end

  context "with created resource" do
    let(:resource) { create(:asset) }
    let(:warehouse) do
      warehouse = build(:warehouse)
      warehouse.save
      warehouse
    end

    before :all do
      create(:chart)
      waybill = build(:waybill, warehouse: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: 100.99, price: 1.0)
      waybill.save.should be_true
      waybill.apply.should be_true
    end

    describe "#state_amount" do
      it "should return amount from state" do
        Warehouse::DealItem.new(resource.tag, resource.mu).
          state_amount(warehouse).should eq(100.99)
      end

      it "should return nil if state is not found" do
        allocation = build(:allocation, warehouse: warehouse)
        allocation.add_item(tag: resource.tag, mu: resource.mu, amount: 100.99)
        allocation.save.should be_true
        allocation.apply.should be_true
        Warehouse::DealItem.new(resource.tag, resource.mu).
            state_amount(warehouse).should eq(0.0)
      end

      it "should return 0 if resource is not assigned" do
        Warehouse::DealItem.new.state_amount(warehouse).should eq(0.0)
      end
    end

    describe "#total_price" do
      it "should return amount * price" do
        Warehouse::DealItem.new(resource.tag, resource.mu, 10, 20).
            total_price.should eq(10 * 20)
      end
    end
  end
end
