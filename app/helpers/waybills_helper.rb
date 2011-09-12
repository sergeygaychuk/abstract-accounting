module WaybillsHelper

  include JqgridsHelper

  def waybills_jqgrid

    options = {:on_document_ready => true}

    grid = [{
      :datatype => 'local',
      :colNames => [t('waybill.entryList.resource') + '*',
                    t('waybill.entryList.amount') + '*',
                    t('waybill.entryList.unit') + '*'],
      :colModel => [ { :name => 'resource', :index => 'resource', :editable => true,
                       :width => 300 },
                     { :name => 'amount',   :index => 'amount',   :editable => true,
                       :width => 120, :formatter => 'function(cellvalue, options, rowObject) {
                           if(isNaN(cellvalue) || (cellvalue == "") ||
                               (parseInt(cellvalue) <= "0")) {
                             return "";
                           }
                           return cellvalue;
                         }'.to_json_var },
                     { :name => 'unit',     :index => 'unit',     :editable => true,
                       :width => 80 }],
      :pager => '#waybills_pager',
      :rowNum => 10,
      :cellEdit => true,
      :editurl => 'clientArray',
      :cellsubmit => 'clientArray',
      :rowList => [10, 20, 30],
      :rownumbers => true,
      :viewrecords => true,
      :beforeEditCell => 'function(rowid, cellname, value, iRow, iCol)
      {
        editRowId = iRow;
        editColId = iCol;
      }'.to_json_var,
      :onPaging => 'function(param)
      {
        fixPager(param, "waybills_list");
      }'.to_json_var
    }]

    pager = [:navGrid, '#waybills_pager', {:refresh => false, :add => false,
                                           :del=> false, :edit => false,
                                           :search => false, :view => false},
                                          {}, {}, {}]
    
    pager_button_add = [:navButtonAdd, '#waybills_pager', {
      :caption => t('waybill.entryList.btn_add'), :buttonicon => 'ui-icon-plus',
      :onClickButton => 'function() {
        $("#waybills_list").addRowData(uin, { resource: ""
                                            , amount: ""
                                            , unit: "" });
        uin++;
      }'.to_json_var }]
    pager_button_del = [:navButtonAdd, '#waybills_pager', {
      :caption => t('waybill.entryList.btn_del'), :buttonicon => 'ui-icon-trash',
      :onClickButton => 'function() {
        if($("#waybills_list").getGridParam("selrow") != null) {
          $("#waybills_list").delRowData($("#waybills_list").getGridParam("selrow"));
          var data = $("#waybills_list").getRowData();
          $("#waybills_list").clearGridData();
          for(uin=0; uin<data.length; uin++) {
            $("#waybills_list").addRowData(uin, data[uin]);
          }
        }
      }'.to_json_var }]

    jqgrid_api 'waybills_list', grid, pager, pager_button_add, pager_button_del,
                                options

  end


  def waybills_jqgrid_tree

    options = {:on_document_ready => true}

    grid = [{
      :url => '/waybills/view',
      :datatype => 'json',
      :mtype => 'GET',
      :colNames => [t('waybill.tree.document_id'), t('waybill.tree.date'),
                    t('waybill.tree.organization'), t('waybill.tree.owner'),
                    t('waybill.tree.vatin'), t('waybill.tree.place'),
                    'in_storehouse'],
      :colModel => [
        { :name => 'document_id',   :index => 'document_id',   :width => 110 },
        { :name => 'created',       :index => 'created',       :width => 100,
          :formatter => 'function(cellvalue, options, rowObject) {
                           return cellvalue.substr(0,10);
                         }'.to_json_var },
        { :name => 'from',      :index => 'from',      :width => 185 },
        { :name => 'owner',     :index => 'owner',     :width => 185 },
        { :name => 'vatin',     :index => 'vatin',     :width => 90 },
        { :name => 'place',     :index => 'place',     :width => 150 },
        { :name => 'in_storehouse', :index => 'in_storehouse', :hidden => true }
      ],
      :pager => '#waybills_tree_pager',
      :height => "100%",
      :rowNum => 30,
      :rowList => [30, 50, 100],
      :sortname => 'created',
      :sortorder => 'asc',
      :viewrecords => true,
      :gridview => true,
      :toppager => true,
      :onSelectRow => 'function(row_id)
      {
        if((canManageWaybill == "true") &&
           ($("#waybills_tree").getCell(row_id, "in_storehouse") == "true")) {
          $("#waybills_release").unbind("click");
          $("#waybills_release_1").unbind("click");
          $("#waybills_release").click(function() {
            location.hash = "#storehouses/releases/new?filter=waybill&waybill=" + row_id;
          });
          $("#waybills_release_1").click(function() {
            location.hash = "#storehouses/releases/new?filter=waybill&waybill=" + row_id;
          });
          $("#waybills_release").removeAttr("disabled");
          $("#waybills_release_1").removeAttr("disabled");
        } else {
          $("#waybills_release").attr("disabled","disabled");
          $("#waybills_release_1").attr("disabled","disabled");
        }
        if ($("#waybills_disable").length > 0) {
          if ($("#waybills_tree").getCell(row_id, "in_storehouse") == "true") {
            $("#waybills_disable").unbind("click");
            $("#waybills_disable_1").unbind("click");
            $("#waybills_disable").click(function() {
              location.hash = "#waybills/" + row_id + "/edit";
            });
            $("#waybills_disable_1").click(function() {
              location.hash = "#waybills/" + row_id + "/edit";
            });
            $("#waybills_disable").removeAttr("disabled");
            $("#waybills_disable_1").removeAttr("disabled");
          } else {
            $("#waybills_disable").attr("disabled", "disabled");
            $("#waybills_disable_1").attr("disabled", "disabled");
          }
        }
      }'.to_json_var,
      :onPaging => 'function(param)
      {
        fixPager(param, "waybills_tree");
      }'.to_json_var,
      :subGrid => true,
      :subGridRowExpanded => 'function(subgrid_id, row_id)
      {
        var subgrid_table_id = subgrid_id + "_t";
        var subgrid_pager_id = subgrid_id + "_p";
        $("#"+subgrid_id).html("<table id=\"" + subgrid_table_id + "\"></table>\
                                <div id=\"" + subgrid_pager_id + "\"></div>");
        $("#"+subgrid_table_id).jqGrid({
          url: "/waybills/" + row_id,
          datatype: "json",
          mtype: "GET",
          colNames: ["resource", "amount", "unit"],
          colModel: [{ name: "resource", index: "resource", width: 400, sortable: false },
                     { name: "amount", index: "amount", width: 150, sortable: false },
                     { name: "unit", index: "unit", width: 150, sortable: false }],
          height: "100%",
          rowNum: 10,
          rowList: [10, 20, 30],
          viewrecords: true,
          pager: "#" + subgrid_pager_id,
          beforeSelectRow: function()
          {
            return false;
          }
        });
      }'.to_json_var
    }]

    pager = [:navGrid, '#waybills_tree_pager', {:refresh => false, :add => false,
                                                :del=> false, :edit => false,
                                                :search => false, :view => false, :cloneToTop => true},
                                               {}, {}, {}]

    button_find_data = {
      :caption => t('grid.btn_find'),
      :buttonicon => 'ui-icon-search', :onClickButton => 'function() {
        if(filter) {
          $("#waybills_tree")[0].clearToolbar();
          filter = false;
        } else {
          filter = true;
        }
        $("#waybills_tree")[0].toggleToolbar();
      }'.to_json_var }

    pager_button_find = [:navButtonAdd, '#waybills_tree_pager', button_find_data]
    pager_button_find1 = [:navButtonAdd, '#waybills_tree_toppager_left', button_find_data]

    jqgrid_api 'waybills_tree', grid, options, pager, pager_button_find, pager_button_find1

  end

end
