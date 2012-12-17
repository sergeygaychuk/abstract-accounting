# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Warehouse::Resource do
  before :all do
    create(:chart)
  end

  it "should have columns" do
    Warehouse::Resource.columns.
        collect { |column| column.name.to_sym }.should =~ [:resource_id, :deal_id]
  end

  it { should belong_to :resource }
  it { should belong_to :deal }

  it { should delegate_method(:tag).to(:resource) }
  it { should delegate_method(:mu).to(:resource) }

  context "with created waybills" do
    before :all do
      @assets = Warehouse::Place.all.inject([]) do |memo, place|
        Warehouse::Waybill.by_warehouse(place).inject(memo) do |mem, w|
          mem + w.deal.rules.collect { |rule| rule.to.give.resource }
        end.uniq
      end
      5.times do
        warehouse = build(:warehouse)
        warehouse.save.should be_true
        3.times do
          waybill = build(:waybill, storekeeper: warehouse.storekeeper,
                          storekeeper_place: warehouse.place)
          @assets << (asset = create(:asset))
          waybill.add_item(tag: asset.tag, mu: asset.mu, amount: 100.12, price: 23.22)
          @assets << (asset = create(:asset))
          waybill.add_item(tag: asset.tag, mu: asset.mu, amount: 100.12, price: 23.22)
          waybill.save.should be_true
          waybill.apply.should be_true
        end
      end
      10.times { create(:asset) }
    end
    it { Warehouse::Resource.count.size.should eq(@assets.count) }
    it { Warehouse::Resource.all.count.should eq(@assets.count) }
    it { Warehouse::Resource.all.collect { |r| r.resource }.should =~ @assets }

    it "should filtrate by warehouse" do
      warehouse = Warehouse::Place.first
      assets = Warehouse::Waybill.by_warehouse(warehouse).inject([]) do |memo, waybill|
        memo + waybill.items.collect { |item| item.resource }
      end
      Warehouse::Resource.by_warehouse(warehouse).all.
          collect { |r| r.resource }.should =~ assets
    end

    describe "#deal" do
      it "should return deal_id by resources" do
        warehouse = Warehouse::Place.first
        deals = Warehouse::Waybill.by_warehouse(warehouse).inject([]) do |memo, w|
          memo + w.deal.rules.collect { |rule| rule.to }
        end.uniq
        Warehouse::Resource.by_warehouse(warehouse).collect do |resource|
          resource.deal
        end.should =~ deals
      end
    end
  end

  it "should return unique record by deal_id" do
    warehouse = build(:warehouse)
    warehouse.save.should be_true

    asset1 = create(:asset)
    asset2 = create(:asset)
    3.times do
      waybill = build(:waybill, storekeeper: warehouse.storekeeper,
                      storekeeper_place: warehouse.place)
      waybill.add_item(tag: asset1.tag, mu: asset1.mu, amount: 100.12, price: 23.22)
      waybill.add_item(tag: asset2.tag, mu: asset2.mu, amount: 100.12, price: 23.22)
      waybill.save.should be_true
      waybill.apply.should be_true
    end
    resources = Warehouse::Resource.by_warehouse(warehouse)
    resources.count.size.should eq(2)
    resources.collect { |r| r.resource }.should =~ [asset1, asset2]
  end
end
