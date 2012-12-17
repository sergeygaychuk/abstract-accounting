# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Warehouse

  class Resource < ActiveRecord::Base
    has_no_table
    column :resource_id, :integer
    column :deal_id, :integer

    belongs_to :resource, class_name: "::Asset"
    belongs_to :deal, class_name: "::Deal"

    delegate :tag, :mu, :to => :resource

    def == (other)
      other.resource_id == self.resource_id
    end

    class << self
      def remote_scope(name, filter)
        ResourceScope.scope name, filter
        self.define_singleton_method(name) { |*args| scoped.send(name, *args) }
      end

      def scoped
        ResourceScope.scoped
      end
    end

    private
      class ResourceScope < ::Fact
        default_scope do
          with_parent_to_deal_id_in(Waybill.select(:deal_id)).
          with_resource_type(Asset.name).
          group{facts.to_deal_id}.group{facts.resource_id}.
          select{facts.resource_id.as(:resource_id)}.select{facts.to_deal_id.as(:deal_id)}
        end

        class << self
          def instantiate(record)
            Resource.instantiate(record)
          end
        end
      end
    public
      remote_scope :presented, -> { joins{to.states}.where{to.states.paid == nil} }
      remote_scope :by_warehouse, ->(warehouse) do
        joins{to.take}.
            where{to.entity_id == warehouse.storekeeper.id}.
            where{to.take.place_id == warehouse.place_id}
      end
  end
end
