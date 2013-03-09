@getTitle = ->
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

  $("#new_comment_btn").on Gumby.click, ->
    $("#new_post_btn").attr("class", "medium btn pill-left default")
    $("#new_comment_btn").attr("class", "medium btn pill-right primary")
    $("#post_comment").val("true")

  $("#new_post_btn").on Gumby.click, ->
    $("#new_post_btn").attr("class", "medium btn pill-left primary")
    $("#new_comment_btn").attr("class", "medium btn pill-right default")
    $("#post_comment").val("false")
