# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "spec_helper"

WarehouseResourceReport.class_eval do
  def ==(other)
    return false unless other.instance_of?(WarehouseResourceReport)
    date.to_date == other.date.to_date && entity == other.entity && amount == other.amount &&
        state == other.state && side == other.side && document_id == other.document_id &&
        item_id == other.item_id
  end
end

describe WarehouseResourceReport do
  it "should return empty state for unknown resource" do
    WarehouseResourceReport.all(resource_id: create(:asset).id,
                                warehouse_id: create(:place).id).should be_empty
    WarehouseResourceReport.count(resource_id: create(:asset).id,
                                   warehouse_id: create(:place).id).should eq(0)
    WarehouseResourceReport.total(resource_id: create(:asset).id,
                                   warehouse_id: create(:place).id).should eq(0.0)
  end

  it "should return states from waybills" do
    create(:chart)
    storekeeper = create(:entity)
    warehouse = create(:place)
    resource = create(:asset)
    count = 3

    count.times do
      waybill = build(:waybill, storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
      waybill.save!
      waybill.apply.should be_true
    end

    report = WarehouseResourceReport.all(resource_id: resource.id, warehouse_id: warehouse.id)
    WarehouseResourceReport.
        count(resource_id: resource.id, warehouse_id: warehouse.id).should eq(count)
    state = 0.0
    report.count.should eq(count)
    report.each do |item|
      item.should be_instance_of(WarehouseResourceReport)
      item.date.should_not be_nil
      item.entity.should_not be_nil
      item.amount.should_not be_nil
      item.state.should_not be_nil
      item.document_id.should_not be_nil
      item.item_id.should_not be_nil

      distributor = item.entity
      wb = Waybill.joins{deal.rules.from}.
          where{deal.rules.from.entity_id == my{distributor.id}}.uniq.first
      wb.should_not be_nil
      state += wb.items[0].amount

      item.date.should eq(wb.created)
      item.amount.should eq(wb.items[0].amount)
      item.entity.should eq(wb.distributor)
      item.state.should eq(state)
      item.document_id.should eq(wb.document_id)
      item.item_id.should eq(wb.id)
    end

    WarehouseResourceReport.
        total(resource_id: resource.id, warehouse_id: warehouse.id).should eq(state)
  end

  it "should return states from waybills without reversed waybill" do
    create(:chart)
    storekeeper = create(:entity)
    warehouse = create(:place)
    resource = create(:asset)
    count = 3

    count.times do
      waybill = build(:waybill, storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
      waybill.save!
      waybill.apply.should be_true
    end

    report = WarehouseResourceReport.all(resource_id: resource.id, warehouse_id: warehouse.id)
    WarehouseResourceReport.
        count(resource_id: resource.id, warehouse_id: warehouse.id).should eq(count)
    state = 0.0
    report.count.should eq(count)
    report.each do |item|
      item.should be_instance_of(WarehouseResourceReport)
      item.date.should_not be_nil
      item.entity.should_not be_nil
      item.amount.should_not be_nil
      item.state.should_not be_nil
      item.document_id.should_not be_nil
      item.item_id.should_not be_nil

      distributor = item.entity
      wb = Waybill.joins{deal.rules.from}.
          where{deal.rules.from.entity_id == my{distributor.id}}.uniq.first
      wb.should_not be_nil
      state += wb.items[0].amount

      item.date.should eq(wb.created)
      item.amount.should eq(wb.items[0].amount)
      item.entity.should eq(wb.distributor)
      item.state.should eq(state)
      item.document_id.should eq(wb.document_id)
      item.item_id.should eq(wb.id)
    end

    WarehouseResourceReport.
        total(resource_id: resource.id, warehouse_id: warehouse.id).should eq(state)

    waybill = build(:waybill, storekeeper: storekeeper, storekeeper_place: warehouse)
    waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
    waybill.save!
    waybill.apply.should be_true

    report = WarehouseResourceReport.all(resource_id: resource.id, warehouse_id: warehouse.id)
    WarehouseResourceReport.
        count(resource_id: resource.id, warehouse_id: warehouse.id).should eq(count + 1)
    state = 0.0
    report.count.should eq(count + 1)
    report.each do |item|
      item.should be_instance_of(WarehouseResourceReport)
      item.date.should_not be_nil
      item.entity.should_not be_nil
      item.amount.should_not be_nil
      item.state.should_not be_nil
      item.document_id.should_not be_nil
      item.item_id.should_not be_nil

      wb = Waybill.where{id == item.item_id}.first
      wb.should_not be_nil
      state += wb.items[0].amount

      item.date.should eq(wb.created)
      item.amount.should eq(wb.items[0].amount)
      item.entity.should eq(wb.distributor)
      item.state.should eq(state)
      item.document_id.should eq(wb.document_id)
      item.item_id.should eq(wb.id)
    end

    WarehouseResourceReport.
        total(resource_id: resource.id, warehouse_id: warehouse.id).should eq(state)

    waybill.reverse.should be_true

    report = WarehouseResourceReport.all(resource_id: resource.id, warehouse_id: warehouse.id)
    WarehouseResourceReport.
        count(resource_id: resource.id, warehouse_id: warehouse.id).should eq(count)
    state = 0.0
    report.count.should eq(count)
    report.each do |item|
      item.should be_instance_of(WarehouseResourceReport)
      item.date.should_not be_nil
      item.entity.should_not be_nil
      item.amount.should_not be_nil
      item.state.should_not be_nil
      item.document_id.should_not be_nil
      item.item_id.should_not be_nil
      item.item_id.should_not eq(waybill.id)

      wb = Waybill.where{id == item.item_id}.first
      wb.should_not be_nil
      state += wb.items[0].amount

      item.date.should eq(wb.created)
      item.amount.should eq(wb.items[0].amount)
      item.entity.should eq(wb.distributor)
      item.state.should eq(state)
      item.document_id.should eq(wb.document_id)
      item.item_id.should eq(wb.id)
    end

    WarehouseResourceReport.
        total(resource_id: resource.id, warehouse_id: warehouse.id).should eq(state)
  end

  it "should return states from waybills and allocations" do
    create(:chart)
    storekeeper = create(:entity)
    warehouse = create(:place)
    resource = create(:asset)
    count = 3

    count.times do
      waybill = build(:waybill, storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      allocation = build(:allocation, storekeeper: storekeeper, storekeeper_place: warehouse)
      allocation.add_item(tag: resource.tag, mu: resource.mu,
                amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
      allocation.save!
      allocation.apply.should be_true
    end

    report = WarehouseResourceReport.all(resource_id: resource.id, warehouse_id: warehouse.id)
    WarehouseResourceReport.
        count(resource_id: resource.id, warehouse_id: warehouse.id).should eq(count * 2)
    state = 0
    report.count.should eq(count * 2)
    report.each do |item|
      item.should be_instance_of(WarehouseResourceReport)
      item.date.should_not be_nil
      item.entity.should_not be_nil
      item.amount.should_not be_nil
      item.state.should_not be_nil
      item.side.should_not be_nil
      item.document_id.should_not be_nil
      item.item_id.should_not be_nil

      date = nil
      amount = nil
      entity = nil
      document_id = nil
      item_id = nil

      if item.side == WarehouseResourceReport::WAYBILL_SIDE
        distributor = item.entity
        wb = Waybill.joins{deal.rules.from}.
            where{deal.rules.from.entity_id == my{distributor.id}}.uniq.first
        wb.should_not be_nil
        state += wb.items[0].amount

        date = wb.created
        amount = wb.items[0].amount
        entity = wb.distributor
        document_id = wb.document_id
        item_id = wb.id
      elsif item.side == WarehouseResourceReport::ALLOCATION_SIDE
        foreman = item.entity
        al = Allocation.joins{deal.rules.to}.
            where{deal.rules.to.entity_id == my{foreman.id}}.uniq.first
        al.should_not be_nil
        state -= al.items[0].amount

        date = al.created
        amount = al.items[0].amount
        entity = al.foreman
        document_id = al.document_id
        item_id = al.id
      end

      item.date.should eq(date)
      item.amount.should eq(amount)
      item.entity.should eq(entity)
      item.state.should eq(state)
      item.document_id.should eq(document_id)
      item.item_id.should eq(item_id)
    end

    WarehouseResourceReport.
        total(resource_id: resource.id, warehouse_id: warehouse.id).should eq(state)
  end

  it "should return states from waybills and allocations without reversed allocations" do
    create(:chart)
    storekeeper = create(:entity)
    warehouse = create(:place)
    resource = create(:asset)
    count = 3

    count.times do
      waybill = build(:waybill, storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      allocation = build(:allocation, storekeeper: storekeeper, storekeeper_place: warehouse)
      allocation.add_item(tag: resource.tag, mu: resource.mu,
                amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
      allocation.save!
      allocation.apply.should be_true
    end

    report = WarehouseResourceReport.all(resource_id: resource.id, warehouse_id: warehouse.id)
    WarehouseResourceReport.
        count(resource_id: resource.id, warehouse_id: warehouse.id).should eq(count * 2)
    state = 0
    report.count.should eq(count * 2)
    report.each do |item|
      item.should be_instance_of(WarehouseResourceReport)
      item.date.should_not be_nil
      item.entity.should_not be_nil
      item.amount.should_not be_nil
      item.state.should_not be_nil
      item.side.should_not be_nil
      item.document_id.should_not be_nil
      item.item_id.should_not be_nil

      date = nil
      amount = nil
      entity = nil
      document_id = nil
      item_id = nil

      if item.side == WarehouseResourceReport::WAYBILL_SIDE
        distributor = item.entity
        wb = Waybill.joins{deal.rules.from}.
            where{deal.rules.from.entity_id == my{distributor.id}}.uniq.first
        wb.should_not be_nil
        state += wb.items[0].amount

        date = wb.created
        amount = wb.items[0].amount
        entity = wb.distributor
        document_id = wb.document_id
        item_id = wb.id
      elsif item.side == WarehouseResourceReport::ALLOCATION_SIDE
        foreman = item.entity
        al = Allocation.joins{deal.rules.to}.
            where{deal.rules.to.entity_id == my{foreman.id}}.uniq.first
        al.should_not be_nil
        state -= al.items[0].amount

        date = al.created
        amount = al.items[0].amount
        entity = al.foreman
        document_id = al.document_id
        item_id = al.id
      end

      item.date.should eq(date)
      item.amount.should eq(amount)
      item.entity.should eq(entity)
      item.state.should eq(state)
      item.document_id.should eq(document_id)
      item.item_id.should eq(item_id)
    end

    WarehouseResourceReport.
        total(resource_id: resource.id, warehouse_id: warehouse.id).should eq(state)


    waybill = build(:waybill, storekeeper: storekeeper, storekeeper_place: warehouse)
    waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
    waybill.save!
    waybill.apply.should be_true

    allocation = build(:allocation, storekeeper: storekeeper, storekeeper_place: warehouse)
    allocation.add_item(tag: resource.tag, mu: resource.mu,
              amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
    allocation.save!
    allocation.apply.should be_true

    report = WarehouseResourceReport.all(resource_id: resource.id, warehouse_id: warehouse.id)
    WarehouseResourceReport.
        count(resource_id: resource.id, warehouse_id: warehouse.id).should eq(count * 2 + 2)
    state = 0
    report.count.should eq(count * 2 + 2)
    report.each do |item|
      item.should be_instance_of(WarehouseResourceReport)
      item.date.should_not be_nil
      item.entity.should_not be_nil
      item.amount.should_not be_nil
      item.state.should_not be_nil
      item.side.should_not be_nil
      item.document_id.should_not be_nil
      item.item_id.should_not be_nil

      date = nil
      amount = nil
      entity = nil
      document_id = nil
      item_id = nil

      if item.side == WarehouseResourceReport::WAYBILL_SIDE
        distributor = item.entity
        wb = Waybill.joins{deal.rules.from}.
            where{deal.rules.from.entity_id == my{distributor.id}}.uniq.first
        wb.should_not be_nil
        state += wb.items[0].amount

        date = wb.created
        amount = wb.items[0].amount
        entity = wb.distributor
        document_id = wb.document_id
        item_id = wb.id
      elsif item.side == WarehouseResourceReport::ALLOCATION_SIDE
        foreman = item.entity
        al = Allocation.joins{deal.rules.to}.
            where{deal.rules.to.entity_id == my{foreman.id}}.uniq.first
        al.should_not be_nil
        state -= al.items[0].amount

        date = al.created
        amount = al.items[0].amount
        entity = al.foreman
        document_id = al.document_id
        item_id = al.id
      end

      item.date.should eq(date)
      item.amount.should eq(amount)
      item.entity.should eq(entity)
      item.state.should eq(state)
      item.document_id.should eq(document_id)
      item.item_id.should eq(item_id)
    end

    WarehouseResourceReport.
        total(resource_id: resource.id, warehouse_id: warehouse.id).should eq(state)

    allocation.reverse.should be_true

    report = WarehouseResourceReport.all(resource_id: resource.id, warehouse_id: warehouse.id)
    WarehouseResourceReport.
        count(resource_id: resource.id, warehouse_id: warehouse.id).should eq(count * 2 + 1)
    state = 0
    report.count.should eq(count * 2 + 1)
    report.each do |item|
      item.should be_instance_of(WarehouseResourceReport)
      item.date.should_not be_nil
      item.entity.should_not be_nil
      item.amount.should_not be_nil
      item.state.should_not be_nil
      item.side.should_not be_nil
      item.document_id.should_not be_nil
      item.item_id.should_not be_nil
      item.item_id.
        should_not eq(allocation.id) if item.side == WarehouseResourceReport::ALLOCATION_SIDE

      date = nil
      amount = nil
      entity = nil
      document_id = nil
      item_id = nil

      if item.side == WarehouseResourceReport::WAYBILL_SIDE
        distributor = item.entity
        wb = Waybill.joins{deal.rules.from}.
            where{deal.rules.from.entity_id == my{distributor.id}}.uniq.first
        wb.should_not be_nil
        state += wb.items[0].amount

        date = wb.created
        amount = wb.items[0].amount
        entity = wb.distributor
        document_id = wb.document_id
        item_id = wb.id
      elsif item.side == WarehouseResourceReport::ALLOCATION_SIDE
        foreman = item.entity
        al = Allocation.joins{deal.rules.to}.
            where{deal.rules.to.entity_id == my{foreman.id}}.uniq.first
        al.should_not be_nil
        state -= al.items[0].amount

        date = al.created
        amount = al.items[0].amount
        entity = al.foreman
        document_id = al.document_id
        item_id = al.id
      end

      item.date.should eq(date)
      item.amount.should eq(amount)
      item.entity.should eq(entity)
      item.state.should eq(state)
      item.document_id.should eq(document_id)
      item.item_id.should eq(item_id)
    end

    WarehouseResourceReport.
        total(resource_id: resource.id, warehouse_id: warehouse.id).should eq(state)
  end

  it "should return states from waybills and allocations by date" do
    Waybill.delete_all
    Allocation.delete_all
    create(:chart)
    storekeeper = create(:entity)
    warehouse = create(:place)
    resource = create(:asset)
    date = Date.current.change(year: 2011)
    count = 3

    count.times do |i|
      waybill = build(:waybill, created: date + i * 2,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      allocation = build(:allocation, created: date + i * 2 + 1,
                         storekeeper: storekeeper, storekeeper_place: warehouse)
      allocation.add_item(tag: resource.tag, mu: resource.mu,
                amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
      allocation.save!
      allocation.apply.should be_true
    end

    report = WarehouseResourceReport.all(resource_id: resource.id, warehouse_id: warehouse.id)
    WarehouseResourceReport.
        count(resource_id: resource.id, warehouse_id: warehouse.id).should eq(count * 2)
    report.count.should eq(count * 2)

    report_c = []
    state = 0.0
    Waybill.all.each_with_index do |w, ind|
      amount = w.items[0].amount
      state += amount
      report_c << WarehouseResourceReport.new(date: w.created, entity: w.distributor,
        amount: amount, state: state, side: WarehouseResourceReport::WAYBILL_SIDE,
        document_id: w.document_id, item_id: w.id)

      al = Allocation.all[ind]
      amount = al.items[0].amount
      state -= amount
      report_c << WarehouseResourceReport.new(date: al.created, entity: al.foreman,
        amount: amount, state: state, side: WarehouseResourceReport::ALLOCATION_SIDE,
        document_id: al.document_id, item_id: al.id)
    end

    report.should eq(report_c)

    WarehouseResourceReport.
        total(resource_id: resource.id, warehouse_id: warehouse.id).should eq(state)
  end

  it "should return states from waybills and allocations by date and amount" do
    Waybill.delete_all
    Allocation.delete_all
    create(:chart)
    storekeeper = create(:entity)
    warehouse = create(:place)
    resource = create(:asset)
    date = Date.current.change(year: 2011)
    count = 3

    count.times do |i|
      waybill = build(:waybill, created: date + i * 2,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      allocation = build(:allocation, created: date + i * 2,
                         storekeeper: storekeeper, storekeeper_place: warehouse)
      allocation.add_item(tag: resource.tag, mu: resource.mu,
                amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
      allocation.save!
      allocation.apply.should be_true
    end

    report = WarehouseResourceReport.all(resource_id: resource.id, warehouse_id: warehouse.id)
    WarehouseResourceReport.
        count(resource_id: resource.id, warehouse_id: warehouse.id).should eq(count * 2)
    report.count.should eq(count * 2)

    report_c = []
    state = 0.0
    Waybill.all.each_with_index do |w, ind|
      amount = w.items[0].amount
      state += amount
      report_c << WarehouseResourceReport.new(date: w.created, entity: w.distributor,
        amount: amount, state: state, side: WarehouseResourceReport::WAYBILL_SIDE,
        document_id: w.document_id, item_id: w.id)

      al = Allocation.all[ind]
      amount = al.items[0].amount
      state -= amount
      report_c << WarehouseResourceReport.new(date: al.created, entity: al.foreman,
        amount: amount, state: state, side: WarehouseResourceReport::ALLOCATION_SIDE,
        document_id: al.document_id, item_id: al.id)
    end

    report.should eq(report_c)

    WarehouseResourceReport.
        total(resource_id: resource.id, warehouse_id: warehouse.id).should eq(state)
  end

  it "should return states with paginate" do
    Waybill.delete_all
    Allocation.delete_all
    create(:chart)
    storekeeper = create(:entity)
    warehouse = create(:place)
    resource = create(:asset)
    date = Date.current.change(year: 2011)
    count = 10

    count.times do |i|
      waybill = build(:waybill, created: date + i * 2,
                      storekeeper: storekeeper, storekeeper_place: warehouse)
      waybill.add_item(tag: resource.tag, mu: resource.mu, amount: rand(1..10), price: 11.32)
      waybill.save!
      waybill.apply.should be_true

      allocation = build(:allocation, created: date + i * 2,
                         storekeeper: storekeeper, storekeeper_place: warehouse)
      allocation.add_item(tag: resource.tag, mu: resource.mu,
                amount: (waybill.items[0].amount / 2) > 0 ? (waybill.items[0].amount / 2) : 1)
      allocation.save!
      allocation.apply.should be_true
    end

    report = WarehouseResourceReport.all(resource_id: resource.id, warehouse_id: warehouse.id,
                                         page: 1, per_page: count)
    WarehouseResourceReport.
        count(resource_id: resource.id, warehouse_id: warehouse.id).should eq(count * 2)
    report.count.should eq(count)

    report_c = []
    state = 0.0
    Waybill.all.each_with_index do |w, ind|

      break if count / 2 == ind

      amount = w.items[0].amount
      state += amount
      report_c << WarehouseResourceReport.new(date: w.created, entity: w.distributor,
        amount: amount, state: state, side: WarehouseResourceReport::WAYBILL_SIDE,
        document_id: w.document_id, item_id: w.id)

      al = Allocation.all[ind]
      amount = al.items[0].amount
      state -= amount
      report_c << WarehouseResourceReport.new(date: al.created, entity: al.foreman,
        amount: amount, state: state, side: WarehouseResourceReport::ALLOCATION_SIDE,
        document_id: al.document_id, item_id: al.id)
    end

    WarehouseResourceReport.
        total(resource_id: resource.id, warehouse_id: warehouse.id).should_not eq(state)

    report.count.should eq(report_c.count)
    report.should eq(report_c)

    report = WarehouseResourceReport.all(resource_id: resource.id, warehouse_id: warehouse.id,
                                         page: 2, per_page: count)

    report_c = []
    Waybill.offset(count / 2).all.each_with_index do |w, ind|
      break if count / 2 == ind

      amount = w.items[0].amount
      state += amount
      report_c << WarehouseResourceReport.new(date: w.created, entity: w.distributor,
        amount: amount, state: state, side: WarehouseResourceReport::WAYBILL_SIDE,
        document_id: w.document_id, item_id: w.id)

      al = Allocation.offset(count / 2).all[ind]
      amount = al.items[0].amount
      state -= amount
      report_c << WarehouseResourceReport.new(date: al.created, entity: al.foreman,
        amount: amount, state: state, side: WarehouseResourceReport::ALLOCATION_SIDE,
        document_id: al.document_id, item_id: al.id)
    end

    report.count.should eq(report_c.count)
    report.should eq(report_c)

    WarehouseResourceReport.
        total(resource_id: resource.id, warehouse_id: warehouse.id).should eq(state)
  end
end
