# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class DbConvertersController < ApplicationController
  def places
    @places = Convert::DbGetter.instance.warehouse_places
  end

  def warehouse
    @warehouse = Convert::DbGetter.instance.warehouse(params[:place_id])
  end

  def new
    @adder = Convert::ResourceAdder.new(place_id: params[:place_id],
                               resource_id: params[:resource_id],
                               count: params[:count])
  end

  def create
    Convert::ResourceAdder.new(params[:adder]).save()
    redirect_to warehouse_db_converters_path(place_id: params[:adder][:place_id])
  end

  def apply
    Convert::DbGetter.apply(params[:user_id])
    redirect_to warehouse_db_converters_path(place_id: params[:place_id])
  end
end
