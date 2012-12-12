# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Warehouse

  class Place < ActiveRecord::Base
    has_no_table
    column :place_id, :integer
    column :user_id, :integer

    belongs_to :place, class_name: "::Place"
    belongs_to :user
    has_one :storekeeper, through: :user, source: :entity, class_name: Entity

    validates_presence_of :user_id

    def save
      valid? and !!user.credentials.create(place_id: place_id, document_type: Warehouse.name)
    end

    def ==(other)
      other.place_id == place_id && other.user_id == user_id
    end

    class << self
      def scoped
        PlaceScope.scoped
      end
    end

    private
      class PlaceScope < ::User
        default_scope do
          by_credentials(Credential.with_document(Warehouse.name).with_presented_place).
            joins{credentials}.
            select{id.as(:user_id)}.select{credentials.place_id.as(:place_id)}
        end

        class << self
          def instantiate(record)
            Place.instantiate(record)
          end
        end
      end
  end
end
