# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe "converter for old db" do
  before(:all) do
    create(:chart)
  end

  it "should create new waybill" do

    place_id, resource_id, count = nil, nil, nil
    resource2_id, count2 = nil, nil

    hs = {}

    Convert::DbGetter.instance.warehouse_places.each do |w_place|
      place_id = w_place[:id]
      Convert::DbGetter.instance.warehouse(place_id).each do |w_resource|
        Convert::DbGetter.instance.waybills_by_resource_id_and_place_id_and_count(
          w_resource[:id], place_id, w_resource[:amount]).each do |waybill|
          if hs.has_key?(waybill[:id])
            resource_id, count = hs[waybill[:id]][0], hs[waybill[:id]][1]
            resource2_id, count2 = w_resource[:id], w_resource[:amount]
            break
          else
            hs[waybill[:id]] = [w_resource[:id], w_resource[:amount]]
          end
        end
        break if resource_id
      end
      break if resource_id
    end

    resource_id.should_not be_nil
    resource2_id.should_not be_nil

    user = create(:user)
    create(:credential, user: user, document_type: Waybill.name)

    resource = Convert::DbGetter.instance.resource(resource_id)
    waybills = Convert::DbGetter.instance.waybills_by_resource_id_and_place_id_and_count(
        resource_id, place_id, count
    ).collect do |item|
      vatin = Convert::DbGetter.instance.waybill(item[:id])[:vatin]
      vatin = "12345dsfs" if vatin.empty?
      {id: item[:id], document_id: item[:document_id],
       count: item[:count], price: 23.34, vatin: vatin }
    end
    params = {
        place_id: place_id, resource_id: resource_id, count: count,
        user_id: user.id, resource_tag: resource[:tag], resource_mu: resource[:mu],
        waybills: waybills
    }

    adder = Convert::ResourceAdder.new(params)
    adder.save

    Waybill.count.should eq(waybills.count)
    waybills.each do |old_w1|
      old_w = Convert::DbGetter.instance.waybill(old_w1[:id])
      w = Waybill.find_by_document_id(old_w[:document_id])
      w.should_not be_nil
      w.storekeeper.id.should eq(user.entity.id)
      w.storekeeper_place.id.should eq(user.credentials.first.place_id)
      old_d = Convert::DbGetter.instance.legal_entity(old_w[:distributor_id])
      w.distributor.should be_instance_of(LegalEntity)
      w.distributor.name.should eq(old_d[:name])
      w.distributor.country.tag.should eq(I18n.t("activerecord.attributes.country.default.tag"))
      w.distributor.identifier_name.should eq("VATIN")
      w.distributor.identifier_value.should eq(old_w1[:vatin])
      w.distributor_place.tag.should eq(I18n.t("views.waybills.defaults.distributor.place"))
      w.items.count.should eq(1)
      w.items[0].resource.tag.should eq(params[:resource_tag])
      w.items[0].resource.mu.should eq(params[:resource_mu])
      w.items[0].amount.should eq(old_w1[:count])
      w.items[0].price.should eq(old_w1[:price])
    end

    Convert::DbGetter.instance.warehouse(place_id).collect { |item| item[:id] }.index(resource_id).should be_nil

    old_count = Waybill.count

    adder = Convert::ResourceAdder.new(resource_id: resource2_id, place_id: place_id,
                                       count: count2)
    waybills = adder.waybills.collect do |item|
          vatin = Convert::DbGetter.instance.waybill(item[:id])[:vatin]
          {id: item[:id], document_id: item[:document_id],
           count: item[:count], price: 23.34, vatin: vatin }
        end
    found = false
    waybills.each do |w|
      unless Convert::DbGetter.instance.get_new_id(w[:id]).nil?
        w[:document_id].should eq(Waybill.find(Convert::DbGetter.instance.get_new_id(w[:id])).document_id)
        w[:vatin] = Waybill.find(Convert::DbGetter.instance.get_new_id(w[:id])).distributor.identifier_value
        found = true
      end
    end
    found.should be_true
    params = {
        place_id: place_id, resource_id: resource2_id, count: count2,
        user_id: user.id, resource_tag: adder.resource[:tag], resource_mu: adder.resource[:mu],
        waybills: waybills
    }

    adder = Convert::ResourceAdder.new(params)
    adder.save

    Waybill.count.should_not eq(waybills.count + old_count)
    waybills.each do |old_w1|
      unless Convert::DbGetter.instance.get_new_id(old_w1[:id]).nil?
        w = Waybill.find(Convert::DbGetter.instance.get_new_id(old_w1[:id]))
        w.items.count.should eq(2)
        w.items.each do |it|
          if it.resource.tag == params[:resource_tag]
            it.resource.tag.should eq(params[:resource_tag])
            it.resource.mu.should eq(params[:resource_mu])
            it.amount.should eq(old_w1[:count])
            it.price.should eq(old_w1[:price])
            break
          end
        end
      end
    end

    Convert::DbGetter.instance.warehouse(place_id).collect { |item| item[:id] }.
        index(resource2_id).should be_nil

    db = SQLite3::Database.new "#{Rails.root}/db/old.sqlite3"
    db.execute("DELETE FROM shower")
    db.execute("DELETE FROM assoc")

    waybill = build(:waybill)
    waybill.add_item(tag: "Some tag", mu: "MU", amount: 10, price: 0.64)
    waybill.save!


    waybill1 = build(:waybill, storekeeper: user.entity,
                               storekeeper_place: user.credentials.
                                  where{document_type == Waybill.name}.first.place)
    waybill1.add_item(tag: "Some tag2", mu: "MU", amount: 120, price: 2.64)
    waybill1.save!

    Convert::DbGetter.apply(user.id)

    Waybill.all.each do |w|
      if w.storekeeper.id == waybill.storekeeper.id
        w.state.should eq(Helpers::Statable::INWORK)
      elsif w.storekeeper.id == waybill1.storekeeper.id
        w.state.should eq(Helpers::Statable::INWORK)
      else
        w.state.should eq(Helpers::Statable::APPLIED)
      end
    end
  end
end
