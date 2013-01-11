# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module OpenTask
  module Common
    module Helpers
      def klass
        described_class
      end
    end
  end
end

RSpec.configure do |config|
  config.include(OpenTask::Common::Helpers)
end
