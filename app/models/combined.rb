# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class Combined
  class_attribute :klasses_i, :configuration

  def initialize(object)
    @object = object.type.constantize.find(object.id)
  end

  def id
    @object.id
  end

  def type
    @object.class.name
  end

  class << self
    def attribute_names
      default_attrs = %w(id type)
      default_attrs + self.configuration.keys.collect { |val| val.to_s }
    end

    def klasses(klasses)
      self.klasses_i = klasses
    end

    def combined_attribute(name, config = {})
      self.configuration ||= Hash.new
      self.configuration[name.to_sym] = config
      define_method name do
        @object.send(config[@object.class.name.to_sym])
      end
    end

    def where(attrs)
      scope.where(attrs)
    end

    def limit(value)
      scope.limit(value)
    end

    def order(value)
      scope.order(value)
    end
    alias_method :order_by, :order
    deprecate :order_by

    def filtrate(*args)
      scope.filtrate(*args)
    end

    def paginate(*args)
      scope.paginate(*args)
    end

    def sort(*args)
      scope.sort(*args)
    end

    def all
      scope.all
    end

    def count
      scope.count
    end

    private
    def scope
      tables = klasses_i.collect do |item|
        sel = configuration.inject([]) do |mem, (key, value)|
          if item.columns_hash[value[item.name.to_sym].to_s].type == :integer
            mem << "to_char(#{value[item.name.to_sym]}, '999') as #{key}"
          else
            mem << "#{value[item.name.to_sym]} as #{key}"
          end
        end
        sel = sel.join(', ')
        item.select("id, '#{item.name}' as type, #{sel}").to_sql
      end
      CombinedRelation.new(SqlRecord.union(tables), self)
    end
  end
end
