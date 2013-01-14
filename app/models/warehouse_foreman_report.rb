# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class WarehouseForemanReport
  attr_reader :resource, :amount, :price

  def initialize(attrs)
    @resource = attrs[:resource]
    @amount = Converter.float(attrs[:amount])
    @price = Converter.float(attrs[:price])
  end

  def sum
    @amount * @price
  end

  class << self
    def foremen(warehouse_id)
      reversed_scope  = Allocation.joins{deal.to_facts}.where{deal.to_facts.amount == -1.0}.
          select{deal.id}

      Allocation.joins{deal.give}.where{deal.give.place_id == warehouse_id}.
          joins{deal.to_facts}.
          joins{deal.deal_state}.where{deal.deal_state.closed != nil}.
          where{deal.id.not_in(reversed_scope)}.
          joins{deal.rules.to}.select{deal.rules.to.entity_id}.
          select{deal.rules.to.entity_type}.uniq.
          all.collect { |al| al.entity_type.constantize.find(al.entity_id) }
    end

    def all(args)
      scope = scoped(args)

      if args[:page] && args[:per_page] && args[:page].to_i > 0 && args[:per_page].to_i > 0
        scope = scope.limit(args[:per_page]).
            offset(args[:per_page].to_i * (args[:page].to_i - 1))
      end

      if args[:resource_ids] && !args[:resource_ids].nil?
        resource_ids =  args[:resource_ids].split(',')
        scope = scope.where{resource_id.in resource_ids}
      end

      prices = prices_scoped_with_range(args).
          joins{from.take}.where{from.take.resource_id.in(scope.select{resource_id})}.
          select{resource_id}.select{resource_type}.
          select{(sum(facts.amount / from.rate) / sum(facts.amount)).as(:price)}.all

      prices_before = nil

      scope.select{resource_id}.select{resource_type}.select{sum(amount).as(:amount)}.
          includes(:resource).collect do |fact|
        price = 1.0
        price_obj = prices.select do |item|
          item.resource_id == fact.resource_id && item.resource_type == fact.resource_type
        end[0]
        if price_obj
          price = price_obj.price
        else
          unless prices_before
            prices_before = prices_scoped_before(args).
                joins{from.take}.where{from.take.resource_id.in(scope.select{resource_id})}.
                select{resource_id}.select{resource_type}.
                select{(max(parent.to.waybill.id)).as(:waybill_id)}.all
          end
          price_item = prices_before.select do |item|
            item.resource_id == fact.resource_id && item.resource_type == fact.resource_type
          end[0]

          price_obj = Waybill.where{id == price_item.waybill_id}.
              joins{deal.rules.from.take}.
              where{deal.rules.from.take.resource_id == fact.resource_id}.
              select{deal.rules.from.rate.as(:price)}.first
          price = (1.0 / Converter.float(price_obj.price))
        end
        WarehouseForemanReport.new(resource: fact.resource, amount: fact.amount,
                                   price: Converter.float(price).accounting_norm)
      end
    end

    def count(args)
      SqlRecord.from(scoped(args).select{resource_id}.to_sql).count
    end

    private
    def scoped(args)
      reversed_scope  = Allocation.joins{deal.to_facts}.where{deal.to_facts.amount == -1.0}.
          select{deal.id}

      scope = Fact.joins{parent.to.give}.where{parent.to.give.place_id == my{args[:warehouse_id]}}.
                joins{to}.joins{parent.to.allocation}.
                where{parent.to_deal_id.not_in(reversed_scope)}.
                where{(to.entity_id == my{args[:foreman_id]}) & (to.entity_type == Entity.name)}

      if args[:start] && args[:stop]
        scope = scope.where{parent.to.allocation.created >= my{args[:start].beginning_of_day}}.
                      where{parent.to.allocation.created <= my{args[:stop].end_of_day}}
      end
      scope.group{resource_id}.group{resource_type}
    end

    def prices_scoped_with_range(args)
      reversed_scope  = Waybill.joins{deal.to_facts}.where{deal.to_facts.amount == -1.0}.
          select{deal.id}

      scope = Fact.joins{parent.to.take}.where{parent.to.take.place_id == my{args[:warehouse_id]}}.
                joins{parent.to.waybill}.
                where{parent.to_deal_id.not_in(reversed_scope)}
      if args[:start] && args[:stop]
        scope = scope.where{parent.to.waybill.created >= my{args[:start].beginning_of_day}}.
                      where{parent.to.waybill.created <= my{args[:stop].end_of_day}}
      end
      scope.group{resource_id}.group{resource_type}
    end

    def prices_scoped_before(args)
      reversed_scope  = Waybill.joins{deal.to_facts}.where{deal.to_facts.amount == -1.0}.
          select{deal.id}

      scope = Fact.joins{parent.to.take}.where{parent.to.take.place_id == my{args[:warehouse_id]}}.
                joins{parent.to.waybill}.
                where{parent.to_deal_id.not_in(reversed_scope)}
      if args[:start] && args[:stop]
        scope = scope.where{parent.to.waybill.created <= my{args[:start].beginning_of_day}}
      end
      scope.group{resource_id}.group{resource_type}
    end
  end
end