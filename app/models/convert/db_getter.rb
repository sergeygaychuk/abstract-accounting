# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require "sqlite3"

# CREATE TABLE "shower" ("asset_id" INTEGER, "place_id" INTEGER);
# CREATE TABLE "assoc" ("new_id" INTEGER, "old_id" INTEGER);

module Convert
  class DbGetter
    include Singleton

    attr_reader :db

    def initialize
      @db = SQLite3::Database.new "#{Rails.root}/db/old.sqlite3"
    end

    def warehouse_places
      db.execute("SELECT id, tag FROM places WHERE id IN (select DISTINCT place_id from waybills)").
          collect { |place| {id: place[0], tag: place[1]} }
    end

    def warehouse(place_id)
      db.execute("
        SELECT assets.id, assets.tag, products.unit, states.amount FROM states
          INNER JOIN deals ON deals.id = states.deal_id
          INNER JOIN assets ON deals.give_id = assets.id AND deals.give_type = 'Asset'
          INNER JOIN products ON products.resource_id = assets.id
          LEFT JOIN shower ON shower.asset_id = assets.id AND shower.place_id = #{place_id}
        WHERE states.deal_id IN (
          SELECT rules.to_id FROM rules
          WHERE rules.deal_id IN (
            SELECT deal_id FROM waybills
            WHERE waybills.place_id = #{place_id} AND waybills.disable_deal_id IS NULL
          )
          GROUP BY rules.to_id
        ) AND states.paid IS NULL AND states.side = 'passive' AND shower.asset_id IS NULL
      ").collect { |warehouse| {id: warehouse[0], tag: warehouse[1], mu: warehouse[2], amount: warehouse[3]} }
    end

    def resource(id)
      db.execute("SELECT assets.id, assets.tag, products.unit FROM assets
                    INNER JOIN products ON products.resource_id = assets.id
                  WHERE assets.id = #{id}").
          collect { |resource| {id: resource[0], tag: resource[1], mu: resource[2]} }[0]
    end

    def place(id)
      db.execute("SELECT id, tag FROM places WHERE id = #{id}").
          collect { |place| {id: place[0], tag: place[1]} }[0]
    end

    def waybills_by_resource_id_and_place_id_and_count(resource_id, place_id, count)
      ws = []
      db.execute("SELECT waybills.id, rules.rate FROM rules
                    INNER JOIN deals ON deals.id = rules.to_id
                    INNER JOIN waybills ON waybills.deal_id = rules.deal_id
                  WHERE deals.give_id = #{resource_id} AND deals.give_type = 'Asset' AND waybills.place_id = #{place_id}
                  ORDER BY waybills.created DESC, waybills.id DESC").
          collect { |info| {id: info[0], amount: info[1]} }.each do |info|
        count -= info[:amount].to_f
        w = db.execute("select id, created, document_id from waybills where id = #{info[:id]}")[0]
        ws << { id: w[0], created: w[1], document_id: w[2],
                count: (count > 0.0 ? info[:amount].to_f : (info[:amount].to_f + count)), price: 0.0 }
        if count <= 0
          break
        end
      end
      ws
    end

    def waybill(id)
      db.execute("SELECT id, created, document_id, vatin, from_id FROM waybills
                  WHERE waybills.id = #{id}").
          collect { |w| {id: w[0], created: w[1], document_id: w[2],
                         vatin: w[3], distributor_id: w[4]} }[0]
    end

    def legal_entity(id)
      db.execute("SELECT id, tag FROM entities
                  WHERE entities.id = #{id}").
          collect { |le| {id: le[0], name: le[1]} }[0]
    end

    def add_to_shower(asset_id, place_id)
      db.execute("INSERT INTO shower(asset_id, place_id) VALUES(#{asset_id}, #{place_id})")
    end

    def add_to_assoc(new_id, old_id)
      db.execute("INSERT INTO assoc(new_id, old_id) VALUES(#{new_id}, #{old_id})")
    end

    def get_new_id(old_id)
      new_ids = db.execute("SELECT new_id FROM assoc WHERE old_id = #{old_id}")
      return nil if new_ids.empty?
      new_ids[0][0]
    end

    def get_old_id(new_id)
      old_ids = db.execute("SELECT old_id FROM assoc WHERE new_id = #{new_id}")
      return nil if old_ids.empty?
      old_ids[0][0]
    end

    def self.current_users
      Credential.where{document_type == Waybill.name}.map(&:user)
    end

    def self.apply(user_id)
      Waybill.transaction do
        Waybill.by_warehouse(
          User.find(user_id).credentials.where{document_type == Waybill.name}.first.place
        ).each do |w|
          unless DbGetter.instance.get_old_id(w.id).nil?
            res = false
            res = w.apply if w.state == Statable::INWORK
            throw "Error" unless res
          end
        end
      end
    end
  end
end
