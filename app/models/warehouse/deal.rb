# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Warehouse
  module Deal
    extend ActiveSupport::Concern

    module ClassMethods
      def act_as_warehouse_deal(args = { from: :from, to: :to})
        has_paper_trail
        include Helpers::Statable
        act_as_statable
        include Helpers::Commentable
        has_comments

        class_attribute :warehouse_fields

        warehouse_entity(args[:from])
        warehouse_entity(args[:to])
        self.warehouse_fields = args

        validates_presence_of :created

        belongs_to :deal, class_name: "::Deal"

        before_save :before_warehouse_deal_save
        after_save :after_warehouse_deal_save
        class_attribute :before_item_save_callback

        after_apply :send_comment_after_apply
        after_reverse :send_comment_after_reverse
        after_cancel :send_comment_after_cancel

        before_apply :do_apply
        before_reverse :do_reverse

        scope :includes_all, includes(deal: [:entity, :deal_state, :to_facts,
                                               give: [:resource, :place],
                                               take: [:resource, :place],
                                               rules: [from: [:entity,
                                                              terms: [:resource, :place]],
                                                       to: [:entity,
                                                            terms: [:resource, :place]]]])
      end

      def warehouse_attr(name, options = {})
        Helpers::ReferenceAttrBuilder.build(self, name, options)
      end

      def before_item_save(callback)
        self.before_item_save_callback = callback
      end

      def warehouse_entity(name)
        attr_name = name.kind_of?(String) ? name : name.to_s
        attr_place = "#{attr_name}_place"
        validates_presence_of attr_name.to_sym, attr_place.to_sym
      end
    end

    def add_item(attrs = {})
      @items ||= []
      @items << DealItem.new(attrs[:tag], attrs[:mu], attrs[:amount], attrs[:price])
    end

    def items
      @items ||= []
      if @items.empty? && self.deal
        @items = self.deal.rules.collect do |rule|
          resource = rule.from.take.resource
          item = DealItem.new(resource.tag, resource.mu, rule.rate,
                              (1.0 / rule.from.rate).accounting_norm)
          item.resource = resource
          item
        end
      end
      @items
    end

    #def owner?
    #  user = PaperTrail.whodunnit
    #  return false if user.root?
    #  return !self.warehouse_id.nil? if self.new_record?
    #  self.storekeeper == user.entity
    #end

    def warehouse=(warehouse)
      self.storekeeper = warehouse.storekeeper
      self.storekeeper_place = warehouse.place
    end

    def warehouse
      Warehouse::Place.by_place(self.storekeeper_place).by_storekeeper(self.storekeeper).first
    end

    def create_deal(give_resource, take_resource, from_place, to_place, entity, rate, item_idx)
      deal = ::Deal.joins(:give, :take).where do
        (give.resource_id == give_resource) & (give.place_id == from_place) &
        (take.resource_id == take_resource) & (take.place_id == to_place) &
        (entity_id == entity) & (entity_type == entity.class.name) & (self.rate == rate)
      end.first
      unless deal
        deal = ::Deal.new(entity: entity, rate: rate,
            tag: I18n.t("activerecord.attributes.#{
                          self.class.name.demodulize.downcase}.deal.resource.tag",
                        id: self.document_id, index: item_idx + 1, deal_id: self.deal_id))
        return nil unless deal.build_give(place: from_place, resource: give_resource)
        return nil unless deal.build_take(place: to_place, resource: take_resource)
        return nil unless deal.save
      end
      deal
    end

    def create_storekeeper_deal(item, index)
      create_deal(item.resource, item.resource, storekeeper_place, storekeeper_place,
                  storekeeper, 1.0, index)
    end

    def create_main_deal
      settings = self.class.warehouse_fields
      deal = ::Deal.new(entity: self.storekeeper, rate: 1.0, isOffBalance: true,
                tag: I18n.t("activerecord.attributes.#{
                                self.class.name.demodulize.downcase}.deal.tag",
                            id: self.document_id, place: storekeeper_place.tag,
                            deal_id: ::Deal.count > 0 ? ::Deal.last.id + 1 : 1))
      shipment = Asset.find_or_create_by_tag(I18n.t('activerecord.defaults.assets.shipment'))
      return nil unless deal.build_give(place: self.send("#{settings[:from]}_place"),
                                        resource: shipment)
      return nil unless deal.build_take(place: self.send("#{settings[:to]}_place"),
                                        resource: shipment)
      deal.save ? deal : nil
    end

    def create_rule(item, idx)
      settings = self.class.warehouse_fields
      return false if self.class.before_item_save_callback &&
                      !send(self.class.before_item_save_callback, item)

      return false unless self.deal.rules.create(
          tag: "#{deal.tag}; rule#{idx}",
          from: send("create_#{settings[:from]}_deal", item, idx),
          to: send("create_#{settings[:to]}_deal", item, idx),
          fact_side: false,
          change_side: true,
          rate: item.amount).valid?
      true
    end

    def before_warehouse_deal_save
      return false unless self.unknown? || self.in_work?
      settings = self.class.warehouse_fields
      unless self.new_record?
        self.deal.rules.each do |rule|
          rule.from.destroy if rule.from.states.count == 0
          rule.to.destroy if rule.to.states.count == 0
        end
        self.deal.rules.destroy_all
        self.deal.rules = []
      end
      if self.storekeeper_id_changed? || self.storekeeper_type_changed? ||
          self.send("#{settings[:to]}_place_id_changed?") ||
          self.send("#{settings[:from]}_place_id_changed?")
        self.deal.destroy unless self.new_record?
        return false unless (self.deal = create_main_deal)
        self.deal_id = self.deal.id
      end
      if self.deal && self.deal.rules.empty?
        @items.each_with_index { |item, idx| return false unless create_rule(item, idx) }
      end
      true
    end

    def changed(*)
      super & attributes.keys
    end

    def after_warehouse_deal_save
      if self.id_changed?
        add_comment(I18n.t("activerecord.attributes.#{
                              self.class.name.demodulize.downcase}.comment.create"))
      else
        add_comment(I18n.t("activerecord.attributes.#{
                              self.class.name.demodulize.downcase}.comment.update"))
      end
    end

    def send_comment_after_apply
      add_comment(I18n.t("activerecord.attributes.#{
                            self.class.name.demodulize.downcase}.comment.apply"))
    end

    def send_comment_after_reverse
      add_comment(I18n.t("activerecord.attributes.#{
                            self.class.name.demodulize.downcase}.comment.reverse"))
    end

    def send_comment_after_cancel
      add_comment(I18n.t("activerecord.attributes.#{
                            self.class.name.demodulize.downcase}.comment.cancel"))
    end

    def do_apply
      return false if self.invalid?
      Txn.transaction do
        fact = Fact.create(amount: 1.0, resource: self.deal.give.resource,
                                day: DateTime.current.change(hour: 12), to: self.deal)
        return false unless fact
        !Txn.create(fact: fact).nil?
      end
    end

    def do_reverse
      Txn.transaction do
        fact = Fact.create(amount: -1.0, resource: self.deal.give.resource,
                                day: DateTime.current.change(hour: 12), to: self.deal)
        return false unless fact
        !Txn.create(fact: fact).nil?
      end
    end
  end
end
