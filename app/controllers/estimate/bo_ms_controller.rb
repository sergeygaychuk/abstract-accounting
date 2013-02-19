# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Estimate
  class BoMsController < ApplicationController
    def index
      if params[:term]
        @boms = BoM.only_boms.search(uid: params[:term]).order('uid').limit(5)
        render :autocomplete
      else
        render 'index', layout: "data_with_filter"
      end
    end

    def preview
      render 'preview', layout: false
    end

    def new
      @bo_m = BoM.new
    end

    def show
      @bo_m = BoM.find params[:id]
    end

    def create
      save do
        BoM.new(params[:bo_m])
      end
    end

    def update
      save do
        bom = BoM.find params[:id]
        bom.items.delete_all
        bom.assign_attributes(params[:bo_m])
        bom
      end
    end

    def data
      scope = BoM.only_boms
      scope = scope.with_catalog_id(params[:catalog_id]) if params[:catalog_id]
      scope = scope.with_catalog_pid(params[:catalog_pid]) if params[:catalog_pid]
      scope = scope.search(params[:like]) if params[:like]
      @count = scope.count

      filter = generate_paginate
      filter[:sort] = params[:order] if params[:order]
      @bo_ms = scope.filtrate(filter).all
    end

    private
      def save
        if params[:materials] || params[:materials] ||
            params[:bo_m][:workers_amount] || params[:bo_m][:drivers_amount]
          BoM.transaction do
            params[:bo_m][:resource_id] ||= BoM.create_resource(params[:resource]).id
            bom = yield
            params[:materials].values.each { |item| bom.build_materials(item) } if params[:materials]
            params[:machinery].values.each { |item| bom.build_machinery(item) } if params[:machinery]
            if bom.save
              render json: { result: 'success', id: bom.id }
            else
              render json: bom.errors.full_messages
            end
          end
        else
          render json: ["#{I18n.t('views.estimates.boms')} : #{I18n.t('errors.messages.blanks')}"]
        end
      end
  end
end