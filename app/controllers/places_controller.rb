# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class PlacesController < ApplicationController
  def index
    if params[:term]
      term = params[:term]
      @places = Place.where{tag.like "%#{term}%"}.order("tag").limit(5)
    else
      render 'index', layout: false
    end
  end

  def preview
    render 'places/preview', layout: false
  end

  def new
    @place = Place.new
  end

  def show
    @place = Place.find(params[:id])
  end

  def data
    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i
    filter = { paginate: { page: page, per_page: per_page }}
    filter[:sort] = params[:order] if params[:order]
    #TODO: should get filtrate options from client
    @places = Place.filtrate(filter)
    @count = Place.count
  end

  def create
    place = nil
    begin
      Place.transaction do
        place = Place.create(params[:place])
        render json: { result: 'success', id: place.id }
      end
    rescue
      render json: place.errors.full_messages
    end
  end

  def update
    place = Place.find(params[:id])
    begin
      Place.transaction do
        place.update_attributes(params[:place])
        render json: { result: 'success', id: place.id }
      end
    rescue
      render json: place.errors.full_messages
    end
  end
end
