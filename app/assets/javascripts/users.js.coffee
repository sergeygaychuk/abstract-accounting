$ ->
  class self.UsersViewModel extends FolderViewModel
    constructor: (data) ->
      @url = '/users/data.json'
      super(data)

      @params =
        page: @page
        per_page: @per_page

    showUser: (object) ->
      location.hash = "documents/users/#{object.id}"