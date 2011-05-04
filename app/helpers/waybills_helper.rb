module WaybillsHelper

  include JqgridsHelper

  def waybills_jqgrid

    options = {:on_document_ready => true}

    grid = [{
      :datatype => 'local',
      :colNames => ['resource*', 'amount*', 'unit*'],
      :colModel => [ { :name => 'resource', :index => 'resource', :editable => true,
                       :width => 300 },
                     { :name => 'amount',   :index => 'amount',   :editable => true,
                       :width => 120,       :formatter => 'integer',
                       :formatoptions => {:defaultValue => ''} },
                     { :name => 'unit',     :index => 'unit',     :editable => true,
                       :width => 80 }],
      :pager => '#waybills_pager',
      :rowNum => 10,
      :cellEdit => true,
      :editurl => 'clientArray',
      :cellsubmit => 'clientArray',
      :rowList => [10, 20, 30],
      :rownumbers => true,
      :sortname => 'resource',
      :sortorder => 'asc',
      :viewrecords => true,
      :beforeEditCell => 'function(rowid, cellname, value, iRow, iCol)
      {
        editRowId = iRow;
        editColId = iCol;
      }'.to_json_var
    }]

    pager = [:navGrid, '#waybills_pager', {:refresh => false, :add => false,
                                           :del=> false, :edit => false,
                                           :search => false, :view => false},
                                          {}, {}, {}]
    
    pager_button_add = [:navButtonAdd, '#waybills_pager', {:caption => 'Add',
      :buttonicon => 'ui-icon-plus', :onClickButton =>
      'function() {
        $("#waybills_list").addRowData(uin, { resource: ""
                                            , amount: ""
                                            , unit: "" });
        uin++;
      }'.to_json_var }]
    pager_button_del = [:navButtonAdd, '#waybills_pager', {:caption => 'Del',
      :buttonicon => 'ui-icon-trash', :onClickButton =>
      'function() {
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

end