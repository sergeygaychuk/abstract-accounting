$ ->
  self.scrolling = ->
    $(document).ready(=>
      $("a.ancLinks").click(->
        elementClick = $(this).attr("href")
        destination = $(elementClick).offset().top
        $('body').animate( { scrollTop: destination }, 1100 )
        false
      )
    )