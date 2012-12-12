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
  it "should have columns" do
    Warehouse::Resource.columns.
        collect { |column| column.name.to_sym }.should =~ [:resource_id]
  end

  it { should belong_to :resource }

  it { should delegate_method(:tag).to(:resource) }
  it { should delegate_method(:mu).to(:resource) }

  context "with created waybills" do
    before :all do
      create(:chart)
      @assets = []
      5.times do
        warehouse = Warehouse::Place.new(user_id: create(:user).id,
                                         place_id: create(:place).id)
        warehouse.save
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
    it { Warehouse::Resource.count.should eq(@assets.count) }
    it { Warehouse::Resource.all.count.should eq(@assets.count) }
    it { Warehouse::Resource.all.should =~ @assets.
        collect{ |item| Warehouse::Resource.new(resource_id: item.id) } }
  end
end
