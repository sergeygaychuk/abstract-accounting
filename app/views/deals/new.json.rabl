# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

object false
child(@deal => :deal) do
  attributes :tag, :isOffBalance, :rate, :entity_id, :entity_type,
             :execution_date, :compensation_period
  child(Limit.new => :limit_attributes) do
    node(:amount) { @deal.limit_amount }
    node(:side) { @deal.limit_side }
  end
end
child(Object.new => :entity) do
  attributes :tag
end
child(Term.new => :give) do
  extends "deals/_term"
end
child(Term.new => :take) do
  extends "deals/_term"
end
child([] => :rules)
