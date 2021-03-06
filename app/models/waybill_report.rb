# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class WaybillReport < Waybill
  def self.select_all
    self.select("waybills.*").
        select{deal.rules.from.take.resource.id.as('resource_id')}.
        select{deal.rules.from.take.resource.tag.as('resource_tag')}.
        select{deal.rules.from.take.resource.mu.as('resource_mu')}.
        select{(deal.rules.from.rate).as('resource_price')}.
        select{(deal.rules.rate).as('resource_amount')}.
        select{(deal.rules.rate / deal.rules.from.rate).as('resource_sum')}
  end

  def self.with_resources
    self.joins{deal.rules.from.take.resource(Asset)}
  end

  custom_sort(:distributor) do |dir|
    query = "case froms_rules.entity_type
                  when 'Entity'      then entities.tag
                  when 'LegalEntity' then legal_entities.name
             end"
    joins{deal.rules.from.entity(LegalEntity).outer}.
        joins{deal.rules.from.entity(Entity).outer}.
        order("#{query} #{dir}")
  end

  custom_sort(:resource_tag) do |dir|
    query = "assets.tag"
    joins{deal.rules.from.take.resource(Asset)}.order("#{query} #{dir}")
  end

  custom_sort(:resource_mu) do |dir|
    query = "assets.mu"
    joins{deal.rules.from.take.resource(Asset)}.order("#{query} #{dir}")
  end

  custom_sort(:resource_amount) do |dir|
    query = "rules.rate"
    joins{deal.rules}.order("#{query} #{dir}")
  end

  custom_sort(:resource_price) do |dir|
    query = "resource_price"
    joins{deal.rules.from}.order("#{query} #{dir}")
  end

  custom_sort(:resource_sum) do |dir|
    query = "resource_sum"
    joins{deal.rules.from}.order("#{query} #{dir}")
  end

  custom_search(:distributor) do |value|
    query = "case froms_rules.entity_type
                  when 'Entity'      then entities.tag
                  when 'LegalEntity' then legal_entities.name
             end"
    joins{deal.rules.from.entity(LegalEntity).outer}.
        joins{deal.rules.from.entity(Entity).outer}.
        where("lower(#{query}) ILIKE lower('%#{value}%')")
    #where{lower(my{query}).like(lower("%#{value}%"))}.uniq
  end

  custom_search(:resource_tag) do |value|
    joins{deal.rules.from.take.resource(Asset)}.
        where{lower(deal.rules.from.take.resource.tag).like(lower("%#{value}%"))}
  end

  custom_search(:states) do |filter = {}|
    group_by = '"assets"."id", "assets"."tag", "assets"."mu", "froms_rules"."rate", "rules"."rate"'
    scope = super(filter)
    scope = scope.group{group_by} unless scope.group_values.empty?
    scope
  end
end
