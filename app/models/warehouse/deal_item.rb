# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Warehouse
  DealItem = Struct.new(:tag, :mu, :amount, :price) do
    def resource
      return nil if !tag || !mu
      if @resource.nil? || @resource.new_record?
        @resource = Asset.with_lower_tag(tag).with_lower_mu(mu).first
      end
      @resource ||= Asset.new(tag: tag, mu: mu)
    end

    def resource=(value)
      @resource = value
    end

    def state_amount(warehouse)
      return 0.0 if resource.nil?
      warehouse_resource = Resource.by_warehouse(warehouse).with_resource_id(resource.id).
          first
      warehouse_resource.amount or 0.0
    end

    def total_price
      amount * price
    end
  end
end
