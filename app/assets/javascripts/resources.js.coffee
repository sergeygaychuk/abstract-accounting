$ ->
  class self.ResourcesViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/resources/data.json'
      super(data)

      @toReport = ko.observableArray()
      @params =
        page: @page
        per_page: @per_page

    show: (resource) ->
      page = if resource.klass == "Asset" then "assets" else "money"
      location.hash = "#documents/#{page}/#{resource.id}"

    showBalances: ->
      unless $('#slide_menu_conditions').is(":visible")
        $('#arrow_conditions').removeClass('arrow-down-slide')
        $('#arrow_conditions').addClass('arrow-up-slide')
        $("#slide_menu_conditions").slideDown()
      params =
        resources: ko.mapping.toJS(@toReport)
      location.hash = "#balance_sheet?#{$.param(params)}"
