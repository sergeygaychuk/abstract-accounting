require "resource"

class StorehouseEntry
  attr_reader :owner, :place, :product, :real_amount, :amount
  def initialize(deal, place, amount)
    @amount = 0
    @real_amount = 0
    @product = nil
    @owner = nil
    @place = place
    if !deal.nil?
      @owner = deal.entity
      @product = Product.find_by_resource_id deal.give
      @amount = amount
      @real_amount = deal.state.amount
    end
  end

  def StorehouseEntry.state(deal, releases = nil)
    return 0 if deal.nil? or deal.state.nil?
    start_state = deal.state.amount
    if releases.nil?
      releases = StorehouseRelease.find_all_by_state StorehouseRelease::INWORK,
          :include => {:deal => {:rules => :from}}
    end
    releases.each do |item|
      if !item.deal.nil?
        item.deal.rules.each do |rule|
          if rule.from.id == deal.id
            start_state -= rule.rate
          end
        end
      end
    end
    start_state
  end
end

class Storehouse < Array
  attr_reader :entity, :place
  def initialize(entity = nil, place = nil, real_amount = true)
    @entity = entity
    @place = place
    wbs = Waybill.find_by_owner_and_place @entity, @place,
          :include => { :deal => { :rules => :to }}
    releases = StorehouseRelease.find_all_by_owner_and_place_and_state @entity, @place,
          StorehouseRelease::INWORK, :include => {:deal => {:rules => :from}}
    if !wbs.nil?
      inner = Hash.new
      wbs.each do |item|
        if !item.deal.nil?
          item.deal.rules.each do |rule|
            if !inner.has_key?(rule.to.id)
              amount = StorehouseEntry.state(rule.to, releases)
              if (real_amount and !rule.to.state.nil? and rule.to.state.amount > 0) or
                  (!real_amount and amount > 0)
                self << StorehouseEntry.new(rule.to, item.place, amount)
              end
              inner[rule.to.id] = true
            end
          end
        end
      end
    end
  end

  def Storehouse.shipment
    a = Asset.find_by_tag("Storehouse Shipment")
    if a.nil?
      a = Asset.new :tag => "Storehouse Shipment"
      return nil unless a.save
    end
    a
  end
end
