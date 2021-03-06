# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

class WarehousesController < ApplicationController
  authorize_resource class: Waybill.name
  authorize_resource class: Allocation.name

  def index
    render 'index', layout: "data_with_filter"
  end

  def data
    params[:page] ||= 1
    params[:per_page] ||= Settings.root.per_page

    attrs = { page: params[:page], per_page: params[:per_page] }

    if params.has_key?(:like) || params.has_key?(:equal)
      [:like, :equal].each { |type|
        params[type].each { |key, value|
          unless value.empty?
            attrs[:where] ||= {}
            attrs[:where][key] = {}
            attrs[:where][key][type] = value
          end
        } if params[type]
      }
    end

    attrs[:without] = params[:without] if params.has_key?(:without)
    unless current_user.root?
      credential = current_user.credentials(:force_update).
          where{document_type == Waybill.name}.first
      credential = current_user.credentials.
          where{(document_type == Allocation.name) & (credential.place_id == place_id)}.
          first if credential
      if credential
        attrs[:where] = {} unless attrs.has_key?(:where)
        attrs[:where][:warehouse_id] = { equal: credential.place_id }
      else
        if current_user.managed_group
          unless can?(:reverse, Waybill) && can?(:reverse, Allocation)
            @warehouse = []
            @count = 0
            return
          end
        else
          @warehouse = []
          @count = 0
          return
        end
      end
    end

    if params[:warehouse_id] && !(attrs[:where] && attrs[:where][:warehouse_id])
      attrs[:where] = {} unless attrs.has_key?(:where)
      attrs[:where][:warehouse_id] = { equal: params[:warehouse_id] }
    end

    attrs[:where] = params[:where] if params[:where]
    @count = Warehouse.count(attrs)

    attrs[:order_by] = params[:order] if params[:order]
    @warehouse = Warehouse.all(attrs)
  end

  def group
    respond_to do |format|
      format.html { render :group, layout: false }
      format.json do
        params[:page] ||= 1
        params[:per_page] ||= Settings.root.per_page

        attrs = { page: params[:page], per_page: params[:per_page] }
        unless current_user.root?
          credential = current_user.credentials(:force_update).
              where{document_type == Waybill.name}.first
          credential = current_user.credentials.
              where{(document_type == Allocation.name) & (credential.place_id == place_id)}.
              first if credential
          if credential
            attrs[:where] = {} unless attrs.has_key?(:where)
            attrs[:where][:warehouse_id] = { equal: credential.place_id }
          else
            if current_user.managed_group
              unless can?(:reverse, Waybill) && can?(:reverse, Allocation)
                @warehouse = []
                @count = 0
                @group_by = params[:group_by]
                return
              end
            else
              @warehouse = []
              @count = 0
              @group_by = params[:group_by]
              return
            end
          end
        end

        if params.has_key?(:group_by)
          attrs[:group_by] = params[:group_by]

          @warehouse = Warehouse.group(attrs)
          @count = Warehouse.count(attrs)
          @group_by = params[:group_by]
        end
      end
    end
  end

  def report
    respond_to do |format|
      format.html { render :report, layout: false }
      format.json do
        params[:page] ||= 1
        params[:per_page] ||= Settings.root.per_page

        @resource = nil
        @place = nil
        @warehouse = []
        @count = 0
        @total = 0.0
        @warehouses = []

        if current_user.root?
          @warehouses = Waybill.warehouses
        else
          credential = current_user.credentials(:force_update).
            where{(document_type == Waybill.name) & (place_id == my{params[:warehouse_id]})}.
            first
          if !credential && !params[:warehouse_id]
            credential = current_user.credentials(:force_update).
                        where{(document_type == Waybill.name)}.
                        first
            params[:warehouse_id] = credential.place_id if credential
          end
          credential = current_user.credentials.
              where{(document_type == Allocation.name) & (credential.place_id == place_id)}.
              first if credential
          unless credential
            if current_user.managed_group
              if can?(:reverse, Waybill) && can?(:reverse, Allocation)
                @warehouses = Waybill.warehouses
              else
                return
              end
            else
              return
            end
          end
        end

        if params.has_key?(:resource_id) && params.has_key?(:warehouse_id)
          @resource = Asset.find(params[:resource_id])
          @place = Place.find(params[:warehouse_id])
          @warehouse = WarehouseResourceReport.all(resource_id: params[:resource_id],
            warehouse_id: params[:warehouse_id], page: params[:page],
            per_page: params[:per_page])
          @count = WarehouseResourceReport.count(resource_id: params[:resource_id],
                      warehouse_id: params[:warehouse_id])
          @total = WarehouseResourceReport.total(resource_id: params[:resource_id],
                                                 warehouse_id: params[:warehouse_id])
        end
      end
      format.pdf do
        @resource = nil
        @place = nil
        @warehouse = []
        @total = 0.0

        unless current_user.root?
          credential = current_user.credentials(:force_update).
            where{(document_type == Waybill.name) & (place_id == my{params[:warehouse_id]})}.
            first
          if !credential && !params[:warehouse_id]
            credential = current_user.credentials(:force_update).
                        where{(document_type == Waybill.name)}.
                        first
            params[:warehouse_id] = credential.place_id if credential
          end
          credential = current_user.credentials.
              where{(document_type == Allocation.name) & (credential.place_id == place_id)}.
              first if credential
          unless credential
            if current_user.managed_group
              unless can?(:reverse, Waybill) && can?(:reverse, Allocation)
                render pdf: 'blank.pdf',
                       template: 'warehouses/report_print.html.erb',
                       formats: [:html],
                       encoding: 'utf-8',
                       layout: false
                return
              end
            else
              render pdf: 'blank.pdf',
                     template: 'warehouses/report_print.html.erb',
                     formats: [:html],
                     encoding: 'utf-8',
                     layout: false
              return
            end
          end
        end

        if params.has_key?(:resource_id) && params.has_key?(:warehouse_id)
          @resource = Asset.find(params[:resource_id])
          @place = Place.find(params[:warehouse_id])
          @warehouse = WarehouseResourceReport.all(resource_id: params[:resource_id],
            warehouse_id: params[:warehouse_id], page: params[:page],
            per_page: params[:per_page])
          @total = WarehouseResourceReport.total(resource_id: params[:resource_id],
                                                 warehouse_id: params[:warehouse_id])
        end
        file_name = 'blank'
        file_name = @resource.tag if @resource
        render pdf: "#{file_name}.pdf",
               template: 'warehouses/report_print.html.erb',
               orientation: 'Landscape',
               formats: [:html],
               encoding: 'utf-8',
               layout: false
      end
    end
  end

  def foremen
    respond_to do |format|
      format.html { render :foremen, layout: false }
      format.xls do

        warehouse_id = params[:warehouse_id]
        unless current_user.root?
          credential = current_user.credentials(:force_update).
            where{(document_type == Waybill.name)}.
            first
          credential = current_user.credentials.
              where{(document_type == Allocation.name) & (credential.place_id == place_id)}.
              first if credential
          if credential
            warehouse_id = credential.place_id
          else
            if current_user.managed_group
              unless can?(:reverse, Waybill) && can?(:reverse, Allocation)
                send_data [].to_xls, :filename => "empty.xls"
              end
            else
              send_data [].to_xls, :filename => "empty.xls"
            end
          end
        end

        if  warehouse_id
          if params[:foreman_id]
            foreman = Entity.find(params[:foreman_id])
            from = (params[:from] && DateTime.parse(params[:from])) ||
                DateTime.current.beginning_of_month
            to = (params[:to] && DateTime.parse(params[:to])) || DateTime.current
            args = {warehouse_id: warehouse_id, foreman_id: params[:foreman_id],
                    start: from, stop: to }
            args.merge!(
                {:resource_ids => params[:resource_ids][params[:foreman_id]]}
            ) if params[:resource_ids]
            resources = WarehouseForemanReport.all(args)
            send_data resources.to_xls(name: foreman.tag,
                                  columns: [{resource: [:tag, :mu]}, :amount, :price, :sum],
                                  headers: [
                                      I18n.t('views.warehouses.foremen.report.resource.name'),
                                      I18n.t('views.warehouses.foremen.report.resource.mu'),
                                      I18n.t('views.warehouses.foremen.report.amount'),
                                      I18n.t('views.warehouses.foremen.report.price'),
                                      I18n.t('views.warehouses.foremen.report.sum')
                                  ],
                                  header_format: {weight: :bold, color: :red}),
                      :filename => "#{foreman.tag}-#{DateTime.current.strftime("%Y-%m")}.xls"
          else
            book = Spreadsheet::Workbook.new
            foremen = WarehouseForemanReport.foremen(warehouse_id)
            from = (params[:from] && DateTime.parse(params[:from])) ||
                DateTime.current.beginning_of_month
            to = (params[:to] && DateTime.parse(params[:to])) || DateTime.current
            foremen.each do |foreman|
              if foreman[:id]
                args = {warehouse_id: warehouse_id, foreman_id: foreman[:id],
                        start: from, stop: to }
                resources = []
                if params[:resource_ids]
                  if params[:resource_ids].has_key?(foreman[:id].to_s)
                    args.merge!({:resource_ids => params[:resource_ids][foreman[:id].to_s]})
                    resources = WarehouseForemanReport.all(args)
                  end
                else
                  resources = WarehouseForemanReport.all(args)
                end
                unless resources.empty?
                  ToXls::Writer.new(resources,
                                   { name: foreman.tag,
                                     columns: [{resource: [:tag, :mu]}, :amount, :price, :sum],
                                     headers: [
                                       I18n.t('views.warehouses.foremen.report.resource.name'),
                                       I18n.t('views.warehouses.foremen.report.resource.mu'),
                                       I18n.t('views.warehouses.foremen.report.amount'),
                                       I18n.t('views.warehouses.foremen.report.price'),
                                       I18n.t('views.warehouses.foremen.report.sum')
                                     ],
                                     header_format: {weight: :bold, color: :red}
                                   }).write_book(book)
                end
              end
            end
            if  book.worksheets.length > 0
              io = StringIO.new('')
              book.write(io)
              send_data io.string,
                        :filename => "#{I18n.t('views.warehouses.report.name')}-" +
                            "#{DateTime.current.strftime("%Y-%m")}.xls"
            else
              send_data [].to_xls, :filename => "empty.xls"
            end
          end
        else
          send_data [].to_xls, :filename => "empty.xls"
        end
      end
      format.json do
        params[:page] ||= 1
        params[:per_page] ||= Settings.root.per_page

        warehouse_id = params[:warehouse_id]
        @warehouses = []
        @foremen = []
        @resources = []
        @count = 0
        @from = (params[:from] && DateTime.parse(params[:from])) ||
            DateTime.current.beginning_of_month
        @to = (params[:to] && DateTime.parse(params[:to])) || DateTime.current

        if current_user.root?
          @warehouses = Waybill.warehouses
        else
          credential = current_user.credentials(:force_update).
            where{(document_type == Waybill.name)}.
            first
          credential = current_user.credentials.
              where{(document_type == Allocation.name) & (credential.place_id == place_id)}.
              first if credential
          if credential
            warehouse_id = credential.place_id
          else
            if current_user.managed_group
              if can?(:reverse, Waybill) && can?(:reverse, Allocation)
                @warehouses = Waybill.warehouses
              else
                return
              end
            else
              return
            end
          end
        end

        if warehouse_id
          @foremen = WarehouseForemanReport.foremen(warehouse_id)
          if params[:foreman_id]
            args = {warehouse_id: warehouse_id, foreman_id: params[:foreman_id],
                    start: @from, stop: @to,
                    page: params[:page], per_page: params[:per_page] }
            @resources = WarehouseForemanReport.all(args)
            @count = WarehouseForemanReport.count(args)
          end
        end
      end
    end
  end

  def print
    attrs = { }

    if params.has_key?(:like) || params.has_key?(:equal)
      [:like, :equal].each { |type|
        params[type].each { |key, value|
          unless value.empty?
            attrs[:where] ||= {}
            attrs[:where][key] = {}
            attrs[:where][key][type] = value
          end
        } if params[type]
      }
    end

    unless current_user.root?
      credential = current_user.credentials(:force_update).
          where{document_type == Waybill.name}.first
      credential = current_user.credentials.
          where{(document_type == Allocation.name) & (credential.place_id == place_id)}.
          first if credential
      if credential
        attrs[:where] = {} unless attrs.has_key?(:where)
        attrs[:where][:warehouse_id] = { equal: credential.place_id }
      else
        if current_user.managed_group
          unless can?(:reverse, Waybill) && can?(:reverse, Allocation)
            @warehouse = []
            @count = 0
            return
          end
        else
          @warehouse = []
          @count = 0
          return
        end
      end
    end

    attrs[:where] = params[:where] if params[:where]
    attrs[:order_by] = params[:order] if params[:order]
    @warehouse = Warehouse.all(attrs)


    respond_to do |format|
      format.html { render :print, layout: false }
      format.pdf do
        render pdf: 'warehouses.print.erb',
               :formats => [:html],
               encoding: 'utf-8',
               layout: false
      end
    end
  end
end
