# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@catalogs => :objects) do
  attributes :id, :tag, :document_id
  node(:have_boms) { |catalog| catalog.boms.exists? }
  node(:have_prices) { |catalog| catalog.prices.exists? }
end
node(:per_page) { Settings.root.per_page }
node(:count) { @count }