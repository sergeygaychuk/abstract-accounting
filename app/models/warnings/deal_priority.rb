# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Warnings
  class DealPriority < Warnings::Deal
    attr_reader :expected, :got
    def initialize(object, expected, got)
      @expected = expected
      @got = got
      super(object)
    end
  end
end
