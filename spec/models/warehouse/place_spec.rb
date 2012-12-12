# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Warehouse::Place do
  it "should have columns" do
    Warehouse::Place.columns.
        collect { |column| column.name.to_sym }.should =~ [:place_id, :user_id]
  end

  it { should belong_to(:place).class_name("::Place") }
  it { should belong_to :user }
  it { should have_one(:storekeeper).through(:user).class_name(Entity) }

  it { should validate_presence_of :user_id }

  describe "#save" do
    it "should create new warehouse through save" do
      place = create(:place)
      user = create(:user)
      w_place = Warehouse::Place.new(place_id: place.id, user_id: user.id)
      expect do
        w_place.save.should be_true
      end.to change(Credential, :count).by(1)
      user.credentials(:force_update).count.should eq(1)
      user.credentials.first.document_type.should eq(Warehouse.name)
      user.credentials.first.place_id.should eq(place.id)
    end

    it "should not create credentials if user is not specified" do
      place = create(:place)
      w_place = Warehouse::Place.new(place_id: place.id)
      expect do
        w_place.save.should be_false
      end.to change(Credential, :count).by(0)
    end

    it "should call validation" do
      place = create(:place)
      w_place = Warehouse::Place.new(place_id: place.id)
      w_place.errors.should be_empty
      expect do
        w_place.save.should be_false
      end.to change(Credential, :count).by(0)
      w_place.errors.should_not be_empty
    end
  end

  describe "#count" do
    it "should return count only for users with access to Warehouse and place_id specified" do
      User.destroy_all
      5.times do
        user = create(:user)
        create(:credential, user: user, document_type: Warehouse.name, place: create(:place))
      end
      5.times do
        user = create(:user)
        create(:credential, user: user, document_type: Place.name, place: create(:place))
      end
      Warehouse::Place.count.should eq(5)
    end
  end

  describe "#all" do
    it "should return warehouses with data" do
      User.destroy_all
      users =
        5.times.collect do
          user = create(:user)
          user.credentials.create(document_type: Warehouse.name, place: create(:place))
          user
        end
      5.times do
        user = create(:user)
        create(:credential, user: user, document_type: Place.name, place: create(:place))
      end
      Warehouse::Place.all.count.should eq(5)
      warehouses = users.collect { |user| Warehouse::Place.new(user_id: user.id, place_id: user.credentials.first.place_id) }
      Warehouse::Place.all.should =~ warehouses
    end
  end
end
