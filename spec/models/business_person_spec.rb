# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe BusinessPerson do
  it "should have next behaviour" do
    BusinessPerson.create!(:person => create(:person),
                           :country => create(:country))
    should validate_presence_of :country_id
    should validate_presence_of :person_id
    should validate_uniqueness_of :person_id
    should belong_to :country
    should belong_to :person
    should belong_to :identifier
    should have_many BusinessPerson.versions_association_name
  end
end
