getTitle = ->
  geturl = "/get_page_title/" + encodeURIComponent($("#link_url").val())
  geturl = geturl.replace(/%/g, "%25")
  $.get geturl, (data) ->
    $("#content").val $("#link_url").val() + " (" + data + ") " + $("#content").val()
    $("#link_url").val ""

$(document).ready ->
  $("#content").keyup ->
    $("#word_count_indicator").html $("#content").val().length

  $("#post_content").submit (event) ->
    event.preventDefault()
    formdata = $("#post_content").serialize()
    $.ajax
      type: "POST"
      url: "/post"
      data: formdata
      success: (msg) ->
        $("#post_result").html(msg).fadeIn "slow"
        $("#content").val ""
        $("#word_count_indicator").html "0"


