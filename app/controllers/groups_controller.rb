# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class GroupsController < ApplicationController
  def index
    render 'groups/index', layout: false
  end

  def preview
    render 'groups/preview', layout: false
  end

  def new
    @group = Group.new
  end

  def data
    page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = params[:per_page].nil? ?
        Settings.root.per_page.to_i : params[:per_page].to_i
    filter = { paginate: { page: page, per_page: per_page }}
    filter[:sort] = params[:order] if params[:order]
    #TODO: should get filtrate options from client
    @groups = Group.filtrate(filter)
    @count = Group.count
  end

  def show
    @group = Group.find(params[:id])
  end

  def create
    group = nil
    begin
      Group.transaction do
        group = Group.create(params[:group])
        group.user_ids = params[:users].values.map{ |item| item[:id] }
        render json: { result: 'success', id: group.id }
      end
    rescue
      render json: group.errors.full_messages
    end
  end

  def update
    group = Group.find(params[:id])
    begin
      Group.transaction do
        group.update_attributes(params[:group])
        group.user_ids = params[:users].values.map{ |item| item[:id] }
        render json: { result: 'success', id: group.id }
      end
    rescue
      render json: group.errors.full_messages
    end
  end
end
