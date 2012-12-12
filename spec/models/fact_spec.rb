# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Fact do
  it "should have next behaviour" do
    should validate_presence_of :day
    should validate_presence_of :amount
    should validate_presence_of :resource_id
    should validate_presence_of :to_deal_id
    should belong_to :resource
    should belong_to :from
    should belong_to :to
    should belong_to(:parent).class_name(Fact)
    should have_one :txn
    should have_many Fact.versions_association_name
    should have_many(:children).class_name(Fact)
    build(:fact).should be_valid
    build(:fact, :from => create(:deal)).should_not be_valid
  end

  it "should filter by resource_type" do
    5.times { create(:fact) }
    5.times do
      resource = create(:money)
      from = create(:deal, take: build(:term, resource: resource))
      to = create(:deal, give: build(:term, resource: resource))
      create(:fact, from: from, to: to, resource: resource)
    end
    Fact.with_resource_type(Asset.name).all.should =~ Fact.where{resource_type == Asset.name}.
        all
    Fact.with_resource_type(Money.name).all.should =~ Fact.where{resource_type == Money.name}.
        all
  end

  it "should filter by inclusion parent to_deal_id in accepted array" do
    6.times do
      create(:fact, parent: create(:fact))
    end
    deals = 2.times.collect { create(:fact, parent: create(:fact)).parent.to_deal_id }
    deals.each { |deal_id| create(:fact, to_deal_id: deal_id,
                                  from: create(:deal,
                                               take: build(:term,
                                                           resource: Deal.find(deal_id).
                                                               give.resource)),
                                  resource: Deal.find(deal_id).give.resource) }
    Fact.with_parent_to_deal_id_in(deals).all.should =~ Fact.joins{parent}.
        where{parent.to_deal_id.in(deals)}.all
  end
end
