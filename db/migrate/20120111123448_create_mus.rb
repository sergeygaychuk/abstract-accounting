# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class CreateMus < ActiveRecord::Migration
  def change
    create_table :mus do |t|
      t.string :tag
    end

    add_index :mus, :tag, :unique => true
  end
end
