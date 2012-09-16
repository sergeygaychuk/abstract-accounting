# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Convert
  class ResourceAdder
    attr_reader :place_id, :resource_id, :count

    def initialize(attrs = {})
      @place_id = attrs[:place_id].to_i
      @resource_id = attrs[:resource_id].to_i
      @count = attrs[:count].to_f
      if attrs[:waybills]
        @user_id = attrs[:user_id].to_i
        @document_id = attrs[:document_id]
        @resource_tag = attrs[:resource_tag]
        @resource_mu = attrs[:resource_mu]
        @waybills = []
        attrs[:waybills].each do |w|
          @waybills << w
        end
      end
    end

    def resource
      DbGetter.instance.resource(@resource_id)
    end

    def place
      DbGetter.instance.place(@place_id)
    end

    def waybills
      DbGetter.instance.waybills_by_resource_id_and_place_id_and_count(@resource_id, @place_id, @count)
    end

    def save
      throw "Unknown user_id" if @user_id <= 0
      Waybill.transaction do
        user = User.find(@user_id)
        place = user.credentials.where{document_type == Waybill.name}.first.place
        moscow = Place.find_or_create_by_tag(I18n.t("views.waybills.defaults.distributor.place"))
        @waybills.each do |w|
          throw "Should exist waybill data" if w[:price].to_f <= 0.0
          old_w = DbGetter.instance.waybill(w[:id])
          if Convert::DbGetter.instance.get_new_id(w[:id]).nil?
            throw "Should exist waybill data" if w[:vatin].empty? || w[:document_id].empty?
            new_w = Waybill.new(created: old_w[:created], document_id: w[:document_id],
                                storekeeper_type: Entity.name, storekeeper_id: user.entity.id,
                                storekeeper_place_id: place.id, distributor_place_id: moscow.id)
            old_d = DbGetter.instance.legal_entity(old_w[:distributor_id])
            unless new_w.distributor
              country = Country.find_or_create_by_tag(I18n.t("activerecord.attributes.country.default.tag"))
              distributor = LegalEntity.find_all_by_name_and_country_id(
                  old_d[:name], country).first
              if distributor.nil?
                distributor = LegalEntity.new(name: old_d[:name],
                                              identifier_name: "VATIN",
                                              identifier_value: w[:vatin])
                distributor.country = country
                distributor.save!
              end
              new_w.distributor = distributor
            end
            new_w.add_item(tag: @resource_tag, mu: @resource_mu, amount: w[:count], price: w[:price])
            new_w.save!
            DbGetter.instance.add_to_assoc(new_w.id, w[:id])
          else
            new_w = Waybill.find(Convert::DbGetter.instance.get_new_id(w[:id]))
            deal = new_w.deal
            resource = Asset.find_or_create_by_tag_and_mu(@resource_tag, @resource_mu)
            new_w.items
            item = WaybillItem.new(object: new_w, amount: w[:count],
                                      resource: resource, price: w[:price])
            new_w.instance_eval do
              @items << item
            end
            from_item = item.warehouse_deal(Chart.first.currency,
                        new_w.distributor_place, new_w.distributor)
            throw "Cann't save from" if from_item.nil?

            to_item = item.warehouse_deal(nil,
                new_w.storekeeper_place, new_w.storekeeper)
            throw "Cann't save to" if to_item.nil?

            throw "Cann't save rules" if deal.rules.create(tag: "#{deal.tag}; rule#{deal.rules.count}",
              from: from_item, to: to_item, fact_side: false,
              change_side: true, rate: item.amount).nil?
          end
        end
        DbGetter.instance.add_to_shower(@resource_id, @place_id)
      end
    end
  end
end
