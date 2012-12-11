# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

require 'spec_helper'

describe Credential do
  it "should have next behaviour" do
    create(:credential)
    should validate_presence_of :user_id
    should validate_uniqueness_of(:document_type).scoped_to(:user_id, :place_id)
    should belong_to :user
    should belong_to :place
    should have_many Credential.versions_association_name
    should have_one(:entity).through(:user)
  end

  it "should return data filtered by document_type" do
    document = "SomeDocument"
    3.times { create(:credential, document_type: document) }
    3.times { create(:credential) }
    Credential.with_document(document).all.should =~ Credential.
        where{document_type == document}.all
  end

  it "should return data filtered by presented place" do
    3.times { create(:credential, place_id: nil) }
    3.times { create(:credential) }
    Credential.with_presented_place.all.should =~ Credential.where{place_id != nil}.all
  end
end
