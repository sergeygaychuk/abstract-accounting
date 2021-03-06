# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Resource < Combined
  klasses [Asset, Money]
  combined_attribute :tag, Asset: :tag, Money: :alpha_code
  combined_attribute :ext_info, Asset: :mu, Money: :num_code
end
