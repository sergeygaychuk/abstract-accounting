module RolesHelper

  include JqgridsHelper

  def roles_jqgrid

    options = {:on_document_ready => true}

    grid = [{
      :url => '/roles',
      :datatype => 'json',
      :mtype => 'GET',
      :colNames => ['name', 'pages', 'id'],
      :colModel => [
        { :name => 'name',  :index => 'name',   :width => 800 },
        { :name => 'pages', :index => 'pages',  :width => 5, :hidden => true },
        { :name => 'id',    :index => 'id',     :width => 5, :hidden => true }
      ],
      :pager => '#roles_pager',
      :rowNum => 10,
      :rowList => [10, 20, 30],
      :sortname => 'name',
      :sortorder => 'asc',
      :viewrecords => true,
      :onSelectRow => "function(cell)
      {
        $('#role_name').val(cell);
        var pages = $('#roles_list').getCell(cell, 'pages').split(',');
        uncheckPages();
        var i = 0;
        while(pages[i])
        {
          $('[name=' + pages[i] + ']').attr('checked', 'checked');
          i++;
        }
        $('#pages').css('display','block');
      }".to_json_var,
      :beforeSelectRow => "function()
      {
        if (canSelect) return true;
        return false;
      }".to_json_var
    }]

    jqgrid_api 'roles_list', grid, options

  end

end
