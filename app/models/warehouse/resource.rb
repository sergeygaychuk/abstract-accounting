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

    belongs_to :resource, class_name: "::Asset"

    delegate :tag, :mu, :to => :resource

    def == (other)
      other.resource_id == self.resource_id
    end

    class << self
      def scoped
        ResourceScope.scoped
      end
    end

    private
    class ResourceScope < ::Fact
      default_scope do
        with_parent_to_deal_id_in(Waybill.select(:deal_id)).
        with_resource_type(Asset.name).select(:resource_id)
      end

      class << self
        def instantiate(record)
          Resource.instantiate(record)
        end
      end
    end
  end
end
