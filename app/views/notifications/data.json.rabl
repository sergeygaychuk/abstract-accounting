# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@notifications => :objects) do
  attributes :id, :title
  node(:date) { |notification| notification.date.strftime('%Y/%m/%d')}
end
node(:per_page) { Settings.root.per_page }
node(:count) { @count }
