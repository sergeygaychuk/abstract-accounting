# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Person < ActiveRecord::Base
  has_paper_trail

  validates_presence_of :first_name, :second_name, :birthday, :place_of_birth
  validates_uniqueness_of :first_name, :scope => :second_name
  has_one :identity, :class_name => "IdentityDocument"
end
