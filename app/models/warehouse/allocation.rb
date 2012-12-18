# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'warehouse/waybill'

module Warehouse
  class AllocationItemsValidator < ActiveModel::Validator
    def validate(record)
      record.errors[:items] << I18n.t('errors.messages.blank') if record.items.empty?

      record.items.each_with_index do |item, index|
        deal = record.create_storekeeper_deal(item, index)
        record.errors[:items] = 'invalid' if !deal || deal.new_record?
        warehouse_amount = item.exp_amount
        if (item.amount > warehouse_amount) || (item.amount <= 0)
          record.errors[:items] = I18n.t("errors.messages.less_than_or_equal_to",
                                         count: warehouse_amount)
        end
      end
    end
  end

  class Allocation < ActiveRecord::Base
    include Warehouse::Deal
    act_as_warehouse_deal from: :storekeeper, to: :foreman

    warehouse_attr :storekeeper, polymorphic: true,
                   reader: -> { self.deal.nil? ? nil : self.deal.entity }
    warehouse_attr :foreman, polymorphic: true,
                   reader: -> { self.deal.nil? ? nil : self.deal.rules.first.to.entity }
    warehouse_attr :storekeeper_place, class: ::Place,
                   reader: -> { self.deal.nil? ? nil : self.deal.give.place }
    warehouse_attr :foreman_place, class: ::Place,
                   reader: -> { self.deal.nil? ? nil : self.deal.take.place }

    class << self
      def by_warehouse(place)
        joins{deal.give}.
            where{deal.give.place_id == place.id}
      end

      def order_by(attrs = {})
        field = nil
        scope = self
        case attrs[:field].to_s
          when 'storekeeper'
            scope = scope.joins{deal.entity(Entity)}
            field = 'entities.tag'
          when 'storekeeper_place'
            scope = scope.joins{deal.give.place}
            field = 'places.tag'
          when 'foreman'
            scope = scope.joins{deal.rules.to.entity(Entity)}.
                group('allocations.id, allocations.created, allocations.deal_id, entities.tag')
            field = 'entities.tag'
          else
            field = attrs[:field] if attrs[:field]
        end
        unless field.nil?
          if attrs[:type] == 'desc'
            scope = scope.order("#{field} DESC")
          else
            scope = scope.order("#{field}")
          end
        end
        scope
      end

      def search(attrs = {})
        scope = attrs.keys.inject(scoped) do |mem, key|
          case key.to_s
            when 'foreman'
              mem.joins{deal.rules.to.entity(Entity)}.uniq
            when 'storekeeper'
              mem.joins{deal.entity(Entity)}
            when 'storekeeper_place'
              mem.joins{deal.give.place}
            when 'resource_tag'
              mem.joins{deal.rules.from.give.resource(Asset)}.uniq
            when 'state'
              mem.joins{deal.deal_state}.joins{deal.to_facts.outer}
            else
              mem
          end
        end
        attrs.inject(scope) do |mem, (key, value)|
          case key.to_s
            when 'foreman'
              mem.where{lower(deal.rules.to.entity.tag).like(lower("%#{value}%"))}
            when 'storekeeper'
              mem.where{lower(deal.entity.tag).like(lower("%#{value}%"))}
            when 'storekeeper_place'
              mem.where{lower(deal.give.place.tag).like(lower("%#{value}%"))}
            when 'resource_tag'
              mem.where{lower(deal.rules.from.give.resource.tag).like(lower("%#{value}%"))}
            when 'state'
              case value.to_i
                when INWORK
                  mem.where{deal.deal_state.closed == nil}
                when APPLIED
                  mem.where{(deal.deal_state.closed != nil) & (deal.to_facts.amount == 1.0)}
                when CANCELED
                  mem.where{(deal.deal_state.closed != nil) & (deal.to_facts.id == nil)}
                when REVERSED
                  mem.where{(deal.deal_state.closed != nil) & (deal.to_facts.amount == -1.0)}
              end
            when 'created'
              mem.where{to_char(created, 'YYYY-MM-DD').like("%#{value}%")}
            else
              mem.where{lower(__send__(key)).like(lower("%#{value}%"))}
          end
        end
      end
    end

    validates_with AllocationItemsValidator

    before_item_save :do_before_item_save

    MOTION_ALLOCATION = 0
    MOTION_INNER = 1



    def document_id
      if self.new_record?
        Allocation.last.nil? ? 1 : Allocation.last.id + 1
      else
        self.id.to_s
      end
    end

    def foreman_place_or_new
      return ::Place.find(self.foreman_place.id) if self.foreman_place
      if self.warehouse_id
        ::Place.find(Allocation.extract_warehouse(self.warehouse_id)[:storekeeper_place_id])
      else
        ::Place.new
      end
    end

    def motion
      self.deal.give.place_id == self.deal.take.place_id ? MOTION_ALLOCATION : MOTION_INNER
    end

    def create_foreman_deal(item, idx)
      deal = create_deal(item.resource, item.resource,
                         storekeeper_place, foreman_place,
                         foreman, 1.0, idx)
      deal.limit.update_attributes(amount: item.amount) if deal && self.motion == MOTION_INNER
      deal
    end

    private
    def do_before_item_save(item)
      return false if item.resource.new_record?
      true
    end
  end
end