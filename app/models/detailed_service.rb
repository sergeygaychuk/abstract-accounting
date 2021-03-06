# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class DetailedService < ActiveRecord::Base
  has_paper_trail

  validates_presence_of :tag, :mu_id
  validates_uniqueness_of :tag, :scope => :mu_id
  belongs_to :mu
  has_many :surrogates, :class_name => "Service", :foreign_key => :detailed_id
  has_one :description, :as => :item
end
